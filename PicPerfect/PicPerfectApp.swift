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
import FirebaseMessaging
#if os(iOS)
import UIKit
typealias ApplicationDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias ApplicationDelegate = NSApplicationDelegate
#endif

@main
struct PicPerfectApp: App {
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(PicPerfectAppDelegate.self) var appDelegate
#else

    @UIApplicationDelegateAdaptor(PicPerfectAppDelegate.self) var appDelegate
#endif
    
#if DEBUG
let isDebugBuild = true
#else
let isDebugBuild = false
#endif
    
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
        
        Analytics.setAnalyticsCollectionEnabled(!isDebugBuild)
        
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

class PicPerfectAppDelegate: NSObject,
                   ApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                             MessagingDelegate {
    
    // MARK: - App Lifecycle
#if os(iOS)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureFirebaseAndNotifications()
        return true
    }
#elseif os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureFirebaseAndNotifications()
    }
#endif
    
    // MARK: - Firebase + Notifications setup
    private func configureFirebaseAndNotifications() {
        // Configurar Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        // Configurar centro de notificaciones
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
#if os(iOS)
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
#elseif os(macOS)
        NSApplication.shared.registerForRemoteNotifications(matching: [.alert, .sound, .badge])
#endif
    }
    
    // MARK: - FCM Token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("📱 FCM token: \(token)")
        
        // Ejemplo: subir a Firestore si querés segmentar notificaciones
        /*
         let db = Firestore.firestore()
         db.collection("userTokens").document(token).setData([
         "token": token,
         "updatedAt": Timestamp(date: Date())
         ], merge: true)
         */
    }
    
    // MARK: - Notificaciones recibidas
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification received in foreground: \(notification.request.content.userInfo)")
#if os(iOS)
        completionHandler([.banner, .sound, .badge])
#elseif os(macOS)
        completionHandler([.banner, .sound])
#endif
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📬 Notification tapped: \(userInfo)")
        completionHandler()
    }
    
    // MARK: - iOS: Manejar device token APNs
#if os(iOS)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📦 Registered for APNs on iOS")
    }
#elseif os(macOS)
    func application(_ application: NSApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📦 Registered for APNs on macOS")
    }
#endif
    
#if os(iOS)
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for APNs on iOS: \(error.localizedDescription)")
    }
#elseif os(macOS)
    func application(_ application: NSApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for APNs on macOS: \(error.localizedDescription)")
    }
#endif
}

