# Push Notifications with GraphQL Backend

## Overview
This implementation registers APNs device tokens with your GraphQL backend for push notifications.

## Setup Complete ✅

### Files Created:
1. **NotificationManager.swift** - Core notification service
2. **AppDelegate.swift** - APNs callbacks handler
3. **NotificationPermissionView.swift** - Permission request UI  
4. **NotificationSettingsView.swift** - Settings screen
5. **LoginHandler.swift** - Login/logout integration
6. **DeviceTokenOperations.graphql** - GraphQL operations

### Files Updated:
- **UpShiftMobileApp.swift** - Added AppDelegate
- **ProfileView.swift** - Linked to notification settings

## Usage

### 1. On App Launch
The app automatically handles device token registration through `AppDelegate`.

### 2. On User Login
Call this after successful Clerk login:

```swift
// In your login success handler
Task {
  await NotificationManager.shared.handleLogin()
}
```

This will:
- Check notification authorization status
- Retry registration if token exists but wasn't saved
- Suggest showing permission prompt if needed

### 3. Show Permission Request
Show the permission view when appropriate:

```swift
// After login or at strategic point
.sheet(isPresented: $showNotificationPermission) {
  NotificationPermissionView()
}
```

### 4. On User Logout
Call this before Clerk logout:

```swift
// In your logout handler
Task {
  await NotificationManager.shared.handleLogout()
  // Then proceed with Clerk signOut
  try? await clerk.signOut()
}
```

This will deactivate all device tokens for the user.

## GraphQL Operations

The app uses these GraphQL mutations/queries:

### Register Token (Automatic)
```graphql
mutation RegisterDeviceToken($token: String!, $platform: Platform!) {
  registerDeviceToken(token: $token, platform: $platform) {
    success
    message
  }
}
```

Variables sent:
```json
{
  "token": "apns-device-token-here",
  "platform": "IOS"
}
```

### Deactivate All Tokens (On Logout)
```graphql
mutation DeactivateAllDeviceTokens {
  deactivateAllDeviceTokens {
    success
    message
  }
}
```

### Deactivate Specific Token (On Settings Disable)
```graphql
mutation DeactivateDeviceToken($token: String!) {
  deactivateDeviceToken(token: $token) {
    success
    message
  }
}
```

## Integration Points

### Login Flow
```swift
// Example in your SignInView
func handleSuccessfulLogin() async {
  // After Clerk login succeeds
  await NotificationManager.shared.handleLogin()
  
  // Show permission request if not determined
  if NotificationManager.shared.shouldShowPermissionPrompt {
    showNotificationPermission = true
  }
}
```

### Logout Flow
```swift
// Example in your ProfileView
func handleLogout() async {
  // Deactivate tokens first
  await NotificationManager.shared.handleLogout()
  
  // Then sign out
  try? await clerk.signOut()
}
```

### App Launch
The `AppDelegate` automatically handles:
- APNs registration callbacks
- Token conversion to hex string
- Notification presentation (foreground/background)
- Notification tap handling

## Notification Management

### Check Status
```swift
let manager = NotificationManager.shared

// Check if enabled
if manager.notificationsEnabled {
  print("Notifications are enabled")
}

// Check if should prompt
if manager.shouldShowPermissionPrompt {
  // Show permission view
}

// Get current authorization status
await manager.checkAuthorizationStatus()
```

### Manual Operations
```swift
// Request permission
let granted = try await manager.requestAuthorization()

// Retry registration (if failed earlier)
await manager.retryRegistration()

// Deactivate current device
await manager.deactivateDeviceToken()

// Deactivate all devices
await manager.deactivateAllDeviceTokens()
```

## Error Handling

All operations include error logging. Check console for:

- ✅ `Device token registered with backend` - Success
- ⚠️ `Token registration returned failure` - Backend rejected
- ❌ `Failed to register device token` - Network/other error
- 💡 `Token stored locally for later retry` - Will retry on next login

## Backend Requirements

Your GraphQL backend must implement these operations:

1. **registerDeviceToken** - Save/update token for authenticated user
2. **deactivateDeviceToken** - Deactivate specific token
3. **deactivateAllDeviceTokens** - Deactivate all user's tokens
4. **myDeviceTokens** (optional) - List user's active tokens

See `DeviceTokenOperations.graphql` for the complete schema.

## Testing

### 1. Enable Push Notifications in Xcode
- Select your target
- Go to Signing & Capabilities
- Add "Push Notifications" capability
- Add "Background Modes" > "Remote notifications"

### 2. Configure APNs Certificates
- Create APNs certificates in Apple Developer Portal
- Upload to your backend push notification service

### 3. Test Flow
1. Install app on physical device
2. Login with Clerk
3. Allow notifications when prompted
4. Check console for "✅ Device token registered"
5. Send test notification from backend
6. Tap notification - should open app
7. Logout - check console for "✅ All device tokens deactivated"

## Console Output Examples

### Successful Registration
```
📱 APNs Device Token: b59766b9cc33840310d92303a25a4066ba8268937d43c0ee482a7f5f352f407c
✅ Device token registered with backend
   Message: Device token registered successfully
```

### On Login
```
🔐 User logged in - checking notification status
💡 Notification permission not determined - show prompt to user
```

### On Logout
```
🔐 User logging out - deactivating device tokens
✅ All device tokens deactivated
   Message: All tokens deactivated successfully
```

## Security Notes

- Tokens are stored locally in UserDefaults as backup
- GraphQL backend validates authentication via Clerk
- Tokens are associated with user accounts
- Deactivation prevents notifications to logged-out devices
- Backend never returns actual token values in queries

## Troubleshooting

### Token Not Generating
- Run on physical device (simulator has limitations)
- Ensure Push Notifications capability is enabled
- Check provisioning profile

### Registration Failing
- Check GraphQL endpoint is correct
- Verify Clerk authentication is working
- Check backend logs for errors
- Token is stored locally and will retry on next login

### Notifications Not Arriving
- Verify APNs certificate is valid and uploaded
- Check device token is in backend database
- Test with Apple's push notification testing tools
- Ensure app is configured for remote notifications

## Next Steps

1. ✅ Configure APNs certificates
2. ✅ Test on physical device
3. ✅ Verify backend receives tokens
4. ✅ Send test notifications
5. ✅ Implement notification handlers for deep linking
6. ✅ Add notification preferences UI
