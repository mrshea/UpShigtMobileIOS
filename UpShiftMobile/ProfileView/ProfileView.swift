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
  @Binding var authIsPresented: Bool
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        if clerk.user != nil {
          Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .foregroundStyle(.blue)
          
          Text([clerk.user?.firstName, clerk.user?.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .isEmpty ? "User" : [clerk.user?.firstName, clerk.user?.lastName]
              .compactMap { $0 }
              .joined(separator: " "))
            .font(.title2)
          
          if let email = clerk.user?.primaryEmailAddress {
              Text(email.id)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          
          UserButton()
            .frame(width: 36, height: 36)
            .padding(.top)
        } else {
          Image(systemName: "person.circle")
            .font(.system(size: 80))
            .foregroundStyle(.gray)
          
          Text("Not signed in")
            .font(.title2)
          
          Button("Sign in") {
            authIsPresented = true
          }
          .buttonStyle(.borderedProminent)
          .padding(.top)
        }
      }
      .navigationTitle("Profile")
    }
  }
}
