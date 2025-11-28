import SwiftUI

struct AvaliableShifts: View {
  var body: some View {
    NavigationStack {
      VStack {
        Image(systemName: "magnifyingglass.circle.fill")
          .font(.system(size: 60))
          .foregroundStyle(.blue)
        
        Text("Explore")
          .font(.title)
          .padding()
        
        Text("Discover new content here")
          .foregroundStyle(.secondary)
      }
      .navigationTitle("Explore")
    }
  }
}
