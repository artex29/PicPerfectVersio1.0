//
//  NotificationsService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/25/25.
//

import UserNotifications


class NotificationsService {
    
    // Identificador fijo para poder modificar/cancelar la notificación del próximo escaneo
    static private let nextScanIdentifier = "pp.next.scan.notification"
    
   static func requestNotificationAccess(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
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
        content.title = "Your next library scan is ready!"
        let clickType = device == .mac ? "click" : "tap"
        content.body = "\(clickType) to start the scan and keep your photos tidy."
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

