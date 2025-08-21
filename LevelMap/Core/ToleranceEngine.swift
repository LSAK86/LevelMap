import Foundation
import simd

// MARK: - Tolerance Engine

struct ToleranceEngine {
    
    /// Calculate tolerance statistics for a set of grid points
    /// - Parameters:
    ///   - points: Array of grid points with measurements
    ///   - tolerance: Tolerance value in the session's units
    ///   - units: Units of the measurements
    /// - Returns: Tolerance statistics
    static func calculateToleranceStats(points: [GridPoint], tolerance: Double, units: SessionUnits) -> ToleranceStats {
        return ToleranceStats(points: points, tolerance: tolerance)
    }
    
    /// Calculate height deviations for grid points using LiDAR data
    /// - Parameters:
    ///   - points: Array of grid points
    ///   - session: Session containing rectangle information
    /// - Returns: Updated grid points with height deviations
    static func calculateHeightDeviations(points: [GridPoint], session: Session) -> [GridPoint] {
        guard session.lidarAvailable else {
            return points
        }
        
        // Get the rectangle plane normal and point
        let planeNormal = simd_float3(0, 1, 0) // Assuming horizontal plane
        let planePoint = simd_float3(session.rectWorldTransform[3].x, 
                                    session.rectWorldTransform[3].y, 
                                    session.rectWorldTransform[3].z)
        
        // Calculate average height from all points
        let heights = points.compactMap { $0.lidarHeight }
        guard !heights.isEmpty else {
            return points
        }
        
        let averageHeight = heights.reduce(0, +) / Double(heights.count)
        
        // Update points with deviations
        return points.map { point in
            var updatedPoint = point
            if let height = point.lidarHeight {
                updatedPoint.deviationFromAvg = height - averageHeight
                
                // Convert deviation to session units for pass/fail calculation
                let deviationInMeters = abs(updatedPoint.deviationFromAvg ?? 0)
                let deviationInUnits = GeometryUtils.convertFromMeters(Float(deviationInMeters), to: session.units)
                updatedPoint.passFail = deviationInUnits <= session.tolerance
            }
            return updatedPoint
        }
    }
    
    /// Calculate pass/fail status for measurements
    /// - Parameters:
    ///   - points: Array of grid points
    ///   - tolerance: Tolerance value in session units
    ///   - units: Units of the measurements
    /// - Returns: Updated grid points with pass/fail status
    static func calculatePassFail(points: [GridPoint], tolerance: Double, units: SessionUnits) -> [GridPoint] {
        let stats = calculateToleranceStats(points: points, tolerance: tolerance, units: units)
        
        return points.map { point in
            var updatedPoint = point
            if let value = point.finalValue {
                let deviation = abs(value - stats.average)
                updatedPoint.passFail = deviation <= tolerance
            }
            return updatedPoint
        }
    }
    
    /// Generate heatmap data for visualization
    /// - Parameters:
    ///   - points: Array of grid points
    ///   - tolerance: Tolerance value
    ///   - units: Units of the measurements
    /// - Returns: Heatmap data with colors for each point
    static func generateHeatmapData(points: [GridPoint], tolerance: Double, units: SessionUnits) -> [GridPointHeatmapData] {
        let stats = calculateToleranceStats(points: points, tolerance: tolerance, units: units)
        
        return points.map { point in
            let deviation = point.finalValue.map { abs($0 - stats.average) } ?? 0
            let normalizedDeviation = min(deviation / tolerance, 2.0) // Cap at 2x tolerance
            
            let color: HeatmapColor
            if deviation <= tolerance {
                color = .green
            } else if deviation <= tolerance * 1.5 {
                color = .yellow
            } else {
                color = .red
            }
            
            return GridPointHeatmapData(
                pointId: point.id,
                deviation: deviation,
                normalizedDeviation: normalizedDeviation,
                color: color,
                passFail: point.passFail ?? false
            )
        }
    }
    
    /// Validate tolerance value
    /// - Parameters:
    ///   - tolerance: Tolerance value
    ///   - units: Units of the tolerance
    /// - Returns: True if valid, false otherwise
    static func validateTolerance(_ tolerance: Double, units: SessionUnits) -> Bool {
        switch units {
        case .imperial:
            return tolerance > 0 && tolerance <= 12.0 // Max 12 inches
        case .metric:
            return tolerance > 0 && tolerance <= 300.0 // Max 300 mm
        }
    }
    
    /// Get default tolerance values for common scenarios
    /// - Parameter units: Units to get defaults for
    /// - Returns: Array of default tolerance values
    static func defaultTolerances(for units: SessionUnits) -> [Double] {
        switch units {
        case .imperial:
            return [0.125, 0.25, 0.5, 1.0, 2.0] // 1/8", 1/4", 1/2", 1", 2"
        case .metric:
            return [3.0, 5.0, 10.0, 25.0, 50.0] // 3mm, 5mm, 10mm, 25mm, 50mm
        }
    }
    
    /// Calculate measurement uncertainty
    /// - Parameters:
    ///   - points: Array of grid points
    ///   - units: Units of the measurements
    /// - Returns: Uncertainty value
    static func calculateUncertainty(points: [GridPoint], units: SessionUnits) -> Double {
        let values = points.compactMap { $0.finalValue }
        guard values.count >= 2 else {
            return 0
        }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        let standardDeviation = sqrt(variance)
        
        // Standard error of the mean
        return standardDeviation / sqrt(Double(values.count))
    }
    
    /// Check if a session meets quality criteria
    /// - Parameters:
    ///   - session: Session to check
    ///   - points: Grid points for the session
    /// - Returns: Quality assessment
    static func assessQuality(session: Session, points: [GridPoint]) -> QualityAssessment {
        let stats = calculateToleranceStats(points: points, tolerance: session.tolerance, units: session.units)
        let uncertainty = calculateUncertainty(points: points, units: session.units)
        
        let quality: QualityLevel
        if stats.passRate >= 0.95 && uncertainty < session.tolerance * 0.1 {
            quality = .excellent
        } else if stats.passRate >= 0.90 && uncertainty < session.tolerance * 0.2 {
            quality = .good
        } else if stats.passRate >= 0.80 {
            quality = .acceptable
        } else {
            quality = .poor
        }
        
        return QualityAssessment(
            quality: quality,
            passRate: stats.passRate,
            uncertainty: uncertainty,
            recommendations: generateRecommendations(stats: stats, quality: quality)
        )
    }
    
    /// Generate recommendations based on quality assessment
    /// - Parameters:
    ///   - stats: Tolerance statistics
    ///   - quality: Quality level
    /// - Returns: Array of recommendations
    private static func generateRecommendations(stats: ToleranceStats, quality: QualityLevel) -> [String] {
        var recommendations: [String] = []
        
        switch quality {
        case .excellent:
            recommendations.append("Excellent measurement quality")
        case .good:
            recommendations.append("Good measurement quality")
        case .acceptable:
            recommendations.append("Consider re-measuring points with high deviations")
            if stats.exceedanceCount > 0 {
                recommendations.append("Review \(stats.exceedanceCount) points that exceed tolerance")
            }
        case .poor:
            recommendations.append("Significant quality issues detected")
            recommendations.append("Re-measure all points with high deviations")
            recommendations.append("Check measurement equipment and technique")
        }
        
        if stats.maxPairwiseDelta > stats.average * 0.1 {
            recommendations.append("High variation between measurements - check for systematic errors")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct GridPointHeatmapData {
    let pointId: UUID
    let deviation: Double
    let normalizedDeviation: Double
    let color: HeatmapColor
    let passFail: Bool
}

enum HeatmapColor {
    case green
    case yellow
    case red
    
    var uiColor: String {
        switch self {
        case .green: return "green"
        case .yellow: return "yellow"
        case .red: return "red"
        }
    }
}

enum QualityLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case acceptable = "Acceptable"
    case poor = "Poor"
    
    var description: String {
        switch self {
        case .excellent:
            return "All measurements within tolerance with low uncertainty"
        case .good:
            return "Most measurements within tolerance with acceptable uncertainty"
        case .acceptable:
            return "Some measurements exceed tolerance but overall quality is acceptable"
        case .poor:
            return "Significant quality issues detected"
        }
    }
}

struct QualityAssessment {
    let quality: QualityLevel
    let passRate: Double
    let uncertainty: Double
    let recommendations: [String]
}
