import Foundation
import simd

// MARK: - Core Models

struct Project: Codable, Identifiable {
    let id: UUID
    var name: String
    var clientName: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, clientName: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.createdAt = createdAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "clientName": clientName,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
    }
}

struct Location: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    var name: String
    var address: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), projectId: UUID, name: String, address: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.projectId = projectId
        self.name = name
        self.address = address
        self.createdAt = createdAt
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "projectId": projectId.uuidString,
            "name": name,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        if let address = address {
            dict["address"] = address
        }
        return dict
    }
}

enum SessionUnits: String, Codable, CaseIterable {
    case imperial = "imperial"
    case metric = "metric"
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial (inches)"
        case .metric: return "Metric (mm)"
        }
    }
    
    var unitLabel: String {
        switch self {
        case .imperial: return "in"
        case .metric: return "mm"
        }
    }
}

enum FractionalResolution: String, Codable, CaseIterable {
    case eighth = "1/8"
    case sixteenth = "1/16"
    
    var displayName: String {
        return rawValue
    }
    
    var decimalValue: Double {
        switch self {
        case .eighth: return 1.0 / 8.0
        case .sixteenth: return 1.0 / 16.0
        }
    }
}

struct Session: Codable, Identifiable {
    let id: UUID
    let locationId: UUID
    var startedAt: Date
    var completedAt: Date?
    var units: SessionUnits
    var tolerance: Double
    var rectWorldTransform: simd_float4x4
    var rectWidth: Float
    var rectLength: Float
    var rows: Int
    var cols: Int
    var deviceInfo: DeviceInfo
    var lidarAvailable: Bool
    
    init(id: UUID = UUID(), locationId: UUID, units: SessionUnits, tolerance: Double, rows: Int, cols: Int) {
        self.id = id
        self.locationId = locationId
        self.startedAt = Date()
        self.units = units
        self.tolerance = tolerance
        self.rectWorldTransform = matrix_identity_float4x4
        self.rectWidth = 0
        self.rectLength = 0
        self.rows = rows
        self.cols = cols
        self.deviceInfo = DeviceInfo.current()
        self.lidarAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "locationId": locationId.uuidString,
            "startedAt": ISO8601DateFormatter().string(from: startedAt),
            "units": units.rawValue,
            "tolerance": tolerance,
            "rectWidth": rectWidth,
            "rectLength": rectLength,
            "rows": rows,
            "cols": cols,
            "deviceInfo": deviceInfo.toDictionary(),
            "lidarAvailable": lidarAvailable
        ]
        if let completedAt = completedAt {
            dict["completedAt"] = ISO8601DateFormatter().string(from: completedAt)
        }
        return dict
    }
}

struct GridPoint: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    var rowLetter: String
    var colIndex: Int
    var worldPosition: simd_float3
    var aiMeasuredValue: Double?
    var aiMeasuredDisplay: String?
    var aiConfidence: Double?
    var aiMethod: String?
    var measuredUserValue: Double?
    var measuredUserDisplay: String?
    var isUserOverridden: Bool
    var lidarHeight: Double?
    var deviationFromAvg: Double?
    var passFail: Bool?
    var photoIds: [String]
    
    init(id: UUID = UUID(), sessionId: UUID, rowLetter: String, colIndex: Int, worldPosition: simd_float3) {
        self.id = id
        self.sessionId = sessionId
        self.rowLetter = rowLetter
        self.colIndex = colIndex
        self.worldPosition = worldPosition
        self.isUserOverridden = false
        self.photoIds = []
    }
    
    var label: String {
        return "\(rowLetter)\(colIndex)"
    }
    
    var finalValue: Double? {
        return measuredUserValue ?? aiMeasuredValue
    }
    
    var finalDisplay: String? {
        return measuredUserDisplay ?? aiMeasuredDisplay
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "sessionId": sessionId.uuidString,
            "rowLetter": rowLetter,
            "colIndex": colIndex,
            "worldPosition": [worldPosition.x, worldPosition.y, worldPosition.z],
            "isUserOverridden": isUserOverridden,
            "photoIds": photoIds
        ]
        
        if let aiMeasuredValue = aiMeasuredValue {
            dict["aiMeasuredValue"] = aiMeasuredValue
        }
        if let aiMeasuredDisplay = aiMeasuredDisplay {
            dict["aiMeasuredDisplay"] = aiMeasuredDisplay
        }
        if let aiConfidence = aiConfidence {
            dict["aiConfidence"] = aiConfidence
        }
        if let aiMethod = aiMethod {
            dict["aiMethod"] = aiMethod
        }
        if let measuredUserValue = measuredUserValue {
            dict["measuredUserValue"] = measuredUserValue
        }
        if let measuredUserDisplay = measuredUserDisplay {
            dict["measuredUserDisplay"] = measuredUserDisplay
        }
        if let lidarHeight = lidarHeight {
            dict["lidarHeight"] = lidarHeight
        }
        if let deviationFromAvg = deviationFromAvg {
            dict["deviationFromAvg"] = deviationFromAvg
        }
        if let passFail = passFail {
            dict["passFail"] = passFail
        }
        
        return dict
    }
}

struct PhotoAsset: Codable, Identifiable {
    let id: String
    let sessionId: UUID
    let gridPointId: UUID
    var fileURL: URL
    var createdAt: Date
    var arCameraIntrinsics: simd_float3x3?
    var arCameraTransform: simd_float4x4?
    
    init(id: String = UUID().uuidString, sessionId: UUID, gridPointId: UUID, fileURL: URL, arCameraIntrinsics: simd_float3x3? = nil, arCameraTransform: simd_float4x4? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.gridPointId = gridPointId
        self.fileURL = fileURL
        self.createdAt = Date()
        self.arCameraIntrinsics = arCameraIntrinsics
        self.arCameraTransform = arCameraTransform
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "sessionId": sessionId.uuidString,
            "gridPointId": gridPointId.uuidString,
            "fileURL": fileURL.absoluteString,
            "createdAt": ISO8601DateFormatter().string(from: createdAt)
        ]
        
        if let arCameraIntrinsics = arCameraIntrinsics {
            dict["arCameraIntrinsics"] = [
                [arCameraIntrinsics[0][0], arCameraIntrinsics[0][1], arCameraIntrinsics[0][2]],
                [arCameraIntrinsics[1][0], arCameraIntrinsics[1][1], arCameraIntrinsics[1][2]],
                [arCameraIntrinsics[2][0], arCameraIntrinsics[2][1], arCameraIntrinsics[2][2]]
            ]
        }
        
        return dict
    }
}

enum PlanType: String, Codable {
    case individual = "individual"
    case org = "org"
}

struct Entitlement: Codable {
    var userId: String
    var planType: PlanType
    var seatsAllocated: Int
    var seatsUsed: Int
    var orgCode: String?
    var expiresAt: Date?
    
    var hasValidEntitlement: Bool {
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
    
    var availableSeats: Int {
        return max(0, seatsAllocated - seatsUsed)
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "planType": planType.rawValue,
            "seatsAllocated": seatsAllocated,
            "seatsUsed": seatsUsed
        ]
        
        if let orgCode = orgCode {
            dict["orgCode"] = orgCode
        }
        if let expiresAt = expiresAt {
            dict["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt)
        }
        
        return dict
    }
}

struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let appVersion: String
    let buildNumber: String
    
    static func current() -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "model": model,
            "systemVersion": systemVersion,
            "appVersion": appVersion,
            "buildNumber": buildNumber
        ]
    }
}

// MARK: - AI Measurement Models

struct MeasurementAIResult {
    let aiMeasuredValue: Double
    let aiMeasuredDisplay: String
    let aiConfidence: Double
    let aiMethod: String
    let needsCalibrationTap: Bool
}

struct Calibration {
    let axis: Axis
    let pixelPerUnit: Double
    let zeroPixelY: CGFloat
}

enum Axis {
    case vertical
    case horizontal
}

// MARK: - Tolerance Engine Models

struct ToleranceStats {
    let average: Double
    let min: Double
    let max: Double
    let range: Double
    let maxPairwiseDelta: Double
    let exceedanceCount: Int
    let totalPoints: Int
    let passRate: Double
    
    init(points: [GridPoint], tolerance: Double) {
        let values = points.compactMap { $0.finalValue }
        
        if values.isEmpty {
            self.average = 0
            self.min = 0
            self.max = 0
            self.range = 0
            self.maxPairwiseDelta = 0
            self.exceedanceCount = 0
            self.totalPoints = 0
            self.passRate = 0
            return
        }
        
        self.average = values.reduce(0, +) / Double(values.count)
        self.min = values.min() ?? 0
        self.max = values.max() ?? 0
        self.range = max - min
        
        // Calculate max pairwise delta
        var maxDelta = 0.0
        for i in 0..<values.count {
            for j in (i+1)..<values.count {
                let delta = abs(values[i] - values[j])
                maxDelta = max(maxDelta, delta)
            }
        }
        self.maxPairwiseDelta = maxDelta
        
        // Calculate exceedances
        let deviations = values.map { abs($0 - average) }
        self.exceedanceCount = deviations.filter { $0 > tolerance }.count
        self.totalPoints = values.count
        self.passRate = Double(totalPoints - exceedanceCount) / Double(totalPoints)
    }
}
