import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARCaptureView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let session: Session
    @State private var arSession: ARSession?
    @State private var arView: ARView?
    @State private var currentState: ARCaptureState = .detectingPlane
    @State private var detectedPlanes: [ARPlaneAnchor] = []
    @State private var rectangleCorners: [simd_float3] = []
    @State private var rectangleTransform: simd_float4x4 = matrix_identity_float4x4
    @State private var gridPoints: [GridPoint] = []
    @State private var selectedGridPoint: GridPoint?
    @State private var showingPhotoCapture = false
    @State private var showingGridSettings = false
    @State private var showingToleranceSettings = false
    @State private var showingHeatmap = false
    @State private var tolerance: Double
    @State private var units: SessionUnits
    @State private var gridRows: Int
    @State private var gridCols: Int
    
    @State private var rectangleWidth: Float = 0
    @State private var rectangleLength: Float = 0
    
    init(session: Session) {
        self.session = session
        self._tolerance = State(initialValue: session.tolerance)
        self._units = State(initialValue: session.units)
        self._gridRows = State(initialValue: session.rows)
        self._gridCols = State(initialValue: session.cols)
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(
                arSession: $arSession,
                arView: $arView,
                currentState: $currentState,
                detectedPlanes: $detectedPlanes,
                rectangleCorners: $rectangleCorners,
                rectangleTransform: $rectangleTransform,
                gridPoints: $gridPoints,
                selectedGridPoint: $selectedGridPoint,
                tolerance: tolerance,
                units: units,
                gridRows: gridRows,
                gridCols: gridCols,
                showingHeatmap: showingHeatmap
            )
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top toolbar
                topToolbar
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
            .padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            setupARSession()
        }
        .onDisappear {
            cleanupARSession()
        }
        .sheet(isPresented: $showingPhotoCapture) {
            if let selectedPoint = selectedGridPoint {
                PhotoCaptureView(
                    session: session,
                    gridPoint: selectedPoint,
                    onPhotoCaptured: { photoAsset in
                        handlePhotoCaptured(photoAsset, for: selectedPoint)
                    }
                )
            }
        }
        .sheet(isPresented: $showingGridSettings) {
            GridSettingsView(
                rows: $gridRows,
                cols: $gridCols,
                onApply: {
                    generateGrid()
                }
            )
        }
        .sheet(isPresented: $showingToleranceSettings) {
            ToleranceSettingsView(
                tolerance: $tolerance,
                units: $units
            )
        }
    }
    
    // MARK: - UI Components
    
    private var topToolbar: some View {
        HStack {
            Button("Back") {
                dismiss()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            
            Spacer()
            
            // State indicator
            Text(currentState.displayText)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            
            Spacer()
            
            // Settings button
            Button("Settings") {
                showingToleranceSettings = true
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Rectangle info
            if currentState == .rectanglePlaced || currentState == .gridGenerated {
                rectangleInfoView
            }
            
            // Action buttons
            HStack(spacing: 16) {
                switch currentState {
                case .detectingPlane:
                    planeDetectionView
                case .planeDetected:
                    planeDetectedView
                case .placingRectangle:
                    rectanglePlacementView
                case .rectanglePlaced:
                    rectanglePlacedView
                case .gridGenerated:
                    gridGeneratedView
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
    
    private var rectangleInfoView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Rectangle Size")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("\(formatMeasurement(Double(rectangleWidth), units: units)) × \(formatMeasurement(Double(rectangleLength), units: units))")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Grid")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("\(gridRows) × \(gridCols)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var planeDetectionView: some View {
        VStack {
            Text("Point camera at floor surface")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
    
    private var planeDetectedView: some View {
        Button("Start Rectangle Placement") {
            currentState = .placingRectangle
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.blue)
        .cornerRadius(8)
    }
    
    private var rectanglePlacementView: some View {
        VStack(spacing: 12) {
            Text("Tap two corners to place rectangle")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if rectangleCorners.count == 1 {
                Text("Tap second corner")
                    .foregroundColor(.yellow)
            }
            
            Button("Reset") {
                resetRectangle()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .cornerRadius(8)
        }
    }
    
    private var rectanglePlacedView: some View {
        HStack(spacing: 16) {
            Button("Generate Grid") {
                generateGrid()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(8)
            
            Button("Grid Settings") {
                showingGridSettings = true
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(8)
        }
    }
    
    private var gridGeneratedView: some View {
        HStack(spacing: 16) {
            Button("Heatmap") {
                showingHeatmap.toggle()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(showingHeatmap ? Color.green : Color.blue)
            .cornerRadius(8)
            
            Button("Complete Session") {
                completeSession()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(8)
        }
    }
    
    // MARK: - AR Session Management
    
    private func setupARSession() {
        guard let arView = arView else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.run(configuration)
        arView.session.delegate = ARSessionDelegate.shared
        
        // Set up tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
    }
    
    private func cleanupARSession() {
        arSession?.pause()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        switch currentState {
        case .placingRectangle:
            handleRectanglePlacement(at: location, in: arView)
        case .gridGenerated:
            handleGridPointSelection(at: location, in: arView)
        default:
            break
        }
    }
    
    private func handleRectanglePlacement(at location: CGPoint, in arView: ARView) {
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        guard let result = results.first else { return }
        
        let worldPosition = result.worldTransform.columns.3
        let point = simd_float3(worldPosition.x, worldPosition.y, worldPosition.z)
        
        if rectangleCorners.count < 2 {
            rectangleCorners.append(point)
            
            if rectangleCorners.count == 2 {
                finalizeRectangle()
            }
        }
    }
    
    private func handleGridPointSelection(at location: CGPoint, in arView: ARView) {
        // Find closest grid point to tap location
        let tapPosition = arView.convert(location, from: nil)
        
        var closestPoint: GridPoint?
        var closestDistance: Float = Float.greatestFiniteMagnitude
        
        for point in gridPoints {
            let screenPosition = arView.project(point.worldPosition)
            let distance = sqrt(pow(Float(screenPosition.x - tapPosition.x), 2) + pow(Float(screenPosition.y - tapPosition.y), 2))
            
            if distance < closestDistance {
                closestDistance = distance
                closestPoint = point
            }
        }
        
        if let point = closestPoint, closestDistance < 50 { // 50 pixel threshold
            selectedGridPoint = point
            showingPhotoCapture = true
        }
    }
    
    private func finalizeRectangle() {
        guard rectangleCorners.count == 2 else { return }
        
        let cornerA = rectangleCorners[0]
        let cornerB = rectangleCorners[1]
        
        rectangleTransform = GeometryUtils.createRectangleTransform(from: cornerA, to: cornerB)
        let dimensions = GeometryUtils.calculateRectangleDimensions(from: cornerA, to: cornerB)
        
        rectangleWidth = dimensions.width
        rectangleLength = dimensions.length
        
        currentState = .rectanglePlaced
    }
    
    private func generateGrid() {
        guard rectangleCorners.count == 2 else { return }
        
        gridPoints = GeometryUtils.gridWorldPositions(
            rectTransform: rectangleTransform,
            width: rectangleWidth,
            length: rectangleLength,
            rows: gridRows,
            cols: gridCols
        )
        
        // Update session with grid points
        var updatedSession = session
        updatedSession.rectWorldTransform = rectangleTransform
        updatedSession.rectWidth = rectangleWidth
        updatedSession.rectLength = rectangleLength
        updatedSession.rows = gridRows
        updatedSession.cols = gridCols
        
        Task {
            try await dataStore.saveSession(updatedSession)
            
            for var point in gridPoints {
                point.sessionId = session.id
                try await dataStore.saveGridPoint(point)
            }
        }
        
        currentState = .gridGenerated
    }
    
    private func resetRectangle() {
        rectangleCorners.removeAll()
        rectangleTransform = matrix_identity_float4x4
        rectangleWidth = 0
        rectangleLength = 0
        currentState = .placingRectangle
    }
    
    private func handlePhotoCaptured(_ photoAsset: PhotoAsset, for gridPoint: GridPoint) {
        // Update grid point with photo
        var updatedPoint = gridPoint
        updatedPoint.photoIds.append(photoAsset.id)
        
        Task {
            try await dataStore.saveGridPoint(updatedPoint)
        }
    }
    
    private func completeSession() {
        var updatedSession = session
        updatedSession.completedAt = Date()
        
        Task {
            try await dataStore.saveSession(updatedSession)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Types

enum ARCaptureState {
    case detectingPlane
    case planeDetected
    case placingRectangle
    case rectanglePlaced
    case gridGenerated
    
    var displayText: String {
        switch self {
        case .detectingPlane:
            return "Detecting Floor"
        case .planeDetected:
            return "Floor Detected"
        case .placingRectangle:
            return "Place Rectangle"
        case .rectanglePlaced:
            return "Rectangle Placed"
        case .gridGenerated:
            return "Grid Ready"
        }
    }
}

// MARK: - AR Session Delegate

class ARSessionDelegate: NSObject, ARSessionDelegate {
    static let shared = ARSessionDelegate()
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle new plane anchors
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Handle updated plane anchors
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @Binding var arSession: ARSession?
    @Binding var arView: ARView?
    @Binding var currentState: ARCaptureState
    @Binding var detectedPlanes: [ARPlaneAnchor]
    @Binding var rectangleCorners: [simd_float3]
    @Binding var rectangleTransform: simd_float4x4
    @Binding var gridPoints: [GridPoint]
    @Binding var selectedGridPoint: GridPoint?
    let tolerance: Double
    let units: SessionUnits
    let gridRows: Int
    let gridCols: Int
    let showingHeatmap: Bool
    
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView = view
        arSession = view.session
        return view
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update AR overlay based on state
        updateAROverlay(for: uiView)
    }
    
    private func updateAROverlay(for arView: ARView) {
        // Clear existing overlays
        arView.scene.anchors.removeAll()
        
        // Add rectangle overlay
        if rectangleCorners.count >= 2 {
            addRectangleOverlay(to: arView)
        }
        
        // Add grid overlay
        if !gridPoints.isEmpty {
            addGridOverlay(to: arView)
        }
    }
    
    private func addRectangleOverlay(to arView: ARView) {
        // Create rectangle entity
        let rectangle = ModelEntity()
        
        // Add to scene
        let anchor = AnchorEntity(world: rectangleTransform)
        anchor.addChild(rectangle)
        arView.scene.addAnchor(anchor)
    }
    
    private func addGridOverlay(to arView: ARView) {
        for point in gridPoints {
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.02))
            sphere.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
            
            let anchor = AnchorEntity(world: point.worldPosition)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
        }
    }
}

#Preview {
    ARCaptureView(session: Session(
        locationId: UUID(),
        units: .imperial,
        tolerance: 0.5,
        rows: 4,
        cols: 4
    ))
    .environmentObject(DataStore())
}
