//
//  PicPerfectApp.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI
import SwiftData

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
        }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(ContentModel())
                .environment(PhotoGroupManager())
                .onAppear {
                    // Sincronizar al volver al foreground
                    NSUbiquitousKeyValueStore.default.synchronize()
//                    PhotoAnalysisCloudCache.clearAllRecords()
//                    CleanupHistoryCloudStore.clearAll()
                }
        }
        .modelContainer(for: PersistentPhotoGroup.self)
    }
}
