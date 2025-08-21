import Foundation
import ARKit
import RealityKit
import Combine
import simd

class ARSessionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSessionActive = false
    @Published var detectedPlanes: [ARPlaneAnchor] = []
    @Published var selectedPlane: ARPlaneAnchor?
    @Published var rectangleCorners: [simd_float3] = []
    @Published var gridPoints: [GridPoint] = []
    @Published var currentState: ARSessionState = .initializing
    @Published var errorMessage: String?
    
    // MARK: - AR Properties
    private var arSession: ARSession?
    private var arView: ARView?
    private var planeDetectionEnabled = true
    private var rectangleEntity: ModelEntity?
    private var gridEntities: [ModelEntity] = []
    
    // MARK: - Grid Configuration
    private var gridRows: Int = 4
    private var gridCols: Int = 4
    private var rectangleWidth: Float = 1.0
    private var rectangleLength: Float = 1.0
    
    // MARK: - Session Configuration
    func configureSession(_ arView: ARView) {
        self.arView = arView
        self.arSession = arView.session
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arSession?.delegate = self
        arSession?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isSessionActive = true
        currentState = .detectingPlanes
    }
    
    // MARK: - Plane Management
    func selectPlane(_ plane: ARPlaneAnchor) {
        selectedPlane = plane
        currentState = .planeSelected
        clearRectangle()
    }
    
    func clearPlaneSelection() {
        selectedPlane = nil
        currentState = .detectingPlanes
        clearRectangle()
    }
    
    // MARK: - Rectangle Management
    func placeRectangle(at worldPosition: simd_float3) {
        guard let selectedPlane = selectedPlane else { return }
        
        // Project point onto plane
        let planeNormal = selectedPlane.transform.columns.2.xyz
        let planePoint = selectedPlane.transform.columns.3.xyz
        let projectedPoint = projectPointOntoPlane(worldPosition, planeNormal: planeNormal, planePoint: planePoint)
        
        if rectangleCorners.isEmpty {
            // First corner
            rectangleCorners = [projectedPoint]
            currentState = .placingRectangle
        } else if rectangleCorners.count == 1 {
            // Second corner - create rectangle
            let corner1 = rectangleCorners[0]
            let corner2 = projectedPoint
            
            createRectangle(from: corner1, to: corner2, on: selectedPlane)
            currentState = .rectanglePlaced
        }
    }
    
    private func createRectangle(from corner1: simd_float3, to corner2: simd_float3, on plane: ARPlaneAnchor) {
        let center = (corner1 + corner2) / 2.0
        let diagonal = corner2 - corner1
        
        // Calculate width and length
        rectangleWidth = abs(diagonal.x)
        rectangleLength = abs(diagonal.z)
        
        // Ensure minimum size
        rectangleWidth = max(rectangleWidth, 0.5)
        rectangleLength = max(rectangleLength, 0.5)
        
        // Create rectangle corners
        let halfWidth = rectangleWidth / 2.0
        let halfLength = rectangleLength / 2.0
        
        rectangleCorners = [
            center + simd_float3(-halfWidth, 0, -halfLength),
            center + simd_float3(halfWidth, 0, -halfLength),
            center + simd_float3(halfWidth, 0, halfLength),
            center + simd_float3(-halfWidth, 0, halfLength)
        ]
        
        createRectangleVisual()
    }
    
    private func createRectangleVisual() {
        guard let arView = arView else { return }
        
        // Remove existing rectangle
        clearRectangle()
        
        // Create rectangle mesh
        let rectangleMesh = MeshResource.generatePlane(width: rectangleWidth, depth: rectangleLength)
        let rectangleMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        rectangleEntity = ModelEntity(mesh: rectangleMesh, materials: [rectangleMaterial])
        
        // Position rectangle
        let center = (rectangleCorners[0] + rectangleCorners[2]) / 2.0
        rectangleEntity?.position = center
        
        // Add to scene
        arView.scene.addAnchor(AnchorEntity(world: center))
        arView.scene.addAnchor(AnchorEntity(world: center).addChild(rectangleEntity!))
    }
    
    private func clearRectangle() {
        rectangleEntity = nil
        rectangleCorners = []
        gridEntities.forEach { $0.removeFromParent() }
        gridEntities = []
        gridPoints = []
    }
    
    // MARK: - Grid Management
    func configureGrid(rows: Int, cols: Int) {
        gridRows = rows
        gridCols = cols
        generateGrid()
    }
    
    private func generateGrid() {
        guard !rectangleCorners.isEmpty, rectangleCorners.count == 4 else { return }
        
        clearGrid()
        
        let corner1 = rectangleCorners[0]
        let corner2 = rectangleCorners[2]
        
        for row in 0..<gridRows {
            for col in 0..<gridCols {
                let rowRatio = Float(row) / Float(gridRows - 1)
                let colRatio = Float(col) / Float(gridCols - 1)
                
                let position = corner1 + (corner2 - corner1) * simd_float3(colRatio, 0, rowRatio)
                
                let gridPoint = GridPoint(
                    id: "\(Character(UnicodeScalar(65 + row)!))\(col + 1)",
                    worldPosition: position,
                    row: row,
                    col: col,
                    measurement: nil,
                    photoAssetId: nil,
                    heightDeviation: nil
                )
                
                gridPoints.append(gridPoint)
                createGridVisual(for: gridPoint)
            }
        }
    }
    
    private func createGridVisual(for gridPoint: GridPoint) {
        guard let arView = arView else { return }
        
        let sphereMesh = MeshResource.generateSphere(radius: 0.02)
        let sphereMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
        
        sphereEntity.position = gridPoint.worldPosition
        
        let anchorEntity = AnchorEntity(world: gridPoint.worldPosition)
        anchorEntity.addChild(sphereEntity)
        arView.scene.addAnchor(anchorEntity)
        
        gridEntities.append(sphereEntity)
    }
    
    private func clearGrid() {
        gridEntities.forEach { $0.removeFromParent() }
        gridEntities = []
        gridPoints = []
    }
    
    // MARK: - Utility Methods
    private func projectPointOntoPlane(_ point: simd_float3, planeNormal: simd_float3, planePoint: simd_float3) -> simd_float3 {
        let distance = dot(point - planePoint, planeNormal)
        return point - distance * planeNormal
    }
    
    private func createRectangleTransform(from corner1: simd_float3, to corner2: simd_float3) -> simd_float4x4 {
        let center = (corner1 + corner2) / 2.0
        let forward = normalize(corner2 - corner1)
        let up = simd_float3(0, 1, 0)
        let right = normalize(cross(forward, up))
        
        var transform = simd_float4x4()
        transform.columns.0 = simd_float4(right, 0)
        transform.columns.1 = simd_float4(up, 0)
        transform.columns.2 = simd_float4(forward, 0)
        transform.columns.3 = simd_float4(center, 1)
        
        return transform
    }
    
    // MARK: - Session Control
    func pauseSession() {
        arSession?.pause()
        isSessionActive = false
    }
    
    func resumeSession() {
        guard let arSession = arSession else { return }
        arSession.resume()
        isSessionActive = true
    }
    
    func resetSession() {
        clearRectangle()
        clearGrid()
        currentState = .initializing
        errorMessage = nil
        
        guard let arSession = arSession else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isSessionActive = true
        currentState = .detectingPlanes
    }
    
    // MARK: - Data Export
    func getSessionData() -> ARSessionData {
        return ARSessionData(
            detectedPlanes: detectedPlanes,
            selectedPlane: selectedPlane,
            rectangleCorners: rectangleCorners,
            gridPoints: gridPoints,
            currentState: currentState,
            errorMessage: errorMessage
        )
    }
}

// MARK: - ARSessionDelegate Extension
extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.detectedPlanes.append(planeAnchor)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    if let index = self.detectedPlanes.firstIndex(where: { $0.identifier == planeAnchor.identifier }) {
                        self.detectedPlanes[index] = planeAnchor
                    }
                }
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.detectedPlanes.removeAll { $0.identifier == planeAnchor.identifier }
                    if self.selectedPlane?.identifier == planeAnchor.identifier {
                        self.selectedPlane = nil
                    }
                }
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.currentState = .error
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.currentState = .interrupted
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.currentState = .detectingPlanes
        }
    }
}

// MARK: - Supporting Types
enum ARSessionState {
    case initializing
    case detectingPlanes
    case planeSelected
    case placingRectangle
    case rectanglePlaced
    case error
    case interrupted
}

struct ARSessionData {
    let detectedPlanes: [ARPlaneAnchor]
    let selectedPlane: ARPlaneAnchor?
    let rectangleCorners: [simd_float3]
    let gridPoints: [GridPoint]
    let currentState: ARSessionState
    let errorMessage: String?
}

// MARK: - Extensions
extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(x, y, z)
    }
}
