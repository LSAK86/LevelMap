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
        
        // Create visual rectangle
        createRectangleVisual()
        
        // Generate grid
        generateGrid()
    }
    
    private func createRectangleVisual() {
        guard let arView = arView else { return }
        
        // Remove existing rectangle
        rectangleEntity?.removeFromParent()
        
        // Create rectangle mesh
        let rectangleMesh = MeshResource.generatePlane(width: rectangleWidth, depth: rectangleLength)
        let rectangleMaterial = SimpleMaterial(color: .blue.withAlphaComponent(0.3), isMetallic: false)
        rectangleEntity = ModelEntity(mesh: rectangleMesh, materials: [rectangleMaterial])
        
        // Position rectangle
        let center = rectangleCorners.reduce(simd_float3.zero, +) / Float(rectangleCorners.count)
        rectangleEntity?.position = center
        
        // Add to scene
        arView.scene.addAnchor(AnchorEntity(world: center))
        arView.scene.anchors.first?.addChild(rectangleEntity!)
    }
    
    // MARK: - Grid Management
    func configureGrid(rows: Int, cols: Int) {
        gridRows = max(2, min(rows, 26)) // A-Z
        gridCols = max(2, min(cols, 50))
        
        if currentState == .rectanglePlaced {
            generateGrid()
        }
    }
    
    private func generateGrid() {
        guard rectangleCorners.count == 4 else { return }
        
        // Clear existing grid
        clearGrid()
        
        // Generate grid points
        let gridPositions = GeometryUtils.gridWorldPositions(
            rectTransform: createRectangleTransform(),
            width: rectangleWidth,
            length: rectangleLength,
            rows: gridRows,
            cols: gridCols
        )
        
        // Create grid points
        gridPoints = gridPositions.enumerated().map { index, position in
            let row = index / gridCols
            let col = index % gridCols
            let label = "\(Character(UnicodeScalar(65 + row)!))\(col + 1)"
            
            return GridPoint(
                id: UUID(),
                sessionId: UUID(), // Will be set by session
                label: label,
                worldPosition: position,
                measuredValue: nil,
                heightDeviation: nil,
                isCompleted: false,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        // Create visual grid
        createGridVisual()
        
        currentState = .gridGenerated
    }
    
    private func createGridVisual() {
        guard let arView = arView else { return }
        
        // Remove existing grid
        gridEntities.forEach { $0.removeFromParent() }
        gridEntities.removeAll()
        
        // Create grid points
        for gridPoint in gridPoints {
            let sphereMesh = MeshResource.generateSphere(radius: 0.02)
            let sphereMaterial = SimpleMaterial(color: .green, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
            
            sphereEntity.position = gridPoint.worldPosition
            gridEntities.append(sphereEntity)
            
            // Add to scene
            arView.scene.anchors.first?.addChild(sphereEntity)
        }
    }
    
    private func clearGrid() {
        gridEntities.forEach { $0.removeFromParent() }
        gridEntities.removeAll()
        gridPoints.removeAll()
    }
    
    // MARK: - Utility Methods
    private func projectPointOntoPlane(_ point: simd_float3, planeNormal: simd_float3, planePoint: simd_float3) -> simd_float3 {
        let distance = dot(point - planePoint, planeNormal)
        return point - distance * planeNormal
    }
    
    private func createRectangleTransform() -> simd_float4x4 {
        let center = rectangleCorners.reduce(simd_float3.zero, +) / Float(rectangleCorners.count)
        
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(center.x, center.y, center.z, 1.0)
        
        return transform
    }
    
    private func clearRectangle() {
        rectangleEntity?.removeFromParent()
        rectangleEntity = nil
        rectangleCorners.removeAll()
        clearGrid()
    }
    
    // MARK: - Session Control
    func pauseSession() {
        arSession?.pause()
        isSessionActive = false
    }
    
    func resumeSession() {
        guard let arView = arView else { return }
        configureSession(arView)
    }
    
    func resetSession() {
        guard let arView = arView else { return }
        
        clearRectangle()
        clearGrid()
        detectedPlanes.removeAll()
        selectedPlane = nil
        currentState = .initializing
        
        configureSession(arView)
    }
    
    // MARK: - Data Export
    func getSessionData() -> ARSessionData {
        return ARSessionData(
            rectangleCorners: rectangleCorners,
            gridPoints: gridPoints,
            rectangleWidth: rectangleWidth,
            rectangleLength: rectangleLength,
            gridRows: gridRows,
            gridCols: gridCols
        )
    }
}

// MARK: - ARSessionDelegate
extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.detectedPlanes.append(planeAnchor)
                    if self.currentState == .detectingPlanes {
                        self.currentState = .planesDetected
                    }
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
                        self.currentState = .detectingPlanes
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
    case planesDetected
    case planeSelected
    case placingRectangle
    case rectanglePlaced
    case gridGenerated
    case interrupted
    case error
}

struct ARSessionData {
    let rectangleCorners: [simd_float3]
    let gridPoints: [GridPoint]
    let rectangleWidth: Float
    let rectangleLength: Float
    let gridRows: Int
    let gridCols: Int
}

// MARK: - Extensions
extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(x, y, z)
    }
}
