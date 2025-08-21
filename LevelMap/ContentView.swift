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
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            showingOnboarding = true
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
            
            SessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(EntitlementService())
}
