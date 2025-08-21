import XCTest
@testable import LevelMap

final class LevelMapTests: XCTestCase {
    
    func testFractionParsing() throws {
        // Test basic fraction parsing
        XCTAssertEqual(FractionUtils.parseFractionalInches("1 3/8"), 1.375)
        XCTAssertEqual(FractionUtils.parseFractionalInches("3/4"), 0.75)
        XCTAssertEqual(FractionUtils.parseFractionalInches("2.5"), 2.5)
        XCTAssertEqual(FractionUtils.parseFractionalInches("0"), 0.0)
        
        // Test invalid fractions
        XCTAssertNil(FractionUtils.parseFractionalInches("invalid"))
        XCTAssertNil(FractionUtils.parseFractionalInches("1/0"))
    }
    
    func testFractionFormatting() throws {
        // Test imperial formatting
        XCTAssertEqual(FractionUtils.formatFractionalInches(1.375, resolution: .eighth), "1 3/8")
        XCTAssertEqual(FractionUtils.formatFractionalInches(0.75, resolution: .eighth), "3/4")
        XCTAssertEqual(FractionUtils.formatFractionalInches(2.0, resolution: .eighth), "2")
        XCTAssertEqual(FractionUtils.formatFractionalInches(0.0625, resolution: .sixteenth), "1/16")
    }
    
    func testUnitConversion() throws {
        // Test inches to mm conversion
        XCTAssertEqual(FractionUtils.inchesToMM(1.0), 25.4, accuracy: 0.001)
        XCTAssertEqual(FractionUtils.inchesToMM(2.5), 63.5, accuracy: 0.001)
        
        // Test mm to inches conversion
        XCTAssertEqual(FractionUtils.mmToInches(25.4), 1.0, accuracy: 0.001)
        XCTAssertEqual(FractionUtils.mmToInches(63.5), 2.5, accuracy: 0.001)
    }
    
    func testGridValidation() throws {
        // Test valid grid dimensions
        XCTAssertTrue(GeometryUtils.validateGridDimensions(rows: 2, cols: 2))
        XCTAssertTrue(GeometryUtils.validateGridDimensions(rows: 10, cols: 10))
        XCTAssertTrue(GeometryUtils.validateGridDimensions(rows: 26, cols: 50))
        
        // Test invalid grid dimensions
        XCTAssertFalse(GeometryUtils.validateGridDimensions(rows: 1, cols: 2))
        XCTAssertFalse(GeometryUtils.validateGridDimensions(rows: 2, cols: 1))
        XCTAssertFalse(GeometryUtils.validateGridDimensions(rows: 27, cols: 10))
        XCTAssertFalse(GeometryUtils.validateGridDimensions(rows: 10, cols: 51))
    }
    
    func testToleranceValidation() throws {
        // Test valid tolerances
        XCTAssertTrue(ToleranceEngine.validateTolerance(0.125, units: .imperial))
        XCTAssertTrue(ToleranceEngine.validateTolerance(10.0, units: .metric))
        XCTAssertTrue(ToleranceEngine.validateTolerance(1.0, units: .imperial))
        
        // Test invalid tolerances
        XCTAssertFalse(ToleranceEngine.validateTolerance(0, units: .imperial))
        XCTAssertFalse(ToleranceEngine.validateTolerance(-1, units: .imperial))
        XCTAssertFalse(ToleranceEngine.validateTolerance(13.0, units: .imperial)) // > 12 inches
        XCTAssertFalse(ToleranceEngine.validateTolerance(301.0, units: .metric)) // > 300 mm
    }
    
    func testToleranceStats() throws {
        // Create test grid points
        let points = [
            GridPoint(sessionId: UUID(), rowLetter: "A", colIndex: 1, worldPosition: simd_float3(0, 0, 0)),
            GridPoint(sessionId: UUID(), rowLetter: "A", colIndex: 2, worldPosition: simd_float3(0, 0, 0)),
            GridPoint(sessionId: UUID(), rowLetter: "B", colIndex: 1, worldPosition: simd_float3(0, 0, 0))
        ]
        
        // Set measurement values
        var testPoints = points
        testPoints[0].measuredUserValue = 1.0
        testPoints[1].measuredUserValue = 1.1
        testPoints[2].measuredUserValue = 0.9
        
        let stats = ToleranceStats(points: testPoints, tolerance: 0.2)
        
        // Test statistics
        XCTAssertEqual(stats.average, 1.0, accuracy: 0.001)
        XCTAssertEqual(stats.min, 0.9, accuracy: 0.001)
        XCTAssertEqual(stats.max, 1.1, accuracy: 0.001)
        XCTAssertEqual(stats.range, 0.2, accuracy: 0.001)
        XCTAssertEqual(stats.totalPoints, 3)
        XCTAssertEqual(stats.exceedanceCount, 0) // All within 0.2 tolerance
    }
    
    func testProjectCreation() throws {
        let project = Project(name: "Test Project", clientName: "Test Client")
        
        XCTAssertEqual(project.name, "Test Project")
        XCTAssertEqual(project.clientName, "Test Client")
        XCTAssertNotNil(project.id)
        XCTAssertNotNil(project.createdAt)
    }
    
    func testSessionCreation() throws {
        let locationId = UUID()
        let session = Session(
            locationId: locationId,
            units: .imperial,
            tolerance: 0.125,
            rows: 4,
            cols: 4
        )
        
        XCTAssertEqual(session.locationId, locationId)
        XCTAssertEqual(session.units, .imperial)
        XCTAssertEqual(session.tolerance, 0.125)
        XCTAssertEqual(session.rows, 4)
        XCTAssertEqual(session.cols, 4)
        XCTAssertTrue(session.lidarAvailable) // Will be true on LiDAR devices
    }
    
    func testGridPointLabeling() throws {
        let point = GridPoint(sessionId: UUID(), rowLetter: "A", colIndex: 1, worldPosition: simd_float3(0, 0, 0))
        
        XCTAssertEqual(point.label, "A1")
        XCTAssertEqual(point.rowLetter, "A")
        XCTAssertEqual(point.colIndex, 1)
    }
    
    func testMeasurementFormatting() throws {
        let imperialValue = 1.375
        let metricValue = 35.0
        
        let imperialFormatted = FractionUtils.formatMeasurement(imperialValue, units: .imperial, resolution: .eighth)
        let metricFormatted = FractionUtils.formatMeasurement(metricValue, units: .metric)
        
        XCTAssertEqual(imperialFormatted, "1 3/8 in")
        XCTAssertEqual(metricFormatted, "35.0 mm")
    }
    
    func testDefaultTolerances() throws {
        let imperialTolerances = ToleranceEngine.defaultTolerances(for: .imperial)
        let metricTolerances = ToleranceEngine.defaultTolerances(for: .metric)
        
        XCTAssertEqual(imperialTolerances.count, 5)
        XCTAssertEqual(metricTolerances.count, 5)
        
        // Check specific values
        XCTAssertEqual(imperialTolerances[0], 0.125) // 1/8"
        XCTAssertEqual(metricTolerances[0], 3.0) // 3mm
    }
    
    func testGridPresets() throws {
        let presets = GeometryUtils.gridPresets()
        
        XCTAssertEqual(presets.count, 5)
        XCTAssertEqual(presets[0].name, "Halves (2)")
        XCTAssertEqual(presets[0].rows, 2)
        XCTAssertEqual(presets[0].cols, 1)
        
        XCTAssertEqual(presets[1].name, "Fourths (2×2)")
        XCTAssertEqual(presets[1].rows, 2)
        XCTAssertEqual(presets[1].cols, 2)
    }
}
