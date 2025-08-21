import Foundation
import Combine

// MARK: - Data Store Protocol

protocol DataStoreProtocol {
    func saveProject(_ project: Project) async throws
    func loadProjects() async throws -> [Project]
    func deleteProject(_ project: Project) async throws
    
    func saveLocation(_ location: Location) async throws
    func loadLocations(for projectId: UUID) async throws -> [Location]
    func deleteLocation(_ location: Location) async throws
    
    func saveSession(_ session: Session) async throws
    func loadSessions(for locationId: UUID) async throws -> [Session]
    func deleteSession(_ session: Session) async throws
    
    func saveGridPoints(_ points: [GridPoint], for sessionId: UUID) async throws
    func loadGridPoints(for sessionId: UUID) async throws -> [GridPoint]
    
    func savePhotoAsset(_ photo: PhotoAsset) async throws
    func loadPhotoAssets(for sessionId: UUID) async throws -> [PhotoAsset]
    func deletePhotoAsset(_ photo: PhotoAsset) async throws
}

// MARK: - Local Data Store Implementation

class DataStore: ObservableObject, DataStoreProtocol {
    @Published var projects: [Project] = []
    @Published var locations: [Location] = []
    @Published var sessions: [Session] = []
    @Published var gridPoints: [UUID: [GridPoint]] = [:]
    @Published var photoAssets: [UUID: [PhotoAsset]] = [:]
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let projectsFile: URL
    private let locationsFile: URL
    private let sessionsFile: URL
    private let gridPointsDirectory: URL
    private let photosDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        projectsFile = documentsDirectory.appendingPathComponent("projects.json")
        locationsFile = documentsDirectory.appendingPathComponent("locations.json")
        sessionsFile = documentsDirectory.appendingPathComponent("sessions.json")
        gridPointsDirectory = documentsDirectory.appendingPathComponent("gridPoints")
        photosDirectory = documentsDirectory.appendingPathComponent("photos")
        
        createDirectoriesIfNeeded()
        loadData()
    }
    
    // MARK: - Project Management
    
    func saveProject(_ project: Project) async throws {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
        
        try await saveProjectsToFile()
    }
    
    func loadProjects() async throws -> [Project] {
        return projects
    }
    
    func deleteProject(_ project: Project) async throws {
        projects.removeAll { $0.id == project.id }
        
        // Delete associated locations
        let projectLocations = locations.filter { $0.projectId == project.id }
        for location in projectLocations {
            try await deleteLocation(location)
        }
        
        try await saveProjectsToFile()
    }
    
    // MARK: - Location Management
    
    func saveLocation(_ location: Location) async throws {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        } else {
            locations.append(location)
        }
        
        try await saveLocationsToFile()
    }
    
    func loadLocations(for projectId: UUID) async throws -> [Location] {
        return locations.filter { $0.projectId == projectId }
    }
    
    func deleteLocation(_ location: Location) async throws {
        locations.removeAll { $0.id == location.id }
        
        // Delete associated sessions
        let locationSessions = sessions.filter { $0.locationId == location.id }
        for session in locationSessions {
            try await deleteSession(session)
        }
        
        try await saveLocationsToFile()
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: Session) async throws {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        
        try await saveSessionsToFile()
    }
    
    func loadSessions(for locationId: UUID) async throws -> [Session] {
        return sessions.filter { $0.locationId == locationId }
    }
    
    func deleteSession(_ session: Session) async throws {
        sessions.removeAll { $0.id == session.id }
        
        // Delete associated grid points and photos
        gridPoints.removeValue(forKey: session.id)
        photoAssets.removeValue(forKey: session.id)
        
        // Delete grid points file
        let gridPointsFile = gridPointsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        try? fileManager.removeItem(at: gridPointsFile)
        
        // Delete photos directory
        let sessionPhotosDirectory = photosDirectory.appendingPathComponent(session.id.uuidString)
        try? fileManager.removeItem(at: sessionPhotosDirectory)
        
        try await saveSessionsToFile()
    }
    
    // MARK: - Grid Points Management
    
    func saveGridPoints(_ points: [GridPoint], for sessionId: UUID) async throws {
        gridPoints[sessionId] = points
        
        let gridPointsFile = gridPointsDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        let data = try JSONEncoder().encode(points)
        try data.write(to: gridPointsFile)
    }
    
    func loadGridPoints(for sessionId: UUID) async throws -> [GridPoint] {
        if let cached = gridPoints[sessionId] {
            return cached
        }
        
        let gridPointsFile = gridPointsDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        
        guard fileManager.fileExists(atPath: gridPointsFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: gridPointsFile)
        let points = try JSONDecoder().decode([GridPoint].self, from: data)
        gridPoints[sessionId] = points
        
        return points
    }
    
    // MARK: - Photo Assets Management
    
    func savePhotoAsset(_ photo: PhotoAsset) async throws {
        if photoAssets[photo.sessionId] == nil {
            photoAssets[photo.sessionId] = []
        }
        
        if let index = photoAssets[photo.sessionId]?.firstIndex(where: { $0.id == photo.id }) {
            photoAssets[photo.sessionId]?[index] = photo
        } else {
            photoAssets[photo.sessionId]?.append(photo)
        }
        
        try await savePhotoAssetsToFile(for: photo.sessionId)
    }
    
    func loadPhotoAssets(for sessionId: UUID) async throws -> [PhotoAsset] {
        if let cached = photoAssets[sessionId] {
            return cached
        }
        
        let photosFile = photosDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        
        guard fileManager.fileExists(atPath: photosFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: photosFile)
        let assets = try JSONDecoder().decode([PhotoAsset].self, from: data)
        photoAssets[sessionId] = assets
        
        return assets
    }
    
    func deletePhotoAsset(_ photo: PhotoAsset) async throws {
        photoAssets[photo.sessionId]?.removeAll { $0.id == photo.id }
        
        // Delete photo file
        try? fileManager.removeItem(at: photo.fileURL)
        
        try await savePhotoAssetsToFile(for: photo.sessionId)
    }
    
    // MARK: - File Operations
    
    func savePhoto(_ image: UIImage, for sessionId: UUID, gridPointId: UUID) async throws -> PhotoAsset {
        let sessionPhotosDirectory = photosDirectory.appendingPathComponent(sessionId.uuidString)
        
        // Create session photos directory if needed
        if !fileManager.fileExists(atPath: sessionPhotosDirectory.path) {
            try fileManager.createDirectory(at: sessionPhotosDirectory, withIntermediateDirectories: true)
        }
        
        let photoId = UUID().uuidString
        let photoFile = sessionPhotosDirectory.appendingPathComponent("\(photoId).jpg")
        
        // Save image as JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw DataStoreError.imageCompressionFailed
        }
        
        try imageData.write(to: photoFile)
        
        // Create photo asset
        let photoAsset = PhotoAsset(
            id: photoId,
            sessionId: sessionId,
            gridPointId: gridPointId,
            fileURL: photoFile
        )
        
        try await savePhotoAsset(photoAsset)
        return photoAsset
    }
    
    // MARK: - Private Methods
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: gridPointsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }
    
    private func loadData() {
        loadProjectsFromFile()
        loadLocationsFromFile()
        loadSessionsFromFile()
    }
    
    private func loadProjectsFromFile() {
        guard fileManager.fileExists(atPath: projectsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: projectsFile)
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("Error loading projects: \(error)")
        }
    }
    
    private func loadLocationsFromFile() {
        guard fileManager.fileExists(atPath: locationsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: locationsFile)
            locations = try JSONDecoder().decode([Location].self, from: data)
        } catch {
            print("Error loading locations: \(error)")
        }
    }
    
    private func loadSessionsFromFile() {
        guard fileManager.fileExists(atPath: sessionsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: sessionsFile)
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    private func saveProjectsToFile() async throws {
        let data = try JSONEncoder().encode(projects)
        try data.write(to: projectsFile)
    }
    
    private func saveLocationsToFile() async throws {
        let data = try JSONEncoder().encode(locations)
        try data.write(to: locationsFile)
    }
    
    private func saveSessionsToFile() async throws {
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: sessionsFile)
    }
    
    private func savePhotoAssetsToFile(for sessionId: UUID) async throws {
        let photosFile = photosDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        let assets = photoAssets[sessionId] ?? []
        let data = try JSONEncoder().encode(assets)
        try data.write(to: photosFile)
    }
    
    // MARK: - Export Methods
    
    func exportSessionData(_ session: Session) async throws -> SessionExportData {
        let points = try await loadGridPoints(for: session.id)
        let photos = try await loadPhotoAssets(for: session.id)
        
        return SessionExportData(
            session: session,
            gridPoints: points,
            photoAssets: photos
        )
    }
    
    func exportAllData() async throws -> AppExportData {
        return AppExportData(
            projects: projects,
            locations: locations,
            sessions: sessions,
            gridPoints: gridPoints,
            photoAssets: photoAssets
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
    let gridPoints: [UUID: [GridPoint]]
    let photoAssets: [UUID: [PhotoAsset]]
}

enum DataStoreError: Error, LocalizedError {
    case imageCompressionFailed
    case fileNotFound
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .fileNotFound:
            return "File not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
