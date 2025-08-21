import SwiftUI
import AVFoundation
import UIKit
import Vision

struct PhotoCaptureView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    let session: Session
    let gridPoint: GridPoint
    let onPhotoCaptured: (PhotoAsset) -> Void
    
    @State private var cameraSession: AVCaptureSession?
    @State private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @State private var capturedImage: UIImage?
    @State private var aiResult: MeasurementAIResult?
    @State private var showingAIResult = false
    @State private var showingManualEntry = false
    @State private var manualMeasurement: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingCalibration = false
    @State private var calibrationPoint: CGPoint?
    
    @StateObject private var aiService = VisionMeasurementAIService()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreviewView(
                    session: cameraSession,
                    previewLayer: cameraPreviewLayer
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
                
                // Loading overlay
                if isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cleanupCamera()
        }
        .sheet(isPresented: $showingAIResult) {
            AIResultView(
                aiResult: aiResult,
                onAccept: acceptAIResult,
                onEdit: { showingManualEntry = true },
                onRescan: capturePhoto,
                onCalibrate: { showingCalibration = true }
            )
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(
                measurement: $manualMeasurement,
                units: session.units,
                onSave: saveManualMeasurement
            )
        }
        .sheet(isPresented: $showingCalibration) {
            CalibrationView(
                image: capturedImage,
                onCalibrate: performCalibration
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - UI Components
    
    private var topToolbar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            
            Spacer()
            
            Text("Point \(gridPoint.rowLetter)\(gridPoint.colIndex)")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            
            Spacer()
            
            Button("Flash") {
                toggleFlash()
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
            // Instructions
            Text("Position ruler with laser dot in frame")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            
            // Capture button
            Button(action: capturePhoto) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 4)
                    )
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analyzing measurement...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Camera Management
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showError("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            cameraSession = session
            session.startRunning()
            
        } catch {
            showError("Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
    private func cleanupCamera() {
        cameraSession?.stopRunning()
        cameraSession = nil
    }
    
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.hasTorch {
                device.torchMode = device.torchMode == .on ? .off : .on
            }
            
            device.unlockForConfiguration()
        } catch {
            showError("Failed to toggle flash")
        }
    }
    
    // MARK: - Photo Capture
    
    private func capturePhoto() {
        guard let session = cameraSession,
              let photoOutput = session.outputs.first as? AVCapturePhotoOutput else {
            showError("Camera not ready")
            return
        }
        
        isLoading = true
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { [weak self] image in
            DispatchQueue.main.async {
                self?.handleCapturedPhoto(image)
            }
        })
    }
    
    private func handleCapturedPhoto(_ image: UIImage) {
        capturedImage = image
        isLoading = false
        
        // Analyze with AI
        Task {
            do {
                let result = try await aiService.analyzeRulerPhoto(
                    image,
                    units: session.units,
                    fractionalResolution: session.units == .imperial ? .sixteenth : nil,
                    priorCalibration: nil // TODO: Load from session
                )
                
                await MainActor.run {
                    aiResult = result
                    showingAIResult = true
                }
            } catch {
                await MainActor.run {
                    showError("AI analysis failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - AI Result Handling
    
    private func acceptAIResult() {
        guard let result = aiResult else { return }
        
        // Save photo and measurement
        Task {
            do {
                let photoAsset = try await savePhoto()
                let updatedPoint = updateGridPoint(with: result)
                
                try await dataStore.saveGridPoint(updatedPoint)
                
                await MainActor.run {
                    onPhotoCaptured(photoAsset)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    showError("Failed to save measurement: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveManualMeasurement() {
        guard let measurement = FractionUtils.parseFractionalInches(manualMeasurement) else {
            showError("Invalid measurement format")
            return
        }
        
        let result = MeasurementAIResult(
            aiMeasuredValue: measurement,
            aiMeasuredDisplay: manualMeasurement,
            aiConfidence: 1.0,
            aiMethod: "manual",
            needsCalibrationTap: false
        )
        
        aiResult = result
        acceptAIResult()
    }
    
    private func performCalibration(at point: CGPoint) {
        // TODO: Implement calibration logic
        showingCalibration = false
        capturePhoto() // Re-analyze with calibration
    }
    
    // MARK: - Helper Methods
    
    private func savePhoto() async throws -> PhotoAsset {
        guard let image = capturedImage else {
            throw PhotoCaptureError.noImage
        }
        
        return try await dataStore.savePhoto(image, for: session.id, gridPointId: gridPoint.id)
    }
    
    private func updateGridPoint(with result: MeasurementAIResult) -> GridPoint {
        var updatedPoint = gridPoint
        updatedPoint.aiMeasuredValue = result.aiMeasuredValue
        updatedPoint.aiMeasuredDisplay = result.aiMeasuredDisplay
        updatedPoint.aiConfidence = result.aiConfidence
        updatedPoint.aiMethod = result.aiMethod
        updatedPoint.measuredUserValue = result.aiMeasuredValue
        updatedPoint.measuredUserDisplay = result.aiMeasuredDisplay
        updatedPoint.isUserOverridden = false
        return updatedPoint
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        isLoading = false
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let session = session {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Photo Capture Delegate

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage) -> Void
    
    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            return
        }
        
        completion(image)
    }
}

// MARK: - AI Result View

struct AIResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    let aiResult: MeasurementAIResult?
    let onAccept: () -> Void
    let onEdit: () -> Void
    let onRescan: () -> Void
    let onCalibrate: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Result display
                VStack(spacing: 16) {
                    Text("AI Measurement")
                        .font(.headline)
                    
                    if let result = aiResult {
                        Text(result.aiMeasuredDisplay)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("Confidence:")
                            Text("\(Int(result.aiConfidence * 100))%")
                                .foregroundColor(confidenceColor(result.aiConfidence))
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Accept") {
                        onAccept()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    
                    Button("Edit") {
                        onEdit()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Re-scan") {
                        onRescan()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
                    
                    if let result = aiResult, result.aiConfidence < 0.6 {
                        Button("Calibrate") {
                            onCalibrate()
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Measurement Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Manual Entry View

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var measurement: String
    let units: SessionUnits
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Enter Measurement")
                    .font(.headline)
                
                TextField("Measurement", text: $measurement)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Text("Format: \(units == .imperial ? "1 3/8" : "35.5")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    onSave()
                    dismiss()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Calibration View

struct CalibrationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage?
    let onCalibrate: (CGPoint) -> Void
    
    @State private var tapLocation: CGPoint?
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture { location in
                            tapLocation = location
                        }
                        .overlay(
                            Group {
                                if let location = tapLocation {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 20, height: 20)
                                        .position(location)
                                }
                            }
                        )
                }
                
                Text("Tap on a known measurement mark (e.g., 0 or 1 inch)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Calibrate") {
                    if let location = tapLocation {
                        onCalibrate(location)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .padding()
                .disabled(tapLocation == nil)
            }
            .navigationTitle("Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Error Types

enum PhotoCaptureError: Error {
    case noImage
    case saveFailed
}

#Preview {
    PhotoCaptureView(
        session: Session(
            locationId: UUID(),
            units: .imperial,
            tolerance: 0.5,
            rows: 4,
            cols: 4
        ),
        gridPoint: GridPoint(
            sessionId: UUID(),
            rowLetter: "A",
            colIndex: 1,
            worldPosition: simd_float3(0, 0, 0)
        ),
        onPhotoCaptured: { _ in }
    )
    .environmentObject(DataStore())
}
