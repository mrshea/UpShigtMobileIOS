//
//  NotificationSettingsView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/10/26.
//

import SwiftUI

struct NotificationSettingsView: View {
  @ObservedObject private var notificationManager = NotificationManager.shared
  @State private var showPermissionSheet = false
  
  var body: some View {
    List {
      Section {
        HStack {
          Label("Push Notifications", systemImage: "bell.fill")
            .foregroundStyle(.primary)
          
          Spacer()
          
          if notificationManager.notificationsEnabled {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
          } else {
            Button("Enable") {
              showPermissionSheet = true
            }
            .font(.subheadline)
            .buttonStyle(.bordered)
            .controlSize(.small)
          }
        }
        
        if let token = notificationManager.deviceToken {
          VStack(alignment: .leading, spacing: 4) {
            Text("Device Token")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            Text(token)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
      } header: {
        Text("Status")
      } footer: {
        if notificationManager.notificationsEnabled {
          Text("You will receive notifications about new shifts, schedule changes, and important updates.")
        } else {
          Text("Enable notifications to stay updated about new shifts and schedule changes.")
        }
      }
      
      Section("Notification Types") {
        NotificationToggleRow(
          icon: "calendar.badge.plus",
          title: "New Shifts",
          description: "When new shifts are available",
          isEnabled: notificationManager.notificationsEnabled
        )
        
        NotificationToggleRow(
          icon: "bell.badge",
          title: "Shift Reminders",
          description: "Reminders before your shifts",
          isEnabled: notificationManager.notificationsEnabled
        )
        
        NotificationToggleRow(
          icon: "arrow.triangle.2.circlepath",
          title: "Schedule Changes",
          description: "Updates to your schedule",
          isEnabled: notificationManager.notificationsEnabled
        )
        
        NotificationToggleRow(
          icon: "megaphone.fill",
          title: "Announcements",
          description: "Important updates and news",
          isEnabled: notificationManager.notificationsEnabled
        )
      }
      .disabled(!notificationManager.notificationsEnabled)
      
      if notificationManager.notificationsEnabled {
        Section {
          Button(role: .destructive) {
            Task {
              await notificationManager.deactivateDeviceToken()
              openSettings()
            }
          } label: {
            Label("Disable Notifications", systemImage: "bell.slash.fill")
          }
        } footer: {
          Text("To disable notifications, you'll need to turn them off in Settings.")
        }
      }
    }
    .navigationTitle("Notifications")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showPermissionSheet) {
      NotificationPermissionView()
    }
    .task {
      await notificationManager.checkAuthorizationStatus()
    }
  }
  
  private func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

struct NotificationToggleRow: View {
  let icon: String
  let title: String
  let description: String
  let isEnabled: Bool
  @State private var isOn = true
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(isEnabled ? .blue : .gray)
        .frame(width: 32)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
        
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .disabled(!isEnabled)
    }
  }
}

#Preview {
  NavigationStack {
    NotificationSettingsView()
  }
}
