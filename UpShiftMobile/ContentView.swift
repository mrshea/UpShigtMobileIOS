import SwiftUI
import Clerk
import Apollo
import UpShiftAPI

struct ContentView: View {
  @Environment(\.clerk) private var clerk
  @State private var authIsPresented = false
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      // Home Tab
      HomeView(clerk: clerk, authIsPresented: $authIsPresented)
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }
        .tag(0)
      
      // My Schedule Tab
      MySchedule(clerk: clerk, authIsPresented: $authIsPresented)
        .tabItem {
          Label("Schedule", systemImage: "calendar")
        }
        .tag(1)
      
      // Explore Tab
      AvaliableShifts()
        .tabItem {
          Label("Claim Shifts", systemImage: "magnifyingglass")
        }
        .tag(2)
      
      // Profile Tab
      ProfileView(clerk: clerk, authIsPresented: $authIsPresented)
        .tabItem {
          Label("Profile", systemImage: "person.fill")
        }
        .tag(3)
    }
    .sheet(isPresented: $authIsPresented) {
      AuthView()
    }
  }
}

// MARK: - Home View
struct HomeView: View {
  var clerk: Clerk
  @Binding var authIsPresented: Bool
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        if clerk.user != nil {
          Text("Welcome, \(clerk.user?.firstName ?? "User")!")
            .font(.title)
          
          UserButton()
            .frame(width: 36, height: 36)
            
            Button("Query"){
                Network.shared.apollo.fetch(query: GetMyShiftsQuery()) { result in
                    switch result {
                    case .success(let graphQLResult):
                        print("Success! Result: \(graphQLResult)")
                    case .failure(let error):
                        print("Failure! Error: \(error)")
                    }
                }
            }
        } else {
          Text("Welcome!")
            .font(.title)
          
          Button("Sign in") {
            authIsPresented = true
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .navigationTitle("Home")
    }
  }
}

// MARK: - Explore View
struct ExploreView: View {
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
