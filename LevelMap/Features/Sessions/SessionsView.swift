import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var sessions: [Session] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    var filteredSessions: [Session] {
        sessions.filter { session in
            searchText.isEmpty || 
            session.id.uuidString.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search sessions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Sessions List
                if isLoading {
                    ProgressView("Loading sessions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredSessions.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet",
                        title: searchText.isEmpty ? "No Sessions" : "No Results",
                        message: searchText.isEmpty ? 
                            "Create your first session to start measuring." :
                            "Try adjusting your search terms."
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSessions()
            }
        }
    }
    
    private func loadSessions() {
        Task {
            await MainActor.run {
                sessions = dataStore.sessions
                isLoading = false
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        Task {
            for index in offsets {
                let session = filteredSessions[index]
                try await dataStore.deleteSession(session)
            }
            await loadSessions()
        }
    }
}

struct SessionRowView: View {
    let session: Session
    @EnvironmentObject var dataStore: DataStore
    @State private var location: Location?
    @State private var project: Project?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session \(session.id.uuidString.prefix(8))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = location {
                        Text(location.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.startedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.units.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("\(session.rows)×\(session.cols) grid")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if session.completedAt != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadSessionDetails()
        }
    }
    
    private func loadSessionDetails() {
        Task {
            // Load location
            let locations = dataStore.locations.filter { $0.id == session.locationId }
            if let sessionLocation = locations.first {
                await MainActor.run {
                    location = sessionLocation
                }
                
                // Load project
                let projects = dataStore.projects.filter { $0.id == sessionLocation.projectId }
                if let sessionProject = projects.first {
                    await MainActor.run {
                        project = sessionProject
                    }
                }
            }
        }
    }
}

struct SessionDetailView: View {
    let session: Session
    @EnvironmentObject var dataStore: DataStore
    @State private var gridPoints: [GridPoint] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session ID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.id.uuidString)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.startedAt, style: .date)
                                .font(.body)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Units")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.units.displayName)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tolerance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.tolerance, specifier: "%.3f") \(session.units.unitLabel)")
                                .font(.body)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Grid Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.rows) rows × \(session.cols) columns")
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.completedAt != nil ? "Completed" : "In Progress")
                                .font(.body)
                                .foregroundColor(session.completedAt != nil ? .green : .orange)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading grid points...")
                            .foregroundColor(.secondary)
                    }
                } else if gridPoints.isEmpty {
                    Text("No grid points available")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(gridPoints) { point in
                        GridPointRowView(point: point)
                    }
                }
            } header: {
                Text("Grid Points")
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadGridPoints()
        }
    }
    
    private func loadGridPoints() {
        Task {
            do {
                let points = try await dataStore.loadGridPoints(for: session.id)
                await MainActor.run {
                    gridPoints = points
                    isLoading = false
                }
            } catch {
                print("Error loading grid points: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct GridPointRowView: View {
    let point: GridPoint
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(point.label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let value = point.finalValue {
                    Text("\(value, specifier: "%.3f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not measured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            if let passFail = point.passFail {
                Image(systemName: passFail ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(passFail ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionsView()
        .environmentObject(DataStore())
}
