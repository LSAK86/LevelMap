import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var entitlementService: EntitlementService
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if authService.isSignedIn {
                if entitlementService.hasValidEntitlement {
                    MainTabView()
                } else {
                    SubscriptionView()
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            checkOnboarding()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    
    private func checkOnboarding() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            showingOnboarding = true
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ProjectsView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Projects")
                }
                .tag(0)
            
            SessionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Sessions")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Modern Home View
struct ModernHomeView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingNewProject = false
    @State private var showingQuickStart = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ModernDesignSystem.Spacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Projects
                    recentProjectsSection
                    
                    // Statistics
                    statisticsSection
                }
                .padding()
            }
            .background(ModernDesignSystem.Colors.background)
            .navigationTitle("LevelMap")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(ModernDesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
            .sheet(isPresented: $showingQuickStart) {
                QuickStartView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ModernDesignSystem.Colors.primary, ModernDesignSystem.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: ModernDesignSystem.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "ruler")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Welcome Text
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("Welcome to LevelMap")
                    .font(ModernDesignSystem.Typography.headlineMedium)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                Text("AR Floor Verification Made Simple")
                    .font(ModernDesignSystem.Typography.bodyMedium)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            Text("Quick Actions")
                .font(ModernDesignSystem.Typography.titleLarge)
                .foregroundColor(ModernDesignSystem.Colors.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ModernDesignSystem.Spacing.md) {
                QuickActionCard(
                    title: "New Session",
                    subtitle: "Start measuring",
                    icon: "plus.circle.fill",
                    color: ModernDesignSystem.Colors.primary
                ) {
                    showingQuickStart = true
                }
                
                QuickActionCard(
                    title: "View Projects",
                    subtitle: "Manage projects",
                    icon: "folder.fill",
                    color: ModernDesignSystem.Colors.secondary
                ) {
                    // Navigate to projects
                }
                
                QuickActionCard(
                    title: "Export Data",
                    subtitle: "Generate reports",
                    icon: "square.and.arrow.up.fill",
                    color: ModernDesignSystem.Colors.accent
                ) {
                    // Show export options
                }
                
                QuickActionCard(
                    title: "Settings",
                    subtitle: "Configure app",
                    icon: "gear.fill",
                    color: ModernDesignSystem.Colors.info
                ) {
                    // Navigate to settings
                }
            }
        }
    }
    
    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                Text("Recent Projects")
                    .font(ModernDesignSystem.Typography.titleLarge)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all projects
                }
                .font(ModernDesignSystem.Typography.labelMedium)
                .foregroundColor(ModernDesignSystem.Colors.primary)
            }
            
            if dataStore.projects.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Projects Yet",
                    subtitle: "Create your first project to get started",
                    actionTitle: "Create Project",
                    action: { showingNewProject = true }
                )
            } else {
                LazyVStack(spacing: ModernDesignSystem.Spacing.sm) {
                    ForEach(dataStore.projects.prefix(3)) { project in
                        ProjectCard(project: project)
                    }
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            Text("Statistics")
                .font(ModernDesignSystem.Typography.titleLarge)
                .foregroundColor(ModernDesignSystem.Colors.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: ModernDesignSystem.Spacing.md) {
                StatCard(
                    title: "Total Projects",
                    value: "\(dataStore.projects.count)",
                    icon: "folder.fill",
                    color: ModernDesignSystem.Colors.primary
                )
                
                StatCard(
                    title: "Total Sessions",
                    value: "\(dataStore.sessions.count)",
                    icon: "list.bullet",
                    color: ModernDesignSystem.Colors.secondary
                )
                
                StatCard(
                    title: "Completed Points",
                    value: "\(dataStore.gridPoints.filter { $0.isCompleted }.count)",
                    icon: "checkmark.circle.fill",
                    color: ModernDesignSystem.Colors.success
                )
                
                StatCard(
                    title: "Total Points",
                    value: "\(dataStore.gridPoints.count)",
                    icon: "grid",
                    color: ModernDesignSystem.Colors.info
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(ModernDesignSystem.Typography.titleSmall)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(ModernDesignSystem.Typography.bodySmall)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(ModernDesignSystem.Spacing.lg)
            .background(ModernDesignSystem.Colors.card)
            .cornerRadius(ModernDesignSystem.CornerRadius.lg)
            .shadow(color: ModernDesignSystem.Shadows.small.color, radius: ModernDesignSystem.Shadows.small.radius, x: ModernDesignSystem.Shadows.small.x, y: ModernDesignSystem.Shadows.small.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // Project Icon
            ZStack {
                Circle()
                    .fill(ModernDesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.primary)
            }
            
            // Project Info
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                Text(project.name)
                    .font(ModernDesignSystem.Typography.titleMedium)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                Text(project.clientName)
                    .font(ModernDesignSystem.Typography.bodySmall)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                
                Text("Created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(ModernDesignSystem.Typography.bodySmall)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.card)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .shadow(color: ModernDesignSystem.Shadows.small.color, radius: ModernDesignSystem.Shadows.small.radius, x: ModernDesignSystem.Shadows.small.x, y: ModernDesignSystem.Shadows.small.y)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(ModernDesignSystem.Typography.headlineSmall)
                .foregroundColor(ModernDesignSystem.Colors.text)
                .fontWeight(.bold)
            
            Text(title)
                .font(ModernDesignSystem.Typography.bodySmall)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.card)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .shadow(color: ModernDesignSystem.Shadows.small.color, radius: ModernDesignSystem.Shadows.small.radius, x: ModernDesignSystem.Shadows.small.x, y: ModernDesignSystem.Shadows.small.y)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 50, weight: .light))
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text(title)
                    .font(ModernDesignSystem.Typography.titleLarge)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(ModernDesignSystem.Typography.bodyMedium)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            ModernPrimaryButton(actionTitle, icon: "plus.circle") {
                action()
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .background(ModernDesignSystem.Colors.card)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
    }
}

// MARK: - Quick Start View
struct QuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProject: Project?
    @State private var showingProjectPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Header
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.accent)
                    
                    Text("Quick Start")
                        .font(ModernDesignSystem.Typography.headlineLarge)
                        .foregroundColor(ModernDesignSystem.Colors.text)
                    
                    Text("Start measuring in seconds")
                        .font(ModernDesignSystem.Typography.bodyMedium)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                // Options
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    QuickStartOption(
                        title: "New Project",
                        subtitle: "Create a new project and start measuring",
                        icon: "plus.circle.fill",
                        action: { showingProjectPicker = true }
                    )
                    
                    QuickStartOption(
                        title: "Existing Project",
                        subtitle: "Continue with an existing project",
                        icon: "folder.fill",
                        action: { showingProjectPicker = true }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Quick Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingProjectPicker) {
            ProjectPickerView(selectedProject: $selectedProject)
        }
    }
}

struct QuickStartOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text(title)
                        .font(ModernDesignSystem.Typography.titleMedium)
                        .foregroundColor(ModernDesignSystem.Colors.text)
                    
                    Text(subtitle)
                        .font(ModernDesignSystem.Typography.bodySmall)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            .padding(ModernDesignSystem.Spacing.lg)
            .background(ModernDesignSystem.Colors.card)
            .cornerRadius(ModernDesignSystem.CornerRadius.lg)
            .shadow(color: ModernDesignSystem.Shadows.small.color, radius: ModernDesignSystem.Shadows.small.radius, x: ModernDesignSystem.Shadows.small.x, y: ModernDesignSystem.Shadows.small.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectPickerView: View {
    @Binding var selectedProject: Project?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        NavigationView {
            List(dataStore.projects) { project in
                Button(action: {
                    selectedProject = project
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(ModernDesignSystem.Typography.titleMedium)
                            Text(project.clientName)
                                .font(ModernDesignSystem.Typography.bodySmall)
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(EntitlementService())
        .environmentObject(DataStore())
}
