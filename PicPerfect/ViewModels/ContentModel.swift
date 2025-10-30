//
//  ContentModel.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/18/25.
//

import Foundation
import Photos
import SwiftUI
import RevenueCat
import Playgrounds
import FirebaseAuth

@Observable
class ContentModel {
    
    @AppStorage("useCounter") static var useCounter: Int = 0
    @AppStorage("nextScanDate") static var nextScanDate: Double = 0.0
    @AppStorage("currentAppVersion") static var currentAppVersion = ""
   
    var processedPhotos: [PPImage] = []
    var showHistoryView: Bool = false
    var onboardingPresent = false
    
    //Purchases properties
    var showPaywall: Bool = false
    private let purchaseManager = PurchaseService.shared
    var isUserSubscribed: Bool = false
    var offerings: Offering? = nil
    
    var requestAppReviewPresent = false
    var activateAppReview = false
    
    let plusCategories: [PhotoGroupCategory] = [.blurry, .exposure]
    
    var feedbackFormPresent: Bool = false
    
    
    init() {
        Task {
            await signInAnonymouslyIfNeeded()
            await loadProcessedPhotos()
            await refreshSubscriptionStatus()
            offerings = await getOfferings()
            await activatePaywall()
        }
        
//        PhotoAnalysisCloudCache.clearProcessedPhotos()
    }
    
    func loadProcessedPhotos() async {
        
        processedPhotos.removeAll()
        
        let ids = PhotoAnalysisCloudCache.retrieveProcessedPhotos()
        
        PhotoLibraryScanner.shared.fetchProcessedPhotos(with: ids) { images in
            self.processedPhotos = images.prefix(10).reversed()
            
        }
    }
    
    //MARK: Purchases methods
    func refreshSubscriptionStatus() async {
        isUserSubscribed = await purchaseManager.isProUser()
    }
    
    func purchase(package: Package, completion: @escaping(Bool) -> Void) async {
        let success = await purchaseManager.purchase(package: package)
        if success {
            await refreshSubscriptionStatus()
            completion(true)
        }
        else {
            completion(false)
        }
    }
    
    func restorePurchases(completion: @escaping(Bool) -> Void) async {
        let success = await purchaseManager.restorePurchases()
        if success {
            await refreshSubscriptionStatus()
            completion(true)
        }
        else {
            completion(false)
        }
    }
    
    func getOfferings() async -> Offering? {
        return await purchaseManager.fetchOfferings()
    }
    
    //MARK: Subscription methods
    func isSubscriptionRequired(for category: PhotoGroupCategory) async -> Bool {
        if plusCategories.contains(category) {
            await refreshSubscriptionStatus()
            return !isUserSubscribed
        }
        
        return false
    }
    
    //MARK: Premissions methods
    func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        Service.requestPhotoLibraryAccessIfNeeded { granted in
            completion(granted)
        }
    }
    
    func reuqestNotificacionPermission(completion: @escaping(Bool) -> Void) {
        NotificationsService.requestNotificationAccess { granted in
            completion(granted)
        }
    }
    
    func canScanLibrary() -> Bool {
        
        Task {
            await refreshSubscriptionStatus()
        }
        
        if isUserSubscribed {
            return true
        } else {
            let now = Date()
            
            // Calculamos tiempo restante
            let nextDate = Date(timeIntervalSince1970: ContentModel.nextScanDate)
            if now < nextDate {
                let remaining = nextDate.timeIntervalSince(now)
                let hours = Int(remaining) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                let seconds = Int(remaining) % 60
                print("⏳ Next scan available in \(hours)h \(minutes)m \(seconds)s")
                return false
            } else {
                // Ya pasó el tiempo, se permite escanear
                return true
            }
        }
    }

    func calculateNextScanDate() async {
        await refreshSubscriptionStatus()
        
        if isUserSubscribed {
            ContentModel.nextScanDate = 0.0
        } else {
            let now = Date()
            ContentModel.nextScanDate = now.timeIntervalSince1970 + 6 * 3600
            let nextDate = Date(timeIntervalSince1970: ContentModel.nextScanDate)
            
            await NotificationsService.scheduleNextScan(for: nextDate)
           let pending =  await NotificationsService.pendingRequests()
            print("📬 Pending notifications: \(pending.map { $0.identifier })")
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .medium
            formatter.timeZone = .current
            print("🕒 Next scan date (local): \(formatter.string(from: nextDate))")
        }
    }
    
    private func activatePaywall() async  {
        if !isUserSubscribed && ContentModel.useCounter % 5 == 0 && ContentModel.useCounter != 0 {
           showPaywall = true
        }
    }
     
    
    //MARK: Ask for review
    func requestAppReview(afterCleanupHistory: Bool = false) {
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let thisVersion = "\(appVersion) Build: \(appBuild)"
        
        if ContentModel.currentAppVersion != thisVersion {
            ContentModel.currentAppVersion = thisVersion
            if afterCleanupHistory {
                activateAppReview = true
            }
            else {
                requestAppReviewPresent = true
            }
        }
       
    }
    
    //MARK: Sign in methods
    private func signInAnonymouslyIfNeeded() async {
        if let currentUser = Auth.auth().currentUser {
            print("✅ Already signed in as \(currentUser.uid)")
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("✅ Signed in anonymously as \(result.user.uid)")
        } catch {
            print("❌ Anonymous sign-in failed: \(error.localizedDescription)")
        }
    }
    
}


