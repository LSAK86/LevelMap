import SwiftUI

struct LocationDetailView: View {
    let location: Location
    @EnvironmentObject var dataStore: DataStore
    @State private var sessions: [Session] = []
    @State private var project: Project?
    @State private var showingNewSession = false
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(location.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        Text(location.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let address = location.address {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Address")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(address)
                                    .font(.body)
                            }
                            
                            Spacer()
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
                        Text("Loading sessions...")
                            .foregroundColor(.secondary)
                    }
                } else if sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No Sessions")
                            .font(.headline)
                        
                        Text("Start your first measurement session to verify floor levels.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("New Session") {
                            showingNewSession = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            } header: {
                HStack {
                    Text("Sessions")
                    Spacer()
                    if !sessions.isEmpty {
                        Button("Add") {
                            showingNewSession = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Session") {
                        showingNewSession = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionView(location: location)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            // Load sessions
            let locationSessions = try await dataStore.loadSessions(for: location.id)
            await MainActor.run {
                sessions = locationSessions
                isLoading = false
            }
            
            // Load project
            let projects = dataStore.projects.filter { $0.id == location.projectId }
            if let sessionProject = projects.first {
                await MainActor.run {
                    project = sessionProject
                }
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        Task {
            for index in offsets {
                let session = sessions[index]
                try await dataStore.deleteSession(session)
            }
            await loadData()
        }
    }
}

struct NewLocationView: View {
    let project: Project
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationName = ""
    @State private var address = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter location name", text: $locationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address (Optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } header: {
                    Text("Location Details")
                } footer: {
                    Text("Add a location to organize measurement sessions for this project.")
                }
                
                Section {
                    Button(action: createLocation) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text("Create Location")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || isLoading)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Location")
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
    
    private func createLocation() {
        guard isFormValid else { return }
        
        isLoading = true
        
        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let location = Location(
            projectId: project.id,
            name: trimmedName,
            address: trimmedAddress.isEmpty ? nil : trimmedAddress
        )
        
        Task {
            do {
                try await dataStore.saveLocation(location)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create location: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct NewSessionView: View {
    let location: Location
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("defaultUnits") private var defaultUnits = SessionUnits.imperial
    @AppStorage("defaultToleranceImperial") private var defaultToleranceImperial = 0.125
    @AppStorage("defaultToleranceMetric") private var defaultToleranceMetric = 3.0
    
    @State private var selectedUnits = SessionUnits.imperial
    @State private var tolerance = 0.125
    @State private var selectedGridPreset = 0
    @State private var customRows = 4
    @State private var customCols = 4
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private let gridPresets = GeometryUtils.gridPresets()
    
    var selectedGrid: (rows: Int, cols: Int) {
        if selectedGridPreset < gridPresets.count - 1 {
            return (gridPresets[selectedGridPreset].rows, gridPresets[selectedGridPreset].cols)
        } else {
            return (customRows, customCols)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Units", selection: $selectedUnits) {
                        ForEach(SessionUnits.allCases, id: \.self) { units in
                            Text(units.displayName).tag(units)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnits) { newValue in
                        updateTolerance()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tolerance")
                            .font(.headline)
                        
                        HStack {
                            Slider(
                                value: $tolerance,
                                in: selectedUnits == .imperial ? 0.0625...2.0 : 1.0...50.0,
                                step: selectedUnits == .imperial ? 0.0625 : 1.0
                            )
                            Text("\(tolerance, specifier: selectedUnits == .imperial ? "%.3f" : "%.0f") \(selectedUnits.unitLabel)")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(width: 80)
                        }
                    }
                } header: {
                    Text("Measurement Settings")
                }
                
                Section {
                    Picker("Grid Preset", selection: $selectedGridPreset) {
                        ForEach(0..<gridPresets.count, id: \.self) { index in
                            Text(gridPresets[index].name).tag(index)
                        }
                    }
                    
                    if selectedGridPreset == gridPresets.count - 1 {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(customRows)", value: $customRows, in: 2...26)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Columns")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(customCols)", value: $customCols, in: 2...50)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Grid Size")
                        Spacer()
                        Text("\(selectedGrid.rows) × \(selectedGrid.cols)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Grid Configuration")
                } footer: {
                    Text("Configure the measurement grid for systematic floor level verification.")
                }
                
                Section {
                    Button(action: createSession) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text("Start Session")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Session")
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
            .onAppear {
                selectedUnits = defaultUnits
                updateTolerance()
            }
        }
    }
    
    private func updateTolerance() {
        switch selectedUnits {
        case .imperial:
            tolerance = defaultToleranceImperial
        case .metric:
            tolerance = defaultToleranceMetric
        }
    }
    
    private func createSession() {
        isLoading = true
        
        let session = Session(
            locationId: location.id,
            units: selectedUnits,
            tolerance: tolerance,
            rows: selectedGrid.rows,
            cols: selectedGrid.cols
        )
        
        Task {
            do {
                try await dataStore.saveSession(session)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create session: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    LocationDetailView(location: Location(projectId: UUID(), name: "Test Location"))
        .environmentObject(DataStore())
}
