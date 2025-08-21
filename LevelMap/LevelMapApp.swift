import SwiftUI
import RealityKit
import ARKit

@main
struct LevelMapApp: App {
    // MARK: - Environment Objects
    @StateObject private var dataStore = DataStore()
    @StateObject private var authService = AuthService()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var entitlementService = EntitlementService()
    @StateObject private var aiService = VisionMeasurementAIService()
    
    // MARK: - App State
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingView()
                } else {
                    ContentView()
                        .environmentObject(dataStore)
                        .environmentObject(authService)
                        .environmentObject(purchaseService)
                        .environmentObject(entitlementService)
                        .environmentObject(aiService)
                }
            }
            .onAppear {
                setupApp()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - App Setup
    private func setupApp() {
        Task {
            do {
                // Initialize services
                try await dataStore.loadData()
                authService.checkSignInStatus()
                purchaseService.configureStore()
                entitlementService.loadEntitlements()
                
                // Check device capabilities
                await checkDeviceCapabilities()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func checkDeviceCapabilities() async {
        // Check ARKit availability
        guard ARWorldTrackingConfiguration.isSupported else {
            await MainActor.run {
                errorMessage = "This device doesn't support ARKit. Some features may be limited."
                showingError = true
            }
            return
        }
        
        // Check LiDAR availability
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("LiDAR available - full height measurement features enabled")
        } else {
            print("LiDAR not available - height measurements will be limited")
        }
    }
}
