//
//  PicPerfectApp.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI

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
            ScanLibraryView()
                .onAppear {
                    // Sincronizar al volver al foreground
                    NSUbiquitousKeyValueStore.default.synchronize()
//                    PhotoAnalysisCloudCache.clearPhotoAnalysisRecords()
                }
        }
    }
}
