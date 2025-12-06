//
//  ProfileView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/26/25.
//

import Foundation
import SwiftUI
import Clerk

// MARK: - Profile View
struct ProfileView: View {
  var clerk: Clerk

  var body: some View {
    NavigationStack {
        authenticatedView
    }
  }

  // MARK: - Authenticated View
  private var authenticatedView: some View {
    ScrollView {
      VStack(spacing: 0) {
        // Profile Header
        profileHeader
          .padding(.vertical, 32)
          .background(Color(.systemGroupedBackground))

        VStack(spacing: 24) {
          // Account Section
          accountSection

          // Preferences Section
          preferencesSection

          // Support Section
          supportSection

          // Account Actions
          accountActionsSection
        }
        .padding(.top, 24)
        .padding(.horizontal)
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Profile Header
  private var profileHeader: some View {
    VStack(spacing: 16) {
      // Profile Picture
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [.blue, .purple],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 100, height: 100)

        if let firstName = clerk.user?.firstName?.first,
           let lastName = clerk.user?.lastName?.first {
          Text("\(firstName)\(lastName)")
            .font(.system(size: 36, weight: .semibold))
            .foregroundStyle(.white)
        } else {
          Image(systemName: "person.fill")
            .font(.system(size: 40))
            .foregroundStyle(.white)
        }
      }
      .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

      // User Name
      Text(fullName)
        .font(.title2.bold())
        .foregroundStyle(.primary)

      // Email
      if let email = clerk.user?.primaryEmailAddress {
        Text(email.emailAddress)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      // Edit Profile Button (Clerk UserButton)
      UserButton()
        .frame(width: 36, height: 36)
        .padding(.top, 8)
    }
  }

  // MARK: - Account Section
  private var accountSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Account")
        .font(.headline)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)

      VStack(spacing: 0) {
        ProfileRow(
          icon: "person.fill",
          title: "Full Name",
          value: fullName,
          iconColor: .blue
        )

        Divider()
          .padding(.leading, 52)

        if let email = clerk.user?.primaryEmailAddress {
          ProfileRow(
            icon: "envelope.fill",
            title: "Email",
            value: email.emailAddress,
            iconColor: .green
          )

          Divider()
            .padding(.leading, 52)
        }

        if let phone = clerk.user?.primaryPhoneNumber {
          ProfileRow(
            icon: "phone.fill",
            title: "Phone",
            value: phone.id,
            iconColor: .orange
          )
        }
      }
      .background(Color(.systemBackground))
      .cornerRadius(12)
    }
  }

  // MARK: - Preferences Section
  private var preferencesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Preferences")
        .font(.headline)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)

      VStack(spacing: 0) {
        NavigationLink(destination: Text("Notifications Settings")) {
          ProfileActionRow(
            icon: "bell.fill",
            title: "Notifications",
            iconColor: .purple
          )
        }

        Divider()
          .padding(.leading, 52)

        NavigationLink(destination: Text("Shift Preferences")) {
          ProfileActionRow(
            icon: "calendar.badge.clock",
            title: "Shift Preferences",
            iconColor: .indigo
          )
        }

        Divider()
          .padding(.leading, 52)

        NavigationLink(destination: Text("Privacy Settings")) {
          ProfileActionRow(
            icon: "lock.fill",
            title: "Privacy",
            iconColor: .blue
          )
        }
      }
      .background(Color(.systemBackground))
      .cornerRadius(12)
    }
  }

  // MARK: - Support Section
  private var supportSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Support")
        .font(.headline)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)

      VStack(spacing: 0) {
        NavigationLink(destination: Text("Help Center")) {
          ProfileActionRow(
            icon: "questionmark.circle.fill",
            title: "Help Center",
            iconColor: .cyan
          )
        }

        Divider()
          .padding(.leading, 52)

        NavigationLink(destination: Text("Contact Support")) {
          ProfileActionRow(
            icon: "message.fill",
            title: "Contact Support",
            iconColor: .green
          )
        }

        Divider()
          .padding(.leading, 52)

        NavigationLink(destination: Text("About")) {
          ProfileActionRow(
            icon: "info.circle.fill",
            title: "About",
            iconColor: .gray
          )
        }
      }
      .background(Color(.systemBackground))
      .cornerRadius(12)
    }
  }

  // MARK: - Account Actions Section
  private var accountActionsSection: some View {
    VStack(spacing: 12) {
      Button(action: {
        // Sign out action handled by Clerk UserButton
      }) {
        HStack {
          Image(systemName: "rectangle.portrait.and.arrow.right")
            .font(.body.weight(.medium))
          Text("Sign Out")
            .font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .foregroundStyle(.red)
        .cornerRadius(12)
      }

      Text("Version 1.0.0")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
    .padding(.bottom, 32)
  }

  // MARK: - Computed Properties
  private var fullName: String {
    let name = [clerk.user?.firstName, clerk.user?.lastName]
      .compactMap { $0 }
      .joined(separator: " ")
    return name.isEmpty ? "User" : name
  }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
  let icon: String
  let title: String
  let value: String
  let iconColor: Color

  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(iconColor.opacity(0.1))
          .frame(width: 36, height: 36)

        Image(systemName: icon)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(iconColor)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text(value)
          .font(.body)
          .foregroundStyle(.primary)
      }

      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
}

// MARK: - Profile Action Row Component
struct ProfileActionRow: View {
  let icon: String
  let title: String
  let iconColor: Color

  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(iconColor.opacity(0.1))
          .frame(width: 36, height: 36)

        Image(systemName: icon)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(iconColor)
      }

      Text(title)
        .font(.body)
        .foregroundStyle(.primary)

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }
}
