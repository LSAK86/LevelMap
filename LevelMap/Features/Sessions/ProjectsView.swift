import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingNewProject = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateDesc
    
    var filteredProjects: [Project] {
        let filtered = dataStore.projects.filter { project in
            searchText.isEmpty || 
            project.name.localizedCaseInsensitiveContains(searchText) ||
            project.clientName.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .nameAsc:
                return first.name < second.name
            case .nameDesc:
                return first.name > second.name
            case .dateAsc:
                return first.createdAt < second.createdAt
            case .dateDesc:
                return first.createdAt > second.createdAt
            case .clientAsc:
                return first.clientName < second.clientName
            case .clientDesc:
                return first.clientName > second.clientName
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Sort Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search projects...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    HStack {
                        Menu {
                            Picker("Sort by", selection: $sortOrder) {
                                Text("Date (Newest)").tag(SortOrder.dateDesc)
                                Text("Date (Oldest)").tag(SortOrder.dateAsc)
                                Text("Name (A-Z)").tag(SortOrder.nameAsc)
                                Text("Name (Z-A)").tag(SortOrder.nameDesc)
                                Text("Client (A-Z)").tag(SortOrder.clientAsc)
                                Text("Client (Z-A)").tag(SortOrder.clientDesc)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Sort")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("\(filteredProjects.count) project\(filteredProjects.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Projects List
                if filteredProjects.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: searchText.isEmpty ? "No Projects" : "No Results",
                        message: searchText.isEmpty ? 
                            "Create your first project to get started with floor level verification." :
                            "Try adjusting your search terms."
                    )
                } else {
                    List {
                        ForEach(filteredProjects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectRowView(project: project)
                            }
                        }
                        .onDelete(perform: deleteProjects)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        Task {
            for index in offsets {
                let project = filteredProjects[index]
                try await dataStore.deleteProject(project)
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    @EnvironmentObject var dataStore: DataStore
    @State private var locationCount = 0
    @State private var sessionCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(project.clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(project.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(locationCount) locations")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress indicator
            if sessionCount > 0 {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("\(sessionCount) sessions completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadProjectStats()
        }
    }
    
    private func loadProjectStats() {
        Task {
            let locations = try await dataStore.loadLocations(for: project.id)
            locationCount = locations.count
            
            var totalSessions = 0
            for location in locations {
                let sessions = try await dataStore.loadSessions(for: location.id)
                totalSessions += sessions.count
            }
            
            await MainActor.run {
                sessionCount = totalSessions
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

enum SortOrder {
    case nameAsc, nameDesc, dateAsc, dateDesc, clientAsc, clientDesc
}

#Preview {
    ProjectsView()
        .environmentObject(DataStore())
}
