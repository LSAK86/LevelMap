import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var entitlementService: EntitlementService
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("defaultUnits") private var defaultUnits: SessionUnits = .imperial
    @AppStorage("defaultFractionalResolution") private var defaultFractionalResolution: FractionalResolution = .sixteenth
    @AppStorage("defaultTolerance") private var defaultTolerance: Double = 0.25
    @AppStorage("includeAIValuesInExport") private var includeAIValuesInExport: Bool = true
    @AppStorage("includePhotosInExport") private var includePhotosInExport: Bool = true
    
    @State private var showingSignOutAlert = false
    @State private var showingHelp = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(DesignSystem.Colors.primary)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name ?? "User")
                                    .font(DesignSystem.Typography.headline)
                                Text(user.email ?? "")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let entitlement = entitlementService.currentEntitlement {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entitlement.planType.displayName)
                                    .font(DesignSystem.Typography.headline)
                                Text("Valid until \(entitlement.expiresAt, style: .date)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(DesignSystem.Colors.error)
                }
                
                // Measurement Settings
                Section("Measurement Settings") {
                    NavigationLink("Default Units") {
                        UnitsSettingsView(defaultUnits: $defaultUnits)
                    }
                    
                    NavigationLink("Default Tolerance") {
                        ToleranceSettingsView(tolerance: $defaultTolerance, units: $defaultUnits)
                    }
                    
                    if defaultUnits == .imperial {
                        Picker("Fractional Resolution", selection: $defaultFractionalResolution) {
                            ForEach(FractionalResolution.allCases, id: \.self) { resolution in
                                Text(resolution.displayName).tag(resolution)
                            }
                        }
                    }
                }
                
                // Export Settings
                Section("Export Settings") {
                    Toggle("Include AI Values", isOn: $includeAIValuesInExport)
                    Toggle("Include Photos", isOn: $includePhotosInExport)
                }
                
                // Support & Legal
                Section("Support & Legal") {
                    Button("Help & FAQ") {
                        showingHelp = true
                    }
                    
                    Button("Privacy Policy") {
                        showingPrivacyPolicy = true
                    }
                    
                    Button("Terms of Service") {
                        showingTermsOfService = true
                    }
                }
                
                // App Info
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out? You can sign back in at any time.")
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
    }
}

// MARK: - Units Settings View

struct UnitsSettingsView: View {
    @Binding var defaultUnits: SessionUnits
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(SessionUnits.allCases, id: \.self) { unit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(unit.displayName)
                                .font(DesignSystem.Typography.headline)
                            Text(unit.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if defaultUnits == unit {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        defaultUnits = unit
                    }
                }
            } footer: {
                Text("This setting will be used as the default for new measurement sessions.")
            }
        }
        .navigationTitle("Default Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Getting Started
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Getting Started")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("1. Create a Project")
                                .font(DesignSystem.Typography.headline)
                            Text("Start by creating a new project and adding a location for your measurements.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("2. Start a Session")
                                .font(DesignSystem.Typography.headline)
                            Text("Configure your measurement session with units, tolerance, and grid settings.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("3. AR Measurement")
                                .font(DesignSystem.Typography.headline)
                            Text("Use AR to detect the floor, place a rectangle, and generate a measurement grid.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("4. Capture Measurements")
                                .font(DesignSystem.Typography.headline)
                            Text("Take photos of rulers with laser dots at each grid point for AI analysis.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Tips for Best Results")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("• Good Lighting")
                                .font(DesignSystem.Typography.headline)
                            Text("Ensure adequate lighting for accurate AI reading of ruler measurements.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("• Steady Camera")
                                .font(DesignSystem.Typography.headline)
                            Text("Keep the camera steady when capturing photos for better AI accuracy.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("• Clear Ruler")
                                .font(DesignSystem.Typography.headline)
                            Text("Use a clean, well-lit ruler with clear markings for best AI recognition.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Troubleshooting
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Troubleshooting")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("AR Not Working?")
                                .font(DesignSystem.Typography.headline)
                            Text("Ensure you're in a well-lit environment with clear floor surfaces. Move the camera slowly to help AR detect planes.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("AI Reading Issues?")
                                .font(DesignSystem.Typography.headline)
                            Text("If AI readings are inaccurate, try recalibrating or manually entering measurements. Ensure the ruler is clearly visible in photos.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text("Privacy Policy")
                        .font(DesignSystem.Typography.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(Date(), style: .date)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Data Collection")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("LevelMap collects and stores measurement data locally on your device. This includes project information, measurement sessions, and photos taken during measurements. No data is transmitted to external servers unless you explicitly export it.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Data Usage")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("Your measurement data is used solely for the purpose of providing floor level verification services. AI analysis is performed on-device and does not require internet connectivity.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Data Security")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("All data is stored locally on your device using iOS security features. When you export data, it is your responsibility to ensure it is shared securely.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Third-Party Services")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("LevelMap uses Apple's Sign in with Apple for authentication and StoreKit for in-app purchases. These services are subject to Apple's privacy policies.")
                            .font(DesignSystem.Typography.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text("Terms of Service")
                        .font(DesignSystem.Typography.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(Date(), style: .date)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Acceptance of Terms")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("By using LevelMap, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Use of Service")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("LevelMap is designed for professional floor level verification. You are responsible for ensuring that measurements are accurate and appropriate for your intended use. The app provides tools but does not guarantee measurement accuracy.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Subscription Terms")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage subscriptions in your Apple ID settings.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Limitation of Liability")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("LevelMap is provided 'as is' without warranties. The developers are not liable for any damages arising from the use of the application or measurement results.")
                            .font(DesignSystem.Typography.body)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Changes to Terms")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("These terms may be updated from time to time. Continued use of the app constitutes acceptance of any changes.")
                            .font(DesignSystem.Typography.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(EntitlementService())
}
