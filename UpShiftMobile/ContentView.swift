import SwiftUI
import Clerk
import Apollo
import UpShiftAPI

struct ContentView: View {
  @Environment(\.clerk) private var clerk
  @State private var authIsPresented = false
  @State private var selectedTab = 0

  var body: some View {
      if clerk.user != nil{
          NaivigatorView(clerk: clerk)
      }else{
          SignInUpView(clerk: clerk, authIsPresented: $authIsPresented)
    }
  }
}

// MARK: - Home View
struct SignInUpView: View {
  var clerk: Clerk
  @Binding var authIsPresented: Bool
  
  var body: some View {
    ZStack {
      // Gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.4, green: 0.2, blue: 0.9),
          Color(red: 0.8, green: 0.3, blue: 0.7),
          Color(red: 1.0, green: 0.5, blue: 0.4)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      
      // Animated circles for visual interest
      GeometryReader { geometry in
        Circle()
          .fill(Color.white.opacity(0.1))
          .frame(width: 300, height: 300)
          .offset(x: -100, y: -150)
          .blur(radius: 40)
        
        Circle()
          .fill(Color.white.opacity(0.15))
          .frame(width: 250, height: 250)
          .offset(x: geometry.size.width - 150, y: geometry.size.height - 100)
          .blur(radius: 30)
        
        Circle()
          .fill(Color.white.opacity(0.08))
          .frame(width: 200, height: 200)
          .offset(x: geometry.size.width / 2 - 100, y: geometry.size.height / 2 - 100)
          .blur(radius: 20)
      }
      
      // Content
      VStack {
        Spacer()
        
        Spacer()
        
        // Sign in button at the bottom
        Button {
          authIsPresented = true
        } label: {
          Text("Get Started")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.9))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 60)
      }
    }
    .sheet(isPresented: $authIsPresented) {
      AuthView()
    }
  }
}

struct NaivigatorView: View{
    var clerk: Clerk
    @State private var selectedTab = 0
    @State private var authIsPresented = false

    
    var body: some View {
        
        TabView(selection: $selectedTab) {
          
          // My Schedule Tab
          MySchedule(clerk: clerk)
            .tabItem {
              Label("Schedule", systemImage: "calendar")
            }
            .tag(0)
          
          // Explore Tab
          AvaliableShifts()
            .tabItem {
              Label("Claim Shifts", systemImage: "magnifyingglass")
            }
            .tag(1)

          // Today Tab
          TodayView(clerk: clerk)
            .tabItem {
              Label("Today", systemImage: "checkmark.circle")
            }
            .tag(2)

          // Time & Earnings Tab
          TimeAndEarnings(clerk: clerk)
            .tabItem {
              Label("Earnings", systemImage: "dollarsign.circle")
            }
            .tag(3)

          // Profile Tab
          ProfileView(clerk: clerk)
            .tabItem {
              Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        
        
        
    }
}

