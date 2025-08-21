import Foundation
import Vision
import CoreImage
import UIKit
import Accelerate

// MARK: - AI Measurement Service

protocol MeasurementAIService {
    func analyzeRulerPhoto(
        _ image: UIImage,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) async throws -> MeasurementAIResult
}

class VisionMeasurementAIService: MeasurementAIService {
    
    /// Analyze a ruler photo to extract measurement reading
    /// - Parameters:
    ///   - image: Photo of ruler with laser dot
    ///   - units: Units for the measurement
    ///   - fractionalResolution: Fractional resolution for imperial
    ///   - priorCalibration: Previous calibration data
    /// - Returns: AI measurement result
    func analyzeRulerPhoto(
        _ image: UIImage,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) async throws -> MeasurementAIResult {
        
        // Step 1: Preprocess image
        let preprocessedImage = try await preprocessImage(image)
        
        // Step 2: Detect laser dot
        let laserPoint = try await detectLaserDot(preprocessedImage)
        
        // Step 3: Detect ruler orientation and scale
        let rulerInfo = try await detectRulerOrientation(preprocessedImage)
        
        // Step 4: Extract ruler markings and labels
        let markings = try await extractRulerMarkings(preprocessedImage, rulerInfo: rulerInfo)
        
        // Step 5: Calculate measurement
        let measurement = try await calculateMeasurement(
            laserPoint: laserPoint,
            markings: markings,
            rulerInfo: rulerInfo,
            units: units,
            fractionalResolution: fractionalResolution,
            priorCalibration: priorCalibration
        )
        
        return measurement
    }
    
    // MARK: - Private Methods
    
    /// Preprocess image for better analysis
    private func preprocessImage(_ image: UIImage) async throws -> CIImage {
        guard let ciImage = CIImage(image: image) else {
            throw MeasurementAIError.invalidImage
        }
        
        // Apply filters for better contrast and edge detection
        let filters: [CIFilter] = [
            // Enhance contrast
            {
                let filter = CIFilter(name: "CIColorControls")
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                filter?.setValue(1.1, forKey: kCIInputContrastKey)
                filter?.setValue(0.0, forKey: kCIInputSaturationKey)
                return filter
            }(),
            
            // Reduce noise
            {
                let filter = CIFilter(name: "CINoiseReduction")
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                filter?.setValue(0.02, forKey: kCIInputNoiseLevelKey)
                filter?.setValue(40.0, forKey: kCIInputSharpnessKey)
                return filter
            }()
        ].compactMap { $0 }
        
        var processedImage = ciImage
        for filter in filters {
            if let output = filter.outputImage {
                processedImage = output
            }
        }
        
        return processedImage
    }
    
    /// Detect laser dot in the image
    private func detectLaserDot(_ image: CIImage) async throws -> CGPoint {
        // Convert to HSV color space for better laser detection
        let hsvImage = convertToHSV(image)
        
        // Create mask for red and green laser colors
        let redMask = createColorMask(hsvImage, hueRange: (0.95...1.0, 0.0...0.05), saturationRange: 0.5...1.0, valueRange: 0.5...1.0)
        let greenMask = createColorMask(hsvImage, hueRange: 0.25...0.35, saturationRange: 0.5...1.0, valueRange: 0.5...1.0)
        
        // Combine masks
        let combinedMask = redMask.adding(greenMask)
        
        // Find the brightest compact blob
        let laserPoint = findBrightestBlob(combinedMask)
        
        guard laserPoint != .zero else {
            throw MeasurementAIError.laserDetectionFailed
        }
        
        return laserPoint
    }
    
    /// Detect ruler orientation and scale
    private func detectRulerOrientation(_ image: CIImage) async throws -> RulerInfo {
        // Use Vision framework to detect rectangles and contours
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 3.0 // Rulers are typically long rectangles
        request.maximumAspectRatio = 20.0
        request.minimumSize = 0.1
        request.maximumObservations = 5
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNRectangleObservation],
              let rulerRect = observations.first else {
            throw MeasurementAIError.rulerDetectionFailed
        }
        
        // Calculate ruler orientation
        let angle = atan2(rulerRect.topRight.y - rulerRect.topLeft.y,
                         rulerRect.topRight.x - rulerRect.topLeft.x)
        
        return RulerInfo(
            boundingBox: rulerRect.boundingBox,
            angle: angle,
            axis: abs(angle) < .pi/4 ? .horizontal : .vertical
        )
    }
    
    /// Extract ruler markings and labels
    private func extractRulerMarkings(_ image: CIImage, rulerInfo: RulerInfo) async throws -> [RulerMarking] {
        // Rotate image to align ruler horizontally
        let rotatedImage = rotateImage(image, angle: -rulerInfo.angle)
        
        // Use Vision framework for text recognition
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(ciImage: rotatedImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            throw MeasurementAIError.textRecognitionFailed
        }
        
        // Filter and process text observations
        let markings = observations.compactMap { observation -> RulerMarking? in
            guard let topCandidate = observation.topCandidates(1).first else { return nil }
            
            // Extract numeric values
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            
            // Try to parse as number
            if let value = Double(text) {
                return RulerMarking(
                    value: value,
                    text: text,
                    confidence: confidence,
                    boundingBox: observation.boundingBox
                )
            }
            
            return nil
        }
        
        return markings.sorted { $0.value < $1.value }
    }
    
    /// Calculate final measurement
    private func calculateMeasurement(
        laserPoint: CGPoint,
        markings: [RulerMarking],
        rulerInfo: RulerInfo,
        units: SessionUnits,
        fractionalResolution: FractionalResolution?,
        priorCalibration: Calibration?
    ) async throws -> MeasurementAIResult {
        
        guard markings.count >= 2 else {
            throw MeasurementAIError.insufficientMarkings
        }
        
        // Calculate pixels per unit
        let pixelPerUnit: Double
        let zeroPixelY: CGFloat
        
        if let calibration = priorCalibration {
            pixelPerUnit = calibration.pixelPerUnit
            zeroPixelY = calibration.zeroPixelY
        } else {
            // Calculate from markings
            let (ppu, zeroY) = calculatePixelPerUnit(markings: markings, units: units)
            pixelPerUnit = ppu
            zeroPixelY = zeroY
        }
        
        // Project laser point onto ruler axis
        let projectedPoint = projectPointOntoAxis(laserPoint, rulerInfo: rulerInfo)
        
        // Calculate measurement
        let measurementInPixels = projectedPoint.y - zeroPixelY
        let measurementInUnits = measurementInPixels / pixelPerUnit
        
        // Format measurement
        let displayValue: String
        if units == .imperial, let resolution = fractionalResolution {
            displayValue = FractionUtils.formatFractionalInches(measurementInUnits, resolution: resolution)
        } else {
            displayValue = String(format: "%.1f", measurementInUnits)
        }
        
        // Calculate confidence
        let confidence = calculateConfidence(
            markings: markings,
            pixelPerUnit: pixelPerUnit,
            laserPoint: laserPoint
        )
        
        return MeasurementAIResult(
            aiMeasuredValue: measurementInUnits,
            aiMeasuredDisplay: "\(displayValue) \(units.unitLabel)",
            aiConfidence: confidence,
            aiMethod: "vision-ocr+laser",
            needsCalibrationTap: confidence < 0.6
        )
    }
    
    // MARK: - Helper Methods
    
    private func convertToHSV(_ image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorMatrix")
        filter?.setValue(image, forKey: kCIInputImageKey)
        // Simplified HSV conversion - in practice, you'd use a more sophisticated approach
        return image
    }
    
    private func createColorMask(_ image: CIImage, hueRange: ClosedRange<Double>, saturationRange: ClosedRange<Double>, valueRange: ClosedRange<Double>) -> CIImage {
        // Create color mask for laser detection
        // This is a simplified implementation
        return image
    }
    
    private func findBrightestBlob(_ mask: CIImage) -> CGPoint {
        // Find the brightest compact region in the mask
        // This is a simplified implementation
        return CGPoint(x: 100, y: 100) // Placeholder
    }
    
    private func rotateImage(_ image: CIImage, angle: Double) -> CIImage {
        let transform = CGAffineTransform(rotationAngle: angle)
        return image.transformed(by: transform)
    }
    
    private func calculatePixelPerUnit(markings: [RulerMarking], units: SessionUnits) -> (pixelPerUnit: Double, zeroPixelY: CGFloat) {
        guard markings.count >= 2 else {
            return (1.0, 0.0)
        }
        
        // Use the first two markings to calculate scale
        let marking1 = markings[0]
        let marking2 = markings[1]
        
        let pixelDistance = abs(marking2.boundingBox.midY - marking1.boundingBox.midY)
        let unitDistance = abs(marking2.value - marking1.value)
        
        let pixelPerUnit = pixelDistance / unitDistance
        let zeroPixelY = marking1.boundingBox.midY - (marking1.value * pixelPerUnit)
        
        return (pixelPerUnit, zeroPixelY)
    }
    
    private func projectPointOntoAxis(_ point: CGPoint, rulerInfo: RulerInfo) -> CGPoint {
        // Project point onto the ruler's axis
        // Simplified implementation
        return point
    }
    
    private func calculateConfidence(markings: [RulerMarking], pixelPerUnit: Double, laserPoint: CGPoint) -> Double {
        // Calculate confidence based on:
        // 1. Number of detected markings
        // 2. Consistency of pixel per unit ratio
        // 3. Laser point quality
        
        var confidence = 0.5 // Base confidence
        
        // Factor 1: Number of markings
        confidence += min(Double(markings.count) * 0.1, 0.3)
        
        // Factor 2: Marking confidence
        let avgMarkingConfidence = markings.map { $0.confidence }.reduce(0, +) / Double(markings.count)
        confidence += avgMarkingConfidence * 0.2
        
        // Factor 3: Pixel per unit consistency (simplified)
        confidence += 0.1
        
        return min(confidence, 1.0)
    }
}

// MARK: - Supporting Types

struct RulerInfo {
    let boundingBox: CGRect
    let angle: Double
    let axis: Axis
}

struct RulerMarking {
    let value: Double
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

enum MeasurementAIError: Error, LocalizedError {
    case invalidImage
    case laserDetectionFailed
    case rulerDetectionFailed
    case textRecognitionFailed
    case insufficientMarkings
    case calibrationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .laserDetectionFailed:
            return "Could not detect laser dot"
        case .rulerDetectionFailed:
            return "Could not detect ruler"
        case .textRecognitionFailed:
            return "Could not read ruler markings"
        case .insufficientMarkings:
            return "Not enough ruler markings detected"
        case .calibrationRequired:
            return "Calibration required for accurate measurement"
        }
    }
}
