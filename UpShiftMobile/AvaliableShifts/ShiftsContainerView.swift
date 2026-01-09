//
//  ShiftsContainerView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/19/25.
//

import SwiftUI

struct ShiftsContainerView: View {
  @State private var selectedView: ViewSelection = .availableShifts
  @Namespace private var namespace
  
  enum ViewSelection: String, CaseIterable, Identifiable {
    case availableShifts = "Available Shifts"
    case timeOff = "Time Off"
    
    var id: String { rawValue }
    
    var icon: String {
      switch self {
      case .availableShifts:
        return "calendar.badge.plus"
      case .timeOff:
        return "calendar.badge.clock"
      }
    }
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Native iOS Segmented Control - Built-in!
        Picker("View", selection: $selectedView) {
          ForEach(ViewSelection.allCases) { view in
            Text(view.rawValue)
              .tag(view)
          }
        }
        .pickerStyle(.segmented)
        .padding()
        
        Divider()
        
        // Content with smooth transitions
        Group {
          switch selectedView {
          case .availableShifts:
            AvaliableShifts()
              .transition(.opacity)
          case .timeOff:
            TimeOffView()
              .transition(.opacity)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview {
  ShiftsContainerView()
}
