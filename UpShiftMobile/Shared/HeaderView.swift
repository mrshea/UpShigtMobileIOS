//
//  HeaderView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/9/26.
//

import SwiftUI
import Clerk

struct HeaderView<Trailing: View>: View {
  let title: String
  let trailing: Trailing

  init(title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        Text(title)
          .font(.largeTitle)
          .fontWeight(.bold)

        Spacer()

        trailing
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
