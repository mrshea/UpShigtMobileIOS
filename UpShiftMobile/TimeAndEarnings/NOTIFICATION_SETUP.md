# Push Notifications Implementation Guide

## Overview
This implementation adds remote push notifications to your app with APNs token storage in Clerk metadata.

## Files Created

### 1. **NotificationManager.swift**
Main service class that handles:
- Requesting notification permissions
- Managing APNs device tokens
- Storing tokens in Clerk user metadata
- Checking authorization status

### 2. **AppDelegate.swift**
Handles APNs registration callbacks:
- `didRegisterForRemoteNotificationsWithDeviceToken` - Success callback
- `didFailToRegisterForRemoteNotificationsWithError` - Error callback
- `UNUserNotificationCenterDelegate` methods for handling notifications

### 3. **NotificationPermissionView.swift**
Beautiful permission request UI that:
- Explains why notifications are needed
- Shows key features (new shifts, reminders, schedule changes)
- Handles permission request flow
- Opens Settings if user denied previously

### 4. **NotificationSettingsView.swift**
Settings screen for managing notifications:
- Shows current notification status
- Displays device token (for debugging)
- Lists notification types
- Allows disabling notifications

## Setup Steps

### 1. Configure Apple Push Notification Service (APNs)

#### In Apple Developer Portal:
1. Go to [developer.apple.com](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your **App ID**
4. Enable **Push Notifications** capability
5. Create APNs certificates:
   - **Development**: For testing
   - **Production**: For App Store builds

#### In Xcode:
1. Select your project target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes** (optional)
   - Enable **Remote notifications** for background updates

### 2. Test Notifications

#### Send Test Notification:
You can send test notifications using the following methods:

**Option 1: Using curl (from terminal)**
```bash
# You'll need:
# - Your APNs auth key (.p8 file)
# - Device token
# - Team ID
# - Key ID
# - Bundle ID

curl -v \
  --header "apns-topic: YOUR_BUNDLE_ID" \
  --header "apns-push-type: alert" \
  --cert YourAuthKey.p8 \
  --cert-type P8 \
  --data '{"aps":{"alert":{"title":"New Shift Available","body":"Check out the latest opportunities"},"sound":"default"}}' \
  https://api.sandbox.push.apple.com/3/device/YOUR_DEVICE_TOKEN
```

**Option 2: Using a tool like [Pusher](https://github.com/noodlewerk/NWPusher)**

**Option 3: From your backend**
```javascript
// Example Node.js with apn library
const apn = require('apn');

const options = {
  token: {
    key: 'path/to/AuthKey.p8',
    keyId: 'YOUR_KEY_ID',
    teamId: 'YOUR_TEAM_ID'
  },
  production: false // Use true for production
};

const apnProvider = new apn.Provider(options);

const note = new apn.Notification({
  alert: {
    title: 'New Shift Available',
    body: 'Check out the latest opportunities'
  },
  topic: 'YOUR_BUNDLE_ID',
  sound: 'default',
  payload: {
    shiftId: '12345',
    type: 'new_shift'
  }
});

apnProvider.send(note, deviceToken).then(result => {
  console.log('Sent:', result);
});
```

### 3. Access Device Token from Clerk

The device token is stored in the user's `unsafeMetadata` in Clerk:

```typescript
// Backend example to get token
const user = await clerkClient.users.getUser(userId);
const apnsToken = user.unsafeMetadata.apnsToken;
const platform = user.unsafeMetadata.platform; // "ios"
const updatedAt = user.unsafeMetadata.apnsTokenUpdatedAt;
```

## Usage in Your App

### Show Permission Request on First Launch
```swift
// In ContentView or after login
.sheet(isPresented: $showNotificationPermission) {
  NotificationPermissionView()
}
```

### Check Permission Status
```swift
let notificationManager = NotificationManager.shared

// Check current status
await notificationManager.checkAuthorizationStatus()

if notificationManager.notificationsEnabled {
  print("Notifications are enabled!")
}
```

### Navigate to Settings
```swift
// User can access from Profile > Notifications
ProfileView(clerk: clerk)
```

## Notification Payload Structure

### Basic Notification
```json
{
  "aps": {
    "alert": {
      "title": "New Shift Available",
      "body": "There's a new kitchen shift starting at 6 PM"
    },
    "sound": "default",
    "badge": 1
  },
  "shiftId": "shift_123",
  "type": "new_shift"
}
```

### With Custom Data
```json
{
  "aps": {
    "alert": {
      "title": "Shift Reminder",
      "body": "Your shift starts in 1 hour"
    },
    "sound": "default",
    "badge": 1
  },
  "shiftId": "shift_456",
  "type": "shift_reminder",
  "startTime": "2026-01-10T18:00:00Z"
}
```

## Handling Notifications in App

The `AppDelegate` includes handlers for:

1. **Foreground notifications** - Shows banner even when app is open
2. **Notification taps** - Handle user tapping on notification

You can extend the tap handler to navigate to specific screens:

```swift
func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse,
  withCompletionHandler completionHandler: @escaping () -> Void
) {
  let userInfo = response.notification.request.content.userInfo
  
  // Navigate based on notification type
  if let type = userInfo["type"] as? String {
    switch type {
    case "new_shift":
      // Navigate to available shifts
      break
    case "shift_reminder":
      // Navigate to my schedule
      break
    case "schedule_change":
      // Show alert or navigate to specific shift
      break
    default:
      break
    }
  }
  
  completionHandler()
}
```

## Testing Checklist

- [ ] Permission request shows correctly
- [ ] Device token is generated
- [ ] Token is saved to Clerk metadata
- [ ] Can send test notification successfully
- [ ] Notification appears in foreground
- [ ] Notification appears in background
- [ ] Tapping notification opens app
- [ ] Settings screen shows correct status
- [ ] Can disable notifications from Settings
- [ ] Token is removed from Clerk when disabled

## Troubleshooting

### Token not generating?
- Ensure Push Notifications capability is enabled
- Check provisioning profile includes push notifications
- Try running on a real device (simulator has limitations)

### Notifications not arriving?
- Verify APNs certificate is valid
- Check bundle ID matches
- Ensure device token is correct
- Try sandbox environment first
- Check device notification settings

### Token not saving to Clerk?
- Check user is logged in
- Verify Clerk configuration
- Check console logs for errors
- Ensure `unsafeMetadata` permissions are correct

## Security Notes

- Device tokens are stored in `unsafeMetadata` (accessible by user)
- Never expose APNs auth keys in client code
- Validate notifications on your backend
- Implement rate limiting for notification sends
- Consider using topics for targeted notifications

## Next Steps

1. Set up your backend to send notifications
2. Implement notification scheduling
3. Add notification categories for actions
4. Track notification metrics
5. Implement notification preferences (per shift type, etc.)
