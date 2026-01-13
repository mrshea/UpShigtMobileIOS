//
//  LoginHandler.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/10/26.
//

import Foundation
import Clerk

/// Extension to handle notification token registration on login/logout
extension NotificationManager {
  
  /// Call this after successful login
  func handleLogin() async {
    print("🔐 User logged in - checking notification status")
    
    // Check if we have permission
    await checkAuthorizationStatus()
    
    if notificationsEnabled {
      // If we have a stored token that wasn't registered, retry
      await retryRegistration()
    } else if shouldShowPermissionPrompt {
      print("💡 Notification permission not determined - show prompt to user")
    }
  }
  
  /// Call this before logout
  func handleLogout() async {
    print("🔐 User logging out - deactivating device tokens")
    
    // Deactivate all tokens for this user
    await deactivateAllDeviceTokens()
  }
}
