//
//  HeaderView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/9/26.
//

import SwiftUI
import Clerk

struct HeaderView: View {
  let title: String
  
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text(title)
          .font(.largeTitle)
          .fontWeight(.bold)

        Spacer()

        UserButton()
          .frame(width: 36, height: 36)
      }
      .padding(.horizontal)
      .padding(.top)
    }
    .background(Color(uiColor: .systemBackground))
  }
}
#Preview {
  HeaderView(title: "My Schedule")
}

