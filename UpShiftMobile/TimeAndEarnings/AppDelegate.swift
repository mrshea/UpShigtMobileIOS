//
//  AppDelegate.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/10/26.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self
    
    return true
  }
  
  // MARK: - Remote Notification Registration
  
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task {
      await NotificationManager.shared.registerDeviceToken(deviceToken)
    }
  }
  
  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NotificationManager.shared.handleRegistrationError(error)
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
  
  // Handle notification when app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    completionHandler([.banner, .sound, .badge])
  }
  
  // Handle notification tap
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Handle notification data
    print("📬 Notification tapped with data: \(userInfo)")
    
    // You can navigate to specific screens based on notification data here
    // Example:
    // if let shiftId = userInfo["shiftId"] as? String {
    //   // Navigate to shift detail
    // }
    
    completionHandler()
  }
}
