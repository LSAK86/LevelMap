import SwiftUI

struct NewProjectView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var clientName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter project name", text: $projectName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter client name", text: $clientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } header: {
                    Text("Project Details")
                } footer: {
                    Text("Create a new project to organize your floor level verification sessions.")
                }
                
                Section {
                    Button(action: createProject) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text("Create Project")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || isLoading)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createProject() {
        guard isFormValid else { return }
        
        isLoading = true
        
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClient = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let project = Project(
            name: trimmedName,
            clientName: trimmedClient
        )
        
        Task {
            do {
                try await dataStore.saveProject(project)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create project: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var dataStore: DataStore
    @State private var locations: [Location] = []
    @State private var showingNewLocation = false
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Project")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(project.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        Text(project.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Client")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(project.clientName)
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading locations...")
                            .foregroundColor(.secondary)
                    }
                } else if locations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No Locations")
                            .font(.headline)
                        
                        Text("Add a location to start creating measurement sessions.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Location") {
                            showingNewLocation = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(locations) { location in
                        NavigationLink(destination: LocationDetailView(location: location)) {
                            LocationRowView(location: location)
                        }
                    }
                    .onDelete(perform: deleteLocations)
                }
            } header: {
                HStack {
                    Text("Locations")
                    Spacer()
                    if !locations.isEmpty {
                        Button("Add") {
                            showingNewLocation = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !locations.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Location") {
                        showingNewLocation = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewLocation) {
            NewLocationView(project: project)
        }
        .onAppear {
            loadLocations()
        }
    }
    
    private func loadLocations() {
        Task {
            do {
                let projectLocations = try await dataStore.loadLocations(for: project.id)
                await MainActor.run {
                    locations = projectLocations
                    isLoading = false
                }
            } catch {
                print("Error loading locations: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        Task {
            for index in offsets {
                let location = locations[index]
                try await dataStore.deleteLocation(location)
            }
            await loadLocations()
        }
    }
}

struct LocationRowView: View {
    let location: Location
    @EnvironmentObject var dataStore: DataStore
    @State private var sessionCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(location.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(sessionCount) sessions")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadSessionCount()
        }
    }
    
    private func loadSessionCount() {
        Task {
            let sessions = try await dataStore.loadSessions(for: location.id)
            await MainActor.run {
                sessionCount = sessions.count
            }
        }
    }
}

#Preview {
    NewProjectView()
        .environmentObject(DataStore())
}
