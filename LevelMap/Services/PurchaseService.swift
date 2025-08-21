import Foundation
import StoreKit
import Combine

// MARK: - Purchase Service

@MainActor
class PurchaseService: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIdentifiers = [
        "com.levelmap.individual.monthly",
        "com.levelmap.individual.yearly"
    ]
    
    override init() {
        super.init()
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func configureStore() {
        // StoreKit 2 automatically handles configuration
        // This method can be used for additional setup if needed
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIdentifiers)
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful purchase
                await updatePurchasedProducts()
                isLoading = false
                
            case .userCancelled:
                isLoading = false
                throw PurchaseError.userCancelled
                
            case .pending:
                isLoading = false
                throw PurchaseError.pending
                
            @unknown default:
                isLoading = false
                throw PurchaseError.unknown
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    func checkSubscriptionStatus() async -> Bool {
        await updatePurchasedProducts()
        return !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }
    }
    
    private func handleTransactionResult(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try result.payloadValue
            
            // Handle the transaction
            await self.updatePurchasedProducts()
            
            // Finish the transaction
            await transaction.finish()
        } catch {
            print("Transaction failed verification: \(error)")
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchasedProductIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try result.payloadValue
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Transaction failed verification: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProductIDs
    }
}

// MARK: - Supporting Types

enum PurchaseError: Error, LocalizedError {
    case userCancelled
    case pending
    case unknown
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "Unknown purchase error"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
