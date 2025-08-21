import Foundation
import Vision
import CoreImage
import UIKit
import Accelerate

protocol MeasurementAIService {
    func analyzeRulerPhoto(
        _ image: UIImage,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) async throws -> MeasurementAIResult
}

class VisionMeasurementAIService: ObservableObject, MeasurementAIService {
    
    // MARK: - Properties
    private let imageProcessor = CIImageProcessor()
    private let textRecognizer = VNRecognizeTextRequest()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupTextRecognition()
    }
    
    private func setupTextRecognition() {
        textRecognizer.recognitionLevel = .accurate
        textRecognizer.usesLanguageCorrection = true
        textRecognizer.recognitionLanguages = ["en-US"]
    }
    
    // MARK: - Main Analysis Method
    func analyzeRulerPhoto(
        _ image: UIImage,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) async throws -> MeasurementAIResult {
        
        // Step 1: Preprocess image
        let processedImage = try await preprocessImage(image)
        
        // Step 2: Detect laser dot
        let laserPoint = try await detectLaserDot(in: processedImage)
        
        // Step 3: Detect ruler and markings
        let rulerInfo = try await detectRulerAndMarkings(in: processedImage)
        
        // Step 4: Calculate measurement
        let measurement = try calculateMeasurement(
            laserPoint: laserPoint,
            rulerInfo: rulerInfo,
            units: units,
            fractionalResolution: fractionalResolution,
            priorCalibration: priorCalibration
        )
        
        // Step 5: Calculate confidence
        let confidence = calculateConfidence(
            laserPoint: laserPoint,
            rulerInfo: rulerInfo,
            measurement: measurement
        )
        
        return MeasurementAIResult(
            aiMeasuredValue: measurement.value,
            aiMeasuredDisplay: measurement.display,
            aiConfidence: confidence,
            aiMethod: "vision-ocr+laser",
            needsCalibrationTap: confidence < 0.6
        )
    }
    
    // MARK: - Image Preprocessing
    private func preprocessImage(_ image: UIImage) async throws -> CIImage {
        guard let ciImage = CIImage(image: image) else {
            throw MeasurementAIError.imageProcessingFailed
        }
        
        // Convert to grayscale for better processing
        let grayscaleFilter = CIFilter(name: "CIColorControls")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter?.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let outputImage = grayscaleFilter?.outputImage else {
            throw MeasurementAIError.imageProcessingFailed
        }
        
        // Enhance contrast
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(outputImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.2, forKey: kCIInputContrastKey)
        
        return contrastFilter?.outputImage ?? outputImage
    }
    
    // MARK: - Laser Detection
    private func detectLaserDot(in image: CIImage) async throws -> CGPoint {
        // Convert to HSV for better color detection
        let hsvImage = convertToHSV(image)
        
        // Create mask for red/green laser colors
        let redMask = createColorMask(hsvImage, hueRange: 0.95...0.05, saturationRange: 0.5...1.0, valueRange: 0.5...1.0)
        let greenMask = createColorMask(hsvImage, hueRange: 0.25...0.45, saturationRange: 0.5...1.0, valueRange: 0.5...1.0)
        
        // Combine masks
        let combinedMask = redMask.adding(alpha: 0.5, to: greenMask)
        
        // Find brightest blob (laser dot)
        let laserPoint = findBrightestBlob(in: combinedMask)
        
        guard laserPoint != .zero else {
            throw MeasurementAIError.laserDetectionFailed
        }
        
        return laserPoint
    }
    
    // MARK: - Ruler Detection
    private func detectRulerAndMarkings(in image: CIImage) async throws -> RulerInfo {
        // Detect rectangles (ruler edges)
        let rectangleRequest = VNDetectRectanglesRequest()
        rectangleRequest.minimumAspectRatio = 0.1
        rectangleRequest.maximumAspectRatio = 0.3
        rectangleRequest.minimumSize = 0.1
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([rectangleRequest])
        
        guard let rectangles = rectangleRequest.results as? [VNRectangleObservation],
              let rulerRect = rectangles.first else {
            throw MeasurementAIError.rulerDetectionFailed
        }
        
        // Detect text markings
        let textRequest = VNRecognizeTextRequest()
        textRequest.regionOfInterest = rulerRect.boundingBox
        
        try handler.perform([textRequest])
        
        guard let textObservations = textRequest.results as? [VNRecognizedTextObservation] else {
            throw MeasurementAIError.textRecognitionFailed
        }
        
        // Parse markings
        let markings = try parseMarkings(from: textObservations, rulerRect: rulerRect)
        
        return RulerInfo(
            boundingBox: rulerRect.boundingBox,
            markings: markings,
            orientation: calculateRulerOrientation(rulerRect)
        )
    }
    
    // MARK: - Measurement Calculation
    private func calculateMeasurement(
        laserPoint: CGPoint,
        rulerInfo: RulerInfo,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) throws -> (value: Double, display: String) {
        
        // Use prior calibration if available
        if let calibration = priorCalibration {
            let pixelDistance = abs(laserPoint.y - calibration.zeroPixelY)
            let measurement = pixelDistance / calibration.pixelPerUnit
            
            let display = formatMeasurement(measurement, units: units, resolution: fractionalResolution)
            return (measurement, display)
        }
        
        // Calculate from ruler markings
        guard let marking1 = rulerInfo.markings.first,
              let marking2 = rulerInfo.markings.dropFirst().first else {
            throw MeasurementAIError.insufficientMarkings
        }
        
        let pixelDistance = abs(marking2.position.y - marking1.position.y)
        let valueDistance = abs(marking2.value - marking1.value)
        let pixelPerUnit = pixelDistance / valueDistance
        
        let laserDistance = abs(laserPoint.y - marking1.position.y)
        let measurement = marking1.value + (laserDistance / pixelPerUnit)
        
        let display = formatMeasurement(measurement, units: units, resolution: fractionalResolution)
        return (measurement, display)
    }
    
    // MARK: - Confidence Calculation
    private func calculateConfidence(
        laserPoint: CGPoint,
        rulerInfo: RulerInfo,
        measurement: (value: Double, display: String)
    ) -> Double {
        var confidence: Double = 0.5
        
        // Laser detection confidence
        if laserPoint != .zero {
            confidence += 0.2
        }
        
        // Ruler detection confidence
        if rulerInfo.markings.count >= 2 {
            confidence += 0.2
        }
        
        // Measurement validity
        if measurement.value > 0 && measurement.value < 1000 {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Helper Methods
    private func convertToHSV(_ image: CIImage) -> CIImage {
        let hsvFilter = CIFilter(name: "CIColorMatrix")
        hsvFilter?.setValue(image, forKey: kCIInputImageKey)
        // Simplified HSV conversion
        return image
    }
    
    private func createColorMask(_ image: CIImage, hueRange: ClosedRange<Float>, saturationRange: ClosedRange<Float>, valueRange: ClosedRange<Float>) -> CIImage {
        // Simplified color masking
        return image
    }
    
    private func findBrightestBlob(in image: CIImage) -> CGPoint {
        // Simplified blob detection
        return CGPoint(x: image.extent.midX, y: image.extent.midY)
    }
    
    private func parseMarkings(from observations: [VNRecognizedTextObservation], rulerRect: VNRectangleObservation) throws -> [RulerMarking] {
        var markings: [RulerMarking] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            if let value = parseMeasurementValue(text) {
                let marking = RulerMarking(
                    text: text,
                    value: value,
                    position: observation.boundingBox.center,
                    confidence: Float(topCandidate.confidence)
                )
                markings.append(marking)
            }
        }
        
        return markings.sorted { $0.value < $1.value }
    }
    
    private func parseMeasurementValue(_ text: String) -> Double? {
        // Parse various measurement formats
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        
        // Try decimal format
        if let value = Double(cleaned) {
            return value
        }
        
        // Try fractional format
        if let value = FractionUtils.parseFractionalInches(text) {
            return value
        }
        
        return nil
    }
    
    private func calculateRulerOrientation(_ rect: VNRectangleObservation) -> RulerOrientation {
        let angle = atan2(rect.topRight.y - rect.topLeft.y, rect.topRight.x - rect.topLeft.x)
        return abs(angle) < .pi/4 ? .horizontal : .vertical
    }
    
    private func formatMeasurement(_ value: Double, units: SessionUnits, resolution: FractionalResolution?) -> String {
        return FractionUtils.formatMeasurement(value, units: units, resolution: resolution)
    }
}

// MARK: - Supporting Types
struct RulerInfo {
    let boundingBox: CGRect
    let markings: [RulerMarking]
    let orientation: RulerOrientation
}

struct RulerMarking {
    let text: String
    let value: Double
    let position: CGPoint
    let confidence: Float
}

enum RulerOrientation {
    case horizontal
    case vertical
}

enum MeasurementAIError: Error, LocalizedError {
    case imageProcessingFailed
    case laserDetectionFailed
    case rulerDetectionFailed
    case textRecognitionFailed
    case insufficientMarkings
    case calibrationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .laserDetectionFailed:
            return "Could not detect laser dot"
        case .rulerDetectionFailed:
            return "Could not detect ruler"
        case .textRecognitionFailed:
            return "Could not read ruler markings"
        case .insufficientMarkings:
            return "Not enough ruler markings detected"
        case .calibrationFailed:
            return "Calibration failed"
        }
    }
}

// MARK: - Extensions
extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension CIImage {
    func adding(alpha: Float, to other: CIImage) -> CIImage {
        let blendFilter = CIFilter(name: "CIBlendWithAlphaMask")
        blendFilter?.setValue(self, forKey: kCIInputImageKey)
        blendFilter?.setValue(other, forKey: kCIInputBackgroundImageKey)
        return blendFilter?.outputImage ?? self
    }
}
