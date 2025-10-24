//
//  PicPerfectApp.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct PicPerfectApp: App {
    
    init() {
        // Forzar sincronización inicial
        NSUbiquitousKeyValueStore.default.synchronize()
        
        // Suscribirse a cambios en iCloud
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { note in
            print("☁️ iCloud store updated: \(note.userInfo ?? [:])")
        }
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.rcAPIKey)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(ContentModel())
                .environment(PhotoGroupManager())
                .onAppear {
                    // Sincronizar al volver al foreground
                    NSUbiquitousKeyValueStore.default.synchronize()
//                    Task {
//                        await PhotoAnalysisCloudCache.clearAllRecords()
//                        PhotoAnalysisCloudCache.clearProcessedPhotos()
//                        CleanupHistoryCloudStore.clearAll()
//                    }
                    
                }
        }
        .modelContainer(for: PersistentPhotoGroup.self)
    }
}
