import Foundation
import Combine
import UIKit

protocol DataStoreProtocol {
    var projects: [Project] { get }
    var locations: [Location] { get }
    var sessions: [Session] { get }
    var gridPoints: [GridPoint] { get }
    var photoAssets: [PhotoAsset] { get }
    
    func saveProject(_ project: Project) async throws
    func loadProject(_ id: UUID) async throws -> Project?
    func deleteProject(_ id: UUID) async throws
    
    func saveLocation(_ location: Location) async throws
    func loadLocation(_ id: UUID) async throws -> Location?
    func deleteLocation(_ id: UUID) async throws
    
    func saveSession(_ session: Session) async throws
    func loadSession(_ id: UUID) async throws -> Session?
    func deleteSession(_ id: UUID) async throws
    
    func saveGridPoint(_ gridPoint: GridPoint) async throws
    func loadGridPoint(_ id: UUID) async throws -> GridPoint?
    func deleteGridPoint(_ id: UUID) async throws
    
    func savePhotoAsset(_ photoAsset: PhotoAsset) async throws
    func loadPhotoAsset(_ id: UUID) async throws -> PhotoAsset?
    func deletePhotoAsset(_ id: UUID) async throws
    
    func savePhoto(_ image: UIImage, for sessionId: UUID, gridPointId: UUID) async throws -> PhotoAsset
    func exportSessionData(_ session: Session) async throws -> SessionExportData
    func exportAllData() async throws -> AppExportData
}

class DataStore: ObservableObject, DataStoreProtocol {
    @Published var projects: [Project] = []
    @Published var locations: [Location] = []
    @Published var sessions: [Session] = []
    @Published var gridPoints: [GridPoint] = []
    @Published var photoAssets: [PhotoAsset] = []
    
    private let documentsPath: URL
    private let projectsPath: URL
    private let locationsPath: URL
    private let sessionsPath: URL
    private let gridPointsPath: URL
    private let photoAssetsPath: URL
    private let photosDirectory: URL
    
    init() {
        documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        projectsPath = documentsPath.appendingPathComponent("projects.json")
        locationsPath = documentsPath.appendingPathComponent("locations.json")
        sessionsPath = documentsPath.appendingPathComponent("sessions.json")
        gridPointsPath = documentsPath.appendingPathComponent("gridPoints.json")
        photoAssetsPath = documentsPath.appendingPathComponent("photoAssets.json")
        photosDirectory = documentsPath.appendingPathComponent("photos")
        
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Initialization
    func loadData() async throws {
        await MainActor.run {
            do {
                projects = try loadFromFile(projectsPath, type: [Project].self)
                locations = try loadFromFile(locationsPath, type: [Location].self)
                sessions = try loadFromFile(sessionsPath, type: [Session].self)
                gridPoints = try loadFromFile(gridPointsPath, type: [GridPoint].self)
                photoAssets = try loadFromFile(photoAssetsPath, type: [PhotoAsset].self)
            } catch {
                print("Error loading data: \(error)")
                // Initialize with empty arrays if loading fails
                projects = []
                locations = []
                sessions = []
                gridPoints = []
                photoAssets = []
            }
        }
    }
    
    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }
    
    private func loadFromFile<T: Codable>(_ path: URL, type: T.Type) throws -> T {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return try JSONDecoder().decode(T.self, from: Data())
        }
        
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func saveToFile<T: Codable>(_ data: T, to path: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: path)
    }
    
    // MARK: - Project Methods
    func saveProject(_ project: Project) async throws {
        await MainActor.run {
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            } else {
                projects.append(project)
            }
        }
        try saveToFile(projects, to: projectsPath)
    }
    
    func loadProject(_ id: UUID) async throws -> Project? {
        return projects.first { $0.id == id }
    }
    
    func deleteProject(_ id: UUID) async throws {
        await MainActor.run {
            projects.removeAll { $0.id == id }
        }
        try saveToFile(projects, to: projectsPath)
    }
    
    // MARK: - Location Methods
    func saveLocation(_ location: Location) async throws {
        await MainActor.run {
            if let index = locations.firstIndex(where: { $0.id == location.id }) {
                locations[index] = location
            } else {
                locations.append(location)
            }
        }
        try saveToFile(locations, to: locationsPath)
    }
    
    func loadLocation(_ id: UUID) async throws -> Location? {
        return locations.first { $0.id == id }
    }
    
    func deleteLocation(_ id: UUID) async throws {
        await MainActor.run {
            locations.removeAll { $0.id == id }
        }
        try saveToFile(locations, to: locationsPath)
    }
    
    // MARK: - Session Methods
    func saveSession(_ session: Session) async throws {
        await MainActor.run {
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = session
            } else {
                sessions.append(session)
            }
        }
        try saveToFile(sessions, to: sessionsPath)
    }
    
    func loadSession(_ id: UUID) async throws -> Session? {
        return sessions.first { $0.id == id }
    }
    
    func deleteSession(_ id: UUID) async throws {
        await MainActor.run {
            sessions.removeAll { $0.id == id }
        }
        try saveToFile(sessions, to: sessionsPath)
    }
    
    // MARK: - GridPoint Methods
    func saveGridPoint(_ gridPoint: GridPoint) async throws {
        await MainActor.run {
            if let index = gridPoints.firstIndex(where: { $0.id == gridPoint.id }) {
                gridPoints[index] = gridPoint
            } else {
                gridPoints.append(gridPoint)
            }
        }
        try saveToFile(gridPoints, to: gridPointsPath)
    }
    
    func loadGridPoint(_ id: UUID) async throws -> GridPoint? {
        return gridPoints.first { $0.id == id }
    }
    
    func deleteGridPoint(_ id: UUID) async throws {
        await MainActor.run {
            gridPoints.removeAll { $0.id == id }
        }
        try saveToFile(gridPoints, to: gridPointsPath)
    }
    
    // MARK: - PhotoAsset Methods
    func savePhotoAsset(_ photoAsset: PhotoAsset) async throws {
        await MainActor.run {
            if let index = photoAssets.firstIndex(where: { $0.id == photoAsset.id }) {
                photoAssets[index] = photoAsset
            } else {
                photoAssets.append(photoAsset)
            }
        }
        try saveToFile(photoAssets, to: photoAssetsPath)
    }
    
    func loadPhotoAsset(_ id: UUID) async throws -> PhotoAsset? {
        return photoAssets.first { $0.id == id }
    }
    
    func deletePhotoAsset(_ id: UUID) async throws {
        await MainActor.run {
            photoAssets.removeAll { $0.id == id }
        }
        try saveToFile(photoAssets, to: photoAssetsPath)
    }
    
    // MARK: - Photo Methods
    func savePhoto(_ image: UIImage, for sessionId: UUID, gridPointId: UUID) async throws -> PhotoAsset {
        let photoId = UUID()
        let filename = "\(photoId.uuidString).jpg"
        let photoURL = photosDirectory.appendingPathComponent(filename)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw DataStoreError.imageCompressionFailed
        }
        
        try imageData.write(to: photoURL)
        
        let photoAsset = PhotoAsset(
            id: photoId,
            sessionId: sessionId,
            gridPointId: gridPointId,
            filename: filename,
            capturedAt: Date(),
            aiResult: nil,
            manualValue: nil,
            notes: nil
        )
        
        try await savePhotoAsset(photoAsset)
        return photoAsset
    }
    
    // MARK: - Export Methods
    func exportSessionData(_ session: Session) async throws -> SessionExportData {
        let sessionGridPoints = gridPoints.filter { $0.sessionId == session.id }
        let sessionPhotos = photoAssets.filter { $0.sessionId == session.id }
        
        return SessionExportData(
            session: session,
            gridPoints: sessionGridPoints,
            photoAssets: sessionPhotos
        )
    }
    
    func exportAllData() async throws -> AppExportData {
        return AppExportData(
            projects: projects,
            locations: locations,
            sessions: sessions,
            gridPoints: gridPoints,
            photoAssets: photoAssets,
            exportedAt: Date()
        )
    }
}

// MARK: - Supporting Types
struct SessionExportData: Codable {
    let session: Session
    let gridPoints: [GridPoint]
    let photoAssets: [PhotoAsset]
}

struct AppExportData: Codable {
    let projects: [Project]
    let locations: [Location]
    let sessions: [Session]
    let gridPoints: [GridPoint]
    let photoAssets: [PhotoAsset]
    let exportedAt: Date
}

enum DataStoreError: Error, LocalizedError {
    case imageCompressionFailed
    case fileNotFound
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .fileNotFound:
            return "File not found"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        }
    }
}
