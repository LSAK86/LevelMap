import SwiftUI
import RealityKit
import ARKit

@main
struct LevelMapApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var authService = AuthService()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var entitlementService = EntitlementService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(authService)
                .environmentObject(purchaseService)
                .environmentObject(entitlementService)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize services
        authService.checkSignInStatus()
        purchaseService.configureStore()
        entitlementService.loadEntitlements()
    }
}
