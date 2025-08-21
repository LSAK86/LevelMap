import Foundation
import Combine

// MARK: - Entitlement Service

class EntitlementService: ObservableObject {
    @Published var currentEntitlement: Entitlement?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let entitlementKey = "currentEntitlement"
    
    init() {
        loadEntitlements()
    }
    
    // MARK: - Public Methods
    
    func loadEntitlements() {
        if let data = userDefaults.data(forKey: entitlementKey),
           let entitlement = try? JSONDecoder().decode(Entitlement.self, from: data) {
            currentEntitlement = entitlement
        }
    }
    
    var hasValidEntitlement: Bool {
        guard let entitlement = currentEntitlement else { return false }
        return entitlement.hasValidEntitlement
    }
    
    func validateOrgCode(_ code: String) async throws -> OrgCodeValidationResult {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock validation - in real app, this would call your backend
        let result = await mockValidateOrgCode(code)
        
        if result.isValid {
            // Update entitlement
            let entitlement = Entitlement(
                userId: "mock-user-id",
                planType: .org,
                seatsAllocated: result.seatsAllocated,
                seatsUsed: result.seatsUsed,
                orgCode: code,
                expiresAt: result.expiresAt
            )
            
            await MainActor.run {
                self.currentEntitlement = entitlement
                self.saveEntitlement(entitlement)
            }
        }
        
        isLoading = false
        return result
    }
    
    func claimSeat() async throws -> Bool {
        guard let entitlement = currentEntitlement,
              entitlement.planType == .org,
              entitlement.availableSeats > 0 else {
            throw EntitlementError.noAvailableSeats
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Mock seat claim - in real app, this would call your backend
        let success = await mockClaimSeat(entitlement.orgCode ?? "")
        
        if success {
            var updatedEntitlement = entitlement
            updatedEntitlement.seatsUsed += 1
            
            await MainActor.run {
                self.currentEntitlement = updatedEntitlement
                self.saveEntitlement(updatedEntitlement)
            }
        }
        
        isLoading = false
        return success
    }
    
    func releaseSeat() async throws {
        guard let entitlement = currentEntitlement,
              entitlement.planType == .org,
              entitlement.seatsUsed > 0 else {
            throw EntitlementError.noSeatsToRelease
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Mock seat release - in real app, this would call your backend
        let success = await mockReleaseSeat(entitlement.orgCode ?? "")
        
        if success {
            var updatedEntitlement = entitlement
            updatedEntitlement.seatsUsed = max(0, updatedEntitlement.seatsUsed - 1)
            
            await MainActor.run {
                self.currentEntitlement = updatedEntitlement
                self.saveEntitlement(updatedEntitlement)
            }
        }
        
        isLoading = false
    }
    
    func clearEntitlement() {
        currentEntitlement = nil
        userDefaults.removeObject(forKey: entitlementKey)
    }
    
    // MARK: - Private Methods
    
    private func saveEntitlement(_ entitlement: Entitlement) {
        if let data = try? JSONEncoder().encode(entitlement) {
            userDefaults.set(data, forKey: entitlementKey)
        }
    }
    
    // MARK: - Mock Methods (Replace with real API calls)
    
    private func mockValidateOrgCode(_ code: String) async -> OrgCodeValidationResult {
        // Mock validation logic
        let validCodes = [
            "STARTER2024": OrgCodeValidationResult(
                isValid: true,
                planType: .starter,
                seatsAllocated: 100,
                seatsUsed: 45,
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            ),
            "PRO2024": OrgCodeValidationResult(
                isValid: true,
                planType: .pro,
                seatsAllocated: 300,
                seatsUsed: 120,
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            ),
            "ENTERPRISE2024": OrgCodeValidationResult(
                isValid: true,
                planType: .enterprise,
                seatsAllocated: 500,
                seatsUsed: 200,
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: Date())
            )
        ]
        
        if let result = validCodes[code.uppercased()] {
            return result
        } else {
            return OrgCodeValidationResult(
                isValid: false,
                planType: nil,
                seatsAllocated: 0,
                seatsUsed: 0,
                expiresAt: nil
            )
        }
    }
    
    private func mockClaimSeat(_ orgCode: String) async -> Bool {
        // Mock seat claim - always succeeds for valid codes
        return ["STARTER2024", "PRO2024", "ENTERPRISE2024"].contains(orgCode.uppercased())
    }
    
    private func mockReleaseSeat(_ orgCode: String) async -> Bool {
        // Mock seat release - always succeeds for valid codes
        return ["STARTER2024", "PRO2024", "ENTERPRISE2024"].contains(orgCode.uppercased())
    }
}

// MARK: - Supporting Types

struct OrgCodeValidationResult {
    let isValid: Bool
    let planType: OrgPlanType?
    let seatsAllocated: Int
    let seatsUsed: Int
    let expiresAt: Date?
    
    var availableSeats: Int {
        return max(0, seatsAllocated - seatsUsed)
    }
}

enum OrgPlanType: String, CaseIterable {
    case starter = "STARTER"
    case pro = "PRO"
    case enterprise = "ENTERPRISE"
    
    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .pro: return "Pro"
        case .enterprise: return "Enterprise"
        }
    }
    
    var maxSeats: Int {
        switch self {
        case .starter: return 100
        case .pro: return 300
        case .enterprise: return 500
        }
    }
    
    var pricePerSeat: Double {
        switch self {
        case .starter: return 1.50
        case .pro: return 1.25
        case .enterprise: return 1.00
        }
    }
    
    var description: String {
        switch self {
        case .starter:
            return "Up to 100 seats at $1.50/user/month"
        case .pro:
            return "Up to 300 seats at $1.25/user/month"
        case .enterprise:
            return "Up to 500 seats at $1.00/user/month"
        }
    }
}

enum EntitlementError: Error, LocalizedError {
    case invalidOrgCode
    case noAvailableSeats
    case noSeatsToRelease
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidOrgCode:
            return "Invalid organization code"
        case .noAvailableSeats:
            return "No available seats in your organization plan"
        case .noSeatsToRelease:
            return "No seats to release"
        case .networkError:
            return "Network error occurred"
        case .serverError:
            return "Server error occurred"
        }
    }
}
