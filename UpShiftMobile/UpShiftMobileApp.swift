//
//  UpShiftMobileApp.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/26/25.
//

import SwiftUI
import SwiftData
import Clerk

@main
struct ClerkQuickstartApp: App {
  @State private var clerk = Clerk.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.clerk, clerk)
        .task {
          clerk.configure(publishableKey: "pk_test_cHJpbWFyeS1tb2xseS04OC5jbGVyay5hY2NvdW50cy5kZXYk")
          try? await clerk.load()
        }
    }
  }
}
