import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var entitlementService: EntitlementService
    @State private var showingSignOutAlert = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            List {
                // User Section
                Section {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email ?? "No email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Account")
                }
                
                // Subscription Section
                Section {
                    if let entitlement = entitlementService.currentEntitlement {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Plan Type")
                                    .font(.headline)
                                Spacer()
                                Text(entitlement.planType.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            if entitlement.planType == .org {
                                HStack {
                                    Text("Organization")
                                    Spacer()
                                    Text(entitlement.orgCode ?? "Unknown")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Seats Used")
                                    Spacer()
                                    Text("\(entitlement.seatsUsed)/\(entitlement.seatsAllocated)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let expiresAt = entitlement.expiresAt {
                                    HStack {
                                        Text("Expires")
                                        Spacer()
                                        Text(expiresAt, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        NavigationLink("Manage Subscription") {
                            SubscriptionView()
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // Preferences Section
                Section {
                    NavigationLink("Units & Precision") {
                        UnitsSettingsView()
                    }
                    
                    NavigationLink("Tolerance Presets") {
                        ToleranceSettingsView()
                    }
                    
                    NavigationLink("Export Settings") {
                        ExportSettingsView()
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Support Section
                Section {
                    NavigationLink("Help & Documentation") {
                        HelpView()
                    }
                    
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                    
                    Button("Show Onboarding") {
                        showingOnboarding = true
                    }
                } header: {
                    Text("Support")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to sign in again to access your data.")
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
        }
    }
}

struct UnitsSettingsView: View {
    @AppStorage("defaultUnits") private var defaultUnits = SessionUnits.imperial
    @AppStorage("fractionalResolution") private var fractionalResolution = FractionalResolution.eighth
    
    var body: some View {
        Form {
            Section {
                Picker("Default Units", selection: $defaultUnits) {
                    ForEach(SessionUnits.allCases, id: \.self) { units in
                        Text(units.displayName).tag(units)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if defaultUnits == .imperial {
                    Picker("Fractional Precision", selection: $fractionalResolution) {
                        ForEach(FractionalResolution.allCases, id: \.self) { resolution in
                            Text(resolution.displayName).tag(resolution)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            } header: {
                Text("Measurement Units")
            } footer: {
                Text("These settings will be used as defaults for new sessions.")
            }
        }
        .navigationTitle("Units & Precision")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ToleranceSettingsView: View {
    @AppStorage("defaultToleranceImperial") private var defaultToleranceImperial = 0.125
    @AppStorage("defaultToleranceMetric") private var defaultToleranceMetric = 3.0
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Imperial (inches)")
                        .font(.headline)
                    
                    HStack {
                        Slider(value: $defaultToleranceImperial, in: 0.0625...2.0, step: 0.0625)
                        Text("\(defaultToleranceImperial, specifier: "%.3f") in")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 80)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metric (mm)")
                        .font(.headline)
                    
                    HStack {
                        Slider(value: $defaultToleranceMetric, in: 1.0...50.0, step: 1.0)
                        Text("\(Int(defaultToleranceMetric)) mm")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 80)
                    }
                }
            } header: {
                Text("Default Tolerances")
            } footer: {
                Text("These tolerance values will be used as defaults for new sessions.")
            }
        }
        .navigationTitle("Tolerance Presets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportSettingsView: View {
    @AppStorage("includeAIValues") private var includeAIValues = true
    @AppStorage("includePhotos") private var includePhotos = true
    @AppStorage("exportFormat") private var exportFormat = "PDF"
    
    var body: some View {
        Form {
            Section {
                Toggle("Include AI Values", isOn: $includeAIValues)
                Toggle("Include Photos", isOn: $includePhotos)
                
                Picker("Default Export Format", selection: $exportFormat) {
                    Text("PDF").tag("PDF")
                    Text("CSV").tag("CSV")
                    Text("JSON").tag("JSON")
                }
                .pickerStyle(SegmentedPickerStyle())
            } header: {
                Text("Export Options")
            } footer: {
                Text("Configure what data is included in exported reports.")
            }
        }
        .navigationTitle("Export Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help & Documentation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Started")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("1. Create a new project and add locations")
                    Text("2. Start a new session and configure your grid")
                    Text("3. Use AR to place a rectangle on the floor")
                    Text("4. Capture measurements at each grid point")
                    Text("5. Review results and export reports")
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tips for Best Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("• Ensure good lighting for AR tracking")
                    Text("• Keep the ruler steady when capturing photos")
                    Text("• Use a laser level for consistent measurements")
                    Text("• Calibrate the AI if readings seem inaccurate")
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Support")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("For technical support or feature requests, please contact us at support@levelmap.app")
                }
            }
            .padding()
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us. This app processes measurement data locally on your device and does not transmit personal information to external servers unless you explicitly choose to export data.")
                
                Text("Data Collection")
                    .font(.headline)
                
                Text("• Measurement data is stored locally on your device")
                Text("• Photos are stored in the app's documents folder")
                Text("• No personal data is transmitted without your consent")
                
                Text("Data Usage")
                    .font(.headline)
                
                Text("• Data is used solely for measurement analysis")
                Text("• AI processing occurs entirely on-device")
                Text("• Export features are under your control")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("By using LevelMap, you agree to these terms of service.")
                
                Text("Use of Service")
                    .font(.headline)
                
                Text("• This app is for professional measurement purposes")
                Text("• Users are responsible for the accuracy of their measurements")
                Text("• The app is provided as-is without warranty")
                
                Text("Subscription Terms")
                    .font(.headline)
                
                Text("• Subscriptions auto-renew unless cancelled")
                Text("• Refunds are subject to App Store policies")
                Text("• Organization codes are managed by your organization")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(PurchaseService())
        .environmentObject(EntitlementService())
}
