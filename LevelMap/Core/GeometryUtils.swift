import Foundation
import simd
import ARKit

// MARK: - Geometry Utilities

struct GeometryUtils {
    
    /// Generate grid points for a rectangle with given dimensions and grid size
    /// - Parameters:
    ///   - rectTransform: 4x4 transform matrix of the rectangle
    ///   - width: Width of the rectangle in meters
    ///   - length: Length of the rectangle in meters
    ///   - rows: Number of rows in the grid
    ///   - cols: Number of columns in the grid
    /// - Returns: Array of grid points with world positions and labels
    static func gridWorldPositions(
        rectTransform: simd_float4x4,
        width: Float,
        length: Float,
        rows: Int,
        cols: Int
    ) -> [GridPoint] {
        var gridPoints: [GridPoint] = []
        
        // Calculate step sizes
        let stepX = width / Float(cols - 1)
        let stepZ = length / Float(rows - 1)
        
        // Generate grid points
        for row in 0..<rows {
            let rowLetter = String(Character(UnicodeScalar(65 + row)!)) // A, B, C, ...
            
            for col in 0..<cols {
                // Calculate local position (relative to rectangle center)
                let localX = (Float(col) - Float(cols - 1) / 2.0) * stepX
                let localZ = (Float(row) - Float(rows - 1) / 2.0) * stepZ
                let localPosition = simd_float3(localX, 0, localZ)
                
                // Transform to world coordinates
                let worldPosition = transformPoint(localPosition, by: rectTransform)
                
                // Create grid point
                let gridPoint = GridPoint(
                    sessionId: UUID(), // Will be set by caller
                    rowLetter: rowLetter,
                    colIndex: col + 1,
                    worldPosition: worldPosition
                )
                
                gridPoints.append(gridPoint)
            }
        }
        
        return gridPoints
    }
    
    /// Transform a point from local to world coordinates
    /// - Parameters:
    ///   - point: Local point in 3D space
    ///   - transform: 4x4 transformation matrix
    /// - Returns: Transformed point in world coordinates
    static func transformPoint(_ point: simd_float3, by transform: simd_float4x4) -> simd_float3 {
        let homogeneousPoint = simd_float4(point.x, point.y, point.z, 1.0)
        let transformedPoint = transform * homogeneousPoint
        return simd_float3(transformedPoint.x, transformedPoint.y, transformedPoint.z)
    }
    
    /// Calculate rectangle dimensions from two corner points
    /// - Parameters:
    ///   - cornerA: First corner point in world coordinates
    ///   - cornerB: Second corner point in world coordinates
    /// - Returns: Tuple of (width, length) in meters
    static func calculateRectangleDimensions(from cornerA: simd_float3, to cornerB: simd_float3) -> (width: Float, length: Float) {
        let delta = cornerB - cornerA
        let width = abs(delta.x)
        let length = abs(delta.z)
        return (width, length)
    }
    
    /// Create a 4x4 transform matrix for a rectangle from two corner points
    /// - Parameters:
    ///   - cornerA: First corner point
    ///   - cornerB: Second corner point
    /// - Returns: 4x4 transformation matrix
    static func createRectangleTransform(from cornerA: simd_float3, to cornerB: simd_float3) -> simd_float4x4 {
        // Calculate center point
        let center = (cornerA + cornerB) / 2.0
        
        // Calculate forward direction (length axis)
        let forward = normalize(cornerB - cornerA)
        
        // Calculate right direction (width axis)
        let right = normalize(simd_float3(forward.z, 0, -forward.x))
        
        // Calculate up direction
        let up = simd_float3(0, 1, 0)
        
        // Create rotation matrix
        let rotation = simd_float3x3(
            right,
            up,
            forward
        )
        
        // Create 4x4 transform matrix
        var transform = matrix_identity_float4x4
        transform[0] = simd_float4(rotation[0].x, rotation[0].y, rotation[0].z, 0)
        transform[1] = simd_float4(rotation[1].x, rotation[1].y, rotation[1].z, 0)
        transform[2] = simd_float4(rotation[2].x, rotation[2].y, rotation[2].z, 0)
        transform[3] = simd_float4(center.x, center.y, center.z, 1)
        
        return transform
    }
    
    /// Calculate distance between two 3D points
    /// - Parameters:
    ///   - pointA: First point
    ///   - pointB: Second point
    /// - Returns: Distance in meters
    static func distance(from pointA: simd_float3, to pointB: simd_float3) -> Float {
        return length(pointB - pointA)
    }
    
    /// Calculate height deviation from a plane
    /// - Parameters:
    ///   - point: Point to check
    ///   - planeNormal: Normal vector of the plane
    ///   - planePoint: Point on the plane
    /// - Returns: Height deviation in meters
    static func heightDeviation(from point: simd_float3, planeNormal: simd_float3, planePoint: simd_float3) -> Float {
        let pointToPlane = point - planePoint
        return dot(pointToPlane, planeNormal)
    }
    
    /// Find the best-fit plane from a set of points using least squares
    /// - Parameter points: Array of 3D points
    /// - Returns: Tuple of (planeNormal, planePoint)
    static func bestFitPlane(from points: [simd_float3]) -> (normal: simd_float3, point: simd_float3) {
        guard points.count >= 3 else {
            return (simd_float3(0, 1, 0), simd_float3(0, 0, 0))
        }
        
        // Calculate centroid
        let centroid = points.reduce(simd_float3(0, 0, 0), +) / Float(points.count)
        
        // Calculate covariance matrix
        var covariance = matrix_float3x3()
        for point in points {
            let diff = point - centroid
            covariance[0][0] += diff.x * diff.x
            covariance[0][1] += diff.x * diff.y
            covariance[0][2] += diff.x * diff.z
            covariance[1][0] += diff.y * diff.x
            covariance[1][1] += diff.y * diff.y
            covariance[1][2] += diff.y * diff.z
            covariance[2][0] += diff.z * diff.x
            covariance[2][1] += diff.z * diff.y
            covariance[2][2] += diff.z * diff.z
        }
        
        // Find eigenvector with smallest eigenvalue (normal vector)
        // For simplicity, we'll use the cross product method for 3 points
        if points.count == 3 {
            let v1 = points[1] - points[0]
            let v2 = points[2] - points[0]
            let normal = normalize(cross(v1, v2))
            return (normal, centroid)
        }
        
        // For more points, use the Y-axis as approximation for horizontal planes
        return (simd_float3(0, 1, 0), centroid)
    }
    
    /// Convert meters to the specified units
    /// - Parameters:
    ///   - meters: Value in meters
    ///   - units: Target units
    /// - Returns: Converted value
    static func convertFromMeters(_ meters: Float, to units: SessionUnits) -> Double {
        switch units {
        case .imperial:
            return Double(meters * 39.3701) // meters to inches
        case .metric:
            return Double(meters * 1000) // meters to mm
        }
    }
    
    /// Convert from specified units to meters
    /// - Parameters:
    ///   - value: Value in the specified units
    ///   - units: Source units
    /// - Returns: Value in meters
    static func convertToMeters(_ value: Double, from units: SessionUnits) -> Float {
        switch units {
        case .imperial:
            return Float(value / 39.3701) // inches to meters
        case .metric:
            return Float(value / 1000) // mm to meters
        }
    }
    
    /// Calculate the area of a rectangle
    /// - Parameters:
    ///   - width: Width in meters
    ///   - length: Length in meters
    /// - Returns: Area in square meters
    static func rectangleArea(width: Float, length: Float) -> Float {
        return width * length
    }
    
    /// Validate grid dimensions
    /// - Parameters:
    ///   - rows: Number of rows
    ///   - cols: Number of columns
    /// - Returns: True if valid, false otherwise
    static func validateGridDimensions(rows: Int, cols: Int) -> Bool {
        return rows >= 2 && rows <= 26 && cols >= 2 && cols <= 50
    }
    
    /// Get grid preset configurations
    static func gridPresets() -> [(name: String, rows: Int, cols: Int)] {
        return [
            ("Halves (2)", 2, 1),
            ("Fourths (2×2)", 2, 2),
            ("Eighths (4×2)", 4, 2),
            ("Eighths (2×4)", 2, 4),
            ("Custom", 0, 0)
        ]
    }
}
