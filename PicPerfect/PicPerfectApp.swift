//
//  PicPerfectApp.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI
import SwiftData
import RevenueCat
import FirebaseAuth
import FirebaseCore
import FirebaseAnalytics

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
        
        print("URL.applicationSupportDirectory", URL.applicationSupportDirectory
                   .path(percentEncoded: false))
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.rcAPIKey)
        
        FirebaseApp.configure()
        
    }
    
    let container: ModelContainer = {
        let schema = Schema([PersistentPhotoGroup.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            print("📂 Store URL:", container.configurations.first?.url ?? .init(string: "nil")!)
            return container
        }
        catch {
            fatalError("❌ Error creating ModelContainer: \(error)")
        }
    }()
    
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
        .modelContainer(container)
        
    }
}
