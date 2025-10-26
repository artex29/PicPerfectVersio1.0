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

@Observable
class ContentModel {
    
    @AppStorage("useCounter") static var useCounter: Int = 0
   
    var processedPhotos: [PPImage] = []
    var showHistoryView: Bool = false
    var onboardingPresent = false
    
    //Purchases properties
    var showPaywall: Bool = false
    private let purchaseManager = PurchaseService.shared
    var isProUser: Bool = false
    var offerings: Offering? = nil
    
    
    
    init() {
        Task {
            await loadProcessedPhotos()
            await refreshSubscriptionStatus()
            offerings = await getOfferings()
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
        isProUser = await purchaseManager.isProUser()
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
}
