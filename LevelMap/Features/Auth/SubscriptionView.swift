import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var entitlementService: EntitlementService
    @State private var selectedTab = 0
    @State private var orgCode = ""
    @State private var showingOrgCodeAlert = false
    @State private var orgCodeAlertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Choose Your Plan")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock unlimited floor level verification")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal)
                
                // Tab Picker
                Picker("Plan Type", selection: $selectedTab) {
                    Text("Individual").tag(0)
                    Text("Organization").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 30)
                
                // Content
                TabView(selection: $selectedTab) {
                    IndividualPlansView()
                        .tag(0)
                    
                    OrganizationPlansView(orgCode: $orgCode, showingAlert: $showingOrgCodeAlert, alertMessage: $orgCodeAlertMessage)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
                
                Spacer()
            }
            .alert("Organization Code", isPresented: $showingOrgCodeAlert) {
                Button("OK") { }
            } message: {
                Text(orgCodeAlertMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct IndividualPlansView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly Plan
                PlanCard(
                    title: "Monthly",
                    price: "$9.99",
                    period: "per month",
                    features: [
                        "Unlimited projects",
                        "Unlimited sessions",
                        "AI measurement reading",
                        "PDF & CSV exports",
                        "LiDAR support"
                    ],
                    isPopular: false
                ) {
                    if let monthlyProduct = purchaseService.products.first(where: { $0.id == "com.levelmap.individual.monthly" }) {
                        Task {
                            try await purchaseService.purchase(monthlyProduct)
                        }
                    }
                }
                
                // Yearly Plan
                PlanCard(
                    title: "Yearly",
                    price: "$99.99",
                    period: "per year",
                    features: [
                        "Everything in Monthly",
                        "2 months free",
                        "Priority support",
                        "Early access to features"
                    ],
                    isPopular: true
                ) {
                    if let yearlyProduct = purchaseService.products.first(where: { $0.id == "com.levelmap.individual.yearly" }) {
                        Task {
                            try await purchaseService.purchase(yearlyProduct)
                        }
                    }
                }
                
                // Restore Purchases
                Button("Restore Purchases") {
                    Task {
                        try await purchaseService.restorePurchases()
                    }
                }
                .foregroundColor(.blue)
                .padding(.top, 20)
                
                if purchaseService.isLoading {
                    ProgressView()
                        .padding(.top, 20)
                }
                
                if let errorMessage = purchaseService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
            .padding()
        }
    }
}

struct OrganizationPlansView: View {
    @EnvironmentObject var entitlementService: EntitlementService
    @Binding var orgCode: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Organization Code Entry
                VStack(spacing: 16) {
                    Text("Enter Organization Code")
                        .font(.headline)
                    
                    TextField("Organization Code", text: $orgCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal)
                    
                    Button("Validate Code") {
                        validateOrgCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(orgCode.isEmpty || entitlementService.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Available Plans
                VStack(spacing: 16) {
                    Text("Available Plans")
                        .font(.headline)
                    
                    ForEach(OrgPlanType.allCases, id: \.self) { plan in
                        OrgPlanCard(plan: plan)
                    }
                }
                
                if entitlementService.isLoading {
                    ProgressView()
                        .padding(.top, 20)
                }
                
                if let errorMessage = entitlementService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
            .padding()
        }
    }
    
    private func validateOrgCode() {
        Task {
            do {
                let result = try await entitlementService.validateOrgCode(orgCode)
                await MainActor.run {
                    if result.isValid {
                        alertMessage = "Valid code! \(result.planType?.displayName ?? "") plan with \(result.availableSeats) available seats."
                    } else {
                        alertMessage = "Invalid organization code. Please check and try again."
                    }
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let features: [String]
    let isPopular: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 4) {
                Text(price)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(period)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.body)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Choose Plan") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct OrgPlanCard: View {
    let plan: OrgPlanType
    
    var body: some View {
        VStack(spacing: 12) {
            Text(plan.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(plan.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                VStack {
                    Text("\(plan.maxSeats)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Max Seats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("$\(String(format: "%.2f", plan.pricePerSeat))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Per Seat/Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(PurchaseService())
        .environmentObject(EntitlementService())
}
