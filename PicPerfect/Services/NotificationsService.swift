//
//  NotificationsService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/25/25.
//

import UserNotifications
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


class NotificationsService {
    
    // Identificador fijo para poder modificar/cancelar la notificación del próximo escaneo
    static private let nextScanIdentifier = "pp.next.scan.notification"
    
   static func requestNotificationAccess(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    
                    #if os(iOS)
                    if let appDelegate = UIApplication.shared.delegate as? PicPerfectAppDelegate {
                        appDelegate.registerForRemoteNotifications()
                    }
                    #elseif os(macOS)
                    if let appDelegate = NSApplication.shared.delegate as? PicPerfectAppDelegate {
                        appDelegate.registerForRemoteNotifications()
                    }
                    #endif
                    
                    completion(granted)
                }
            }
        }
    
    static func scheduleNextScan(for nextScanDate: Date) async {
        let device = DeviceHelper.type
        
        await cancelNextScan()
        
        let targetDate = nextScanDate
        let now = Date()
        
        let safeTarget = targetDate > now.addingTimeInterval(5) ? targetDate : now.addingTimeInterval(10)
        
        let content = UNMutableNotificationContent()
        content.title = LocalizedStringKey("nextScanReady").stringValue
        
        let clickType = device == .mac ?
        LocalizedStringKey("click").stringValue: LocalizedStringKey("tap").stringValue
        
        content.body = "\(clickType) \(LocalizedStringKey("startScan").stringValue)"
        content.sound = .default
        content.userInfo = ["type": "nextScan"]
        content.badge = 1
        
        // Trigger by exact date is better thatn intervals for a specific time
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: safeTarget)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        let request = UNNotificationRequest(identifier: NotificationsService.nextScanIdentifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
           
            print("Next scan notification scheduled for: \(safeTarget)")
           
        }
        catch {
            print("Error scheduling next scan notification: \(error)")
        }
        
    }
    
    // MARK: - Cancel / Inspect
    static  func cancelNextScan() async {
           UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [nextScanIdentifier])
           UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [nextScanIdentifier])
       }
       
    static func pendingRequests() async -> [UNNotificationRequest] {
           await UNUserNotificationCenter.current().pendingNotificationRequests()
       }
    
    static func clearBadgeCount() {
        
        UNUserNotificationCenter.current().setBadgeCount(0)
        
    }
}

