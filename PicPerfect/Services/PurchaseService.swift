//
//  PurchaseService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/22/25.
//

import RevenueCat

final class PurchaseService {
    static let entitlementID = "plus_access"
    
    static let shared = PurchaseService()
    
    init(){}
    
    //MARK: - Check Entitlement
    func isProUser() async -> Bool {
        do {
            let info = try await getCustomerInfo()
            return info?.entitlements.all[Self.entitlementID]?.isActive == true
        }
        catch {
            print("Error fetching customer info: \(error)")
            return false
        }
    }
    
    //MARK: - Fetch Offerings
    func fetchOfferings() async -> Offering? {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                print("✅ Loaded offering: \(current.identifier)")
                return current
            }
            else {
                print("⚠️ No current offering found.")
                return nil
            }
        }
        catch {
            print("❌ Failed to fetch offerings: \(error)")
            return nil
        }
    }
    
    //MARK: - Purchase Package
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            return result.customerInfo.entitlements.all[Self.entitlementID]?.isActive == true
        }
        catch {
            print("❌ Purchase failed: \(error)")
            return false
        }
    }
    
    //MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            let active = info.entitlements.all[Self.entitlementID]?.isActive == true
            print(active ? "🔓 Purchases restored." : "🔒 No active subscription.")
            return active
        }
        catch {
            print("❌ Restore failed: \(error)")
            return false
        }
    }
    
    //MARK: - Get Customer Info
    func getCustomerInfo() async throws -> CustomerInfo? {
        do {
            return try await Purchases.shared.customerInfo()
        }
        catch {
            print("❌ Error fetching customer info: \(error)")
            return nil
        }
    }
}
