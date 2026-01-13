//
//  NotificationPermissionView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/10/26.
//

import SwiftUI

struct NotificationPermissionView: View {
  @StateObject private var notificationManager = NotificationManager.shared
  @Environment(\.dismiss) private var dismiss
  @State private var isRequesting = false
  
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      // Icon
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 120, height: 120)
        
        Image(systemName: "bell.badge.fill")
          .font(.system(size: 60))
          .foregroundStyle(.white)
      }
      .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)
      
      // Title and Description
      VStack(spacing: 12) {
        Text("Stay Updated")
          .font(.title.bold())
        
        Text("Get notified about new shifts, schedule changes, and important updates")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }
      
      // Features List
      VStack(alignment: .leading, spacing: 16) {
        featureRow(
          icon: "calendar.badge.plus",
          title: "New Shifts",
          description: "Be the first to know when new shifts are available"
        )
        
        featureRow(
          icon: "clock.badge.checkmark",
          title: "Shift Reminders",
          description: "Never miss a shift with timely reminders"
        )
        
        featureRow(
          icon: "bell.badge",
          title: "Schedule Changes",
          description: "Get notified about any updates to your schedule"
        )
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 20)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(16)
      .padding(.horizontal)
      
      Spacer()
      
      // Action Buttons
      VStack(spacing: 12) {
        Button(action: requestPermission) {
          HStack {
            if isRequesting {
              ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            } else {
              Text("Enable Notifications")
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundStyle(.white)
          .cornerRadius(12)
        }
        .disabled(isRequesting)
        
        Button("Maybe Later") {
          dismiss()
        }
        .foregroundStyle(.secondary)
      }
      .padding(.horizontal)
      .padding(.bottom, 32)
    }
  }
  
  private func featureRow(icon: String, title: String, description: String) -> some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(.blue)
        .frame(width: 32)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline.weight(.semibold))
        
        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private func requestPermission() {
    isRequesting = true
    
    Task {
      do {
        let granted = try await notificationManager.requestAuthorization()
        
        await MainActor.run {
          isRequesting = false
          
          if granted {
            dismiss()
          } else {
            // Show alert that user needs to enable in settings
            openSettings()
          }
        }
      } catch {
        await MainActor.run {
          isRequesting = false
          print("Error requesting notification permission: \(error)")
        }
      }
    }
  }
  
  private func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  NotificationPermissionView()
}
