//
//  NotificationManager.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/10/26.
//

import Foundation
import Combine
import UserNotifications
import UIKit
import Clerk
import UpShiftAPI
import Apollo

@MainActor
class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  
  @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
  @Published var deviceToken: String?
  
  private let clerk = Clerk.shared
  
  private init() {
    // Don't call async methods in init
  }
  
  // MARK: - Authorization
  
  func checkAuthorizationStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    self.authorizationStatus = settings.authorizationStatus
  }
  
  func requestAuthorization() async throws -> Bool {
    let granted = try await UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    )
    
    await checkAuthorizationStatus()
    
    if granted {
      // Register for remote notifications on the main thread
      UIApplication.shared.registerForRemoteNotifications()
    }
    
    return granted
  }
  
  // MARK: - Device Token Management
  
  func registerDeviceToken(_ deviceToken: Data) async {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    self.deviceToken = tokenString
    
    print("📱 APNs Device Token: \(tokenString)")
    
    // Save token to GraphQL backend
    await saveTokenToBackend(tokenString)
  }
  
  func handleRegistrationError(_ error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // MARK: - GraphQL Backend Integration
  
  private func saveTokenToBackend(_ token: String) async {
    guard clerk.user != nil else {
      print("⚠️ No user logged in, cannot register device token")
      return
    }
    
    // Store token locally as backup
    UserDefaults.standard.set(token, forKey: "apnsDeviceToken")
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "apnsTokenUpdatedAt")
    
    print("✅ Device token saved locally")
    print("   Token: \(token)")
    
       do {
         let mutation = RegisterDeviceTokenMutation(
           token: token,
           platform: .case(.ios)
         )
         
         let result = try await Network.shared.apollo.perform(mutation: mutation)
         
         if let data = result.data {
           if data.registerDeviceToken.success {
             print("✅ Device token registered with backend")
             print("   Message: \(data.registerDeviceToken.message ?? "Success")")
           } else {
             print("⚠️ Token registration returned failure")
             print("   Message: \(data.registerDeviceToken.message ?? "Unknown error")")
           }
         }
         
         if let errors = result.errors {
           print("❌ GraphQL errors during token registration:")
           errors.forEach { error in
             print("   - \(error.message)")
           }
         }
       } catch {
         print("❌ Failed to register device token with backend: \(error.localizedDescription)")
         print("   Token stored locally for later retry")
       }
  }
  
  func deactivateDeviceToken() async {
    guard let token = deviceToken ?? UserDefaults.standard.string(forKey: "apnsDeviceToken") else {
      print("⚠️ No device token to deactivate")
      return
    }
    
    // Clear local storage
    UserDefaults.standard.removeObject(forKey: "apnsDeviceToken")
    UserDefaults.standard.removeObject(forKey: "apnsTokenUpdatedAt")
    self.deviceToken = nil
    
    print("✅ Device token cleared locally")
    print("💡 TODO: Implement GraphQL mutation once schema is generated")
    print("   Run Apollo Codegen to generate: DeactivateDeviceTokenMutation")
    
    // TODO: Uncomment once Apollo generates the types
    /*
    do {
      let mutation = DeactivateDeviceTokenMutation(token: token)
      let result = try await Network.shared.apollo.perform(mutation: mutation)
      
      if let data = result.data {
        if data.deactivateDeviceToken.success {
          print("✅ Device token deactivated on backend")
          print("   Message: \(data.deactivateDeviceToken.message ?? "Success")")
        }
      }
    } catch {
      print("❌ Failed to deactivate device token: \(error.localizedDescription)")
    }
    */
  }
  
  func deactivateAllDeviceTokens() async {
    // Clear local storage
    UserDefaults.standard.removeObject(forKey: "apnsDeviceToken")
    UserDefaults.standard.removeObject(forKey: "apnsTokenUpdatedAt")
    self.deviceToken = nil
    
    print("✅ Device tokens cleared locally")
    print("💡 TODO: Implement GraphQL mutation once schema is generated")
    print("   Run Apollo Codegen to generate: DeactivateAllDeviceTokensMutation")
    
    // TODO: Uncomment once Apollo generates the types
    /*
    do {
      let mutation = DeactivateAllDeviceTokensMutation()
      let result = try await Network.shared.apollo.perform(mutation: mutation)
      
      if let data = result.data {
        if data.deactivateAllDeviceTokens.success {
          print("✅ All device tokens deactivated on backend")
          print("   Message: \(data.deactivateAllDeviceTokens.message ?? "Success")")
        }
      }
    } catch {
      print("❌ Failed to deactivate all device tokens: \(error.localizedDescription)")
    }
    */
  }
  
  // Retry registration if it failed earlier
  func retryRegistration() async {
    guard let token = UserDefaults.standard.string(forKey: "apnsDeviceToken") else {
      print("⚠️ No stored token to retry")
      return
    }
    
    print("🔄 Retrying device token registration...")
    await saveTokenToBackend(token)
  }
  
  // MARK: - Notification Permissions UI
  
  var shouldShowPermissionPrompt: Bool {
    authorizationStatus == .notDetermined
  }
  
  var notificationsEnabled: Bool {
    authorizationStatus == .authorized
  }
}
