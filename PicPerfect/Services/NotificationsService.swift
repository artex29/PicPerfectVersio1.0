//
//  NotificationsService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/25/25.
//

import UserNotifications

class NotificationsService {
   static func requestNotificationAccess(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
}

