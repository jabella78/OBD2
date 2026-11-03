import Foundation
import StoreKit

@MainActor
public class StoreManager: ObservableObject {
    public static let shared = StoreManager()
    public static let proProductID = "com.jabella78.yadiag.pro"
    
    @Published public var isProUnlocked: Bool = false
    @Published public var products: [Product] = []
    @Published public var isPurchasing: Bool = false
    @Published public var purchaseErrorMessage: String? = nil
    
    private var transactionListener: Task<Void, Error>? = nil
    
    public init() {
        // Ripristino stato cache locale
        self.isProUnlocked = UserDefaults.standard.bool(forKey: "isProUnlocked")
        
        // Ascolto aggiornamenti transazioni in background (StoreKit 2)
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    public func loadProducts() async {
        do {
            let loaded = try await Product.products(for: [Self.proProductID])
            self.products = loaded
        } catch {
            print("StoreKit loadProducts error: \(error)")
        }
    }
    
    public func purchasePro() async -> Bool {
        guard let product = products.first(where: { $0.id == Self.proProductID }) ?? products.first else {
            purchaseErrorMessage = "Prodotto non disponibile al momento."
            return false
        }
        
        isPurchasing = true
        purchaseErrorMessage = nil
        
        do {
            let result = try await product.purchase()
            isPurchasing = false
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    self.isProUnlocked = true
                    UserDefaults.standard.set(true, forKey: "isProUnlocked")
                    return true
                }
                return false
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            isPurchasing = false
            purchaseErrorMessage = error.localizedDescription
            return false
        }
    }
    
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }
    
    public func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.proProductID && transaction.revocationDate == nil {
                    self.isProUnlocked = true
                    UserDefaults.standard.set(true, forKey: "isProUnlocked")
                    return
                }
            }
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await MainActor.run {
                        if transaction.productID == StoreManager.proProductID && transaction.revocationDate == nil {
                            StoreManager.shared.isProUnlocked = true
                            UserDefaults.standard.set(true, forKey: "isProUnlocked")
                        }
                    }
                }
            }
        }
    }
}
