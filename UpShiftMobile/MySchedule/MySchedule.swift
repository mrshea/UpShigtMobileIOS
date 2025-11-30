//
//  MySchedule.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/26/25.
//
import SwiftUI
import Foundation
import Clerk
import HorizonCalendar

struct MySchedule: View {
  var clerk: Clerk
  @Binding var authIsPresented: Bool
  @State private var selectedDate = Date()
  @StateObject private var viewModel = ShiftViewModel()
  @Environment(\.calendar) var calendar
  
  // Calendar visible date range (current month - 1 to + 2 months)
    private var calendarVisibleDateRange: ClosedRange<Date> {
        let now = Date()
        
        // First day of current month at 00:00:00
        let components = calendar.dateComponents([.year, .month], from: now)
        let startDate = calendar.date(from: components) ?? now
        
        // Last day of current month at 23:59:59
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? now
        let lastDay = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? now
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastDay) ?? now
        
        return startDate...endDate
    }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if clerk.user != nil {
          // User info header
          VStack(spacing: 12) {
            HStack {
              Text("My Schedule")
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
        
          
          Divider()
          
          // Week calendar view
          ScrollView {
            VStack(spacing: 16) {
              // HorizonCalendar view
              CalendarViewRepresentable(
                calendar: calendar,
                visibleDateRange: calendarVisibleDateRange,
                monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                dataDependency: selectedDate
              )
              .days { day in
                let dayDate = calendar.date(from: day.components) ?? Date()
                DayView(
                  day: day,
                  isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate),
                  hasShifts: viewModel.hasShifts(for: dayDate)
                )
              }
              .onDaySelection { day in
                if let dayDate = calendar.date(from: day.components) {
                  selectedDate = dayDate
                }
              }
              .frame(height: 350)
              .padding(.horizontal)
              
              // Schedule content for selected date
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text(selectedDate, style: .date)
                    .font(.headline)
                  
                  Spacer()
                  
                  Button(action: { Task { await loadShifts() } }) {
                    Image(systemName: "arrow.clockwise")
                      .foregroundStyle(.blue)
                  }
                  .disabled(viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                  ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if let error = viewModel.errorMessage {
                  VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                      .font(.system(size: 40))
                      .foregroundStyle(.orange)
                    
                    Text("Error loading shifts")
                      .font(.headline)
                    
                    Text(error)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                      .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                      Task { await loadShifts() }
                    }
                    .buttonStyle(.bordered)
                  }
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(Color(uiColor: .secondarySystemBackground))
                  .cornerRadius(10)
                } else {
                  // My claimed shifts
                  let myShiftsToday = viewModel.myShiftsForDate(selectedDate)
                  
                  if !myShiftsToday.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                      Text("My Shifts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                      
                      ForEach(myShiftsToday) { claim in
                        MyShiftCard(claim: claim) {
                          Task {
                            do {
                              try await viewModel.unclaimShift(shiftId: claim.shiftId)
                              await loadShifts()
                            } catch {
                              viewModel.errorMessage = error.localizedDescription
                            }
                          }
                        }
                      }
                    }
                  }
                  
                  // Available shifts
                  let availableShifts = viewModel.shiftsForDate(selectedDate)
                  
                  if !availableShifts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                      Text("Available Shifts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.top, myShiftsToday.isEmpty ? 0 : 16)
                      
                      ForEach(availableShifts) { shift in
                        ShiftCard(shift: shift) {
                          Task {
                            do {
                              try await viewModel.claimShift(shiftId: shift.id)
                              await loadShifts()
                            } catch {
                              viewModel.errorMessage = error.localizedDescription
                            }
                          }
                        }
                      }
                    }
                  }
                  
                  if myShiftsToday.isEmpty && availableShifts.isEmpty {
                    Text("No shifts scheduled")
                      .foregroundStyle(.secondary)
                      .padding()
                      .frame(maxWidth: .infinity)
                      .background(Color(uiColor: .secondarySystemBackground))
                      .cornerRadius(10)
                  }
                }
              }
              .padding()
            }
          }
        } else {
          // Not signed in state
          VStack(spacing: 20) {
            Image(systemName: "calendar")
              .font(.system(size: 60))
              .foregroundStyle(.gray)
            
            Text("Sign in to view your schedule")
              .font(.title2)
            
            Button("Sign in") {
              authIsPresented = true
            }
            .buttonStyle(.borderedProminent)
          }
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        if clerk.user != nil {
          await loadShifts()
        }
      }
      .onChange(of: selectedDate) {
        Task {
          await loadShifts()
        }
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func loadShifts() async {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
      return
    }
    
    let startDate = weekInterval.start
    let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? weekInterval.end
    
    await viewModel.fetchShifts(startDate: startDate, endDate: endDate)
    await viewModel.fetchMyShifts()
  }
}

// MARK: - Week Navigation View
struct WeekNavigationView: View {
  @Binding var selectedDate: Date
  @Environment(\.calendar) var calendar
  
  var body: some View {
    HStack {
      Button(action: previousWeek) {
        Image(systemName: "chevron.left")
          .font(.title3)
          .foregroundStyle(.blue)
      }
      
      Spacer()
      
      Text(weekRangeText)
        .font(.headline)
      
      Spacer()
      
      Button(action: nextWeek) {
        Image(systemName: "chevron.right")
          .font(.title3)
          .foregroundStyle(.blue)
      }
    }
    .padding(.vertical, 8)
  }
  
  private var weekRangeText: String {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
      return ""
    }
    
    let startDate = weekInterval.start
    let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? weekInterval.end
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    
    let startString = formatter.string(from: startDate)
    let endString = formatter.string(from: endDate)
    
    // Check if dates are in the same month
    let startMonth = calendar.component(.month, from: startDate)
    let endMonth = calendar.component(.month, from: endDate)
    
    if startMonth == endMonth {
      formatter.dateFormat = "d"
      let endDay = formatter.string(from: endDate)
      formatter.dateFormat = "MMM d"
      let startFormatted = formatter.string(from: startDate)
      return "\(startFormatted) - \(endDay)"
    } else {
      return "\(startString) - \(endString)"
    }
  }
  
  private func previousWeek() {
    if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
      selectedDate = newDate
    }
  }
  
  private func nextWeek() {
    if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
      selectedDate = newDate
    }
  }
}

// MARK: - Shift Cards

struct ShiftCard: View {
  let shift: Shift
  let onClaim: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(shift.role)
            .font(.headline)
          
          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.caption)
            Text("\(shift.startTime) - \(shift.endTime)")
              .font(.subheadline)
          }
          .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
          if shift.isFull {
            Text("Full")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.white)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.red)
              .cornerRadius(4)
          } else {
            Text("\(shift.availableSpots) spots")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            Button(action: onClaim) {
              Text("Claim")
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
          }
        }
      }
      
      if let claimedBy = shift.claimedBy, !claimedBy.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "person.2")
            .font(.caption2)
          Text("\(claimedBy.count) claimed")
            .font(.caption2)
        }
        .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(uiColor: .secondarySystemBackground))
    .cornerRadius(10)
  }
}

struct MyShiftCard: View {
  let claim: MyShiftClaim
  let onUnclaim: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(claim.shift.role)
              .font(.headline)
            
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
              .font(.subheadline)
          }
          
          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.caption)
            Text("\(claim.shift.startTime) - \(claim.shift.endTime)")
              .font(.subheadline)
          }
          .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        Button(action: onUnclaim) {
          Text("Cancel")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.red)
      }
      
      HStack(spacing: 4) {
        Image(systemName: "calendar.badge.clock")
          .font(.caption2)
        Text("Claimed \(claim.claimedAt, style: .relative) ago")
          .font(.caption2)
      }
      .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.green.opacity(0.1))
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.green.opacity(0.3), lineWidth: 1)
    )
    .cornerRadius(10)
  }
}

// MARK: - Custom Calendar Day View

struct DayView: View {
  let day: DayComponents
  let isSelected: Bool
  let hasShifts: Bool
  @Environment(\.calendar) var calendar
  
  private var dayDate: Date {
    calendar.date(from: day.components) ?? Date()
  }
  
  var body: some View {
    VStack(spacing: 4) {
      Text("\(day.day)")
        .font(.system(size: 18))
        .fontWeight(isSelected ? .bold : .regular)
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(width: 36, height: 36)
        .background(
          Circle()
            .fill(isSelected ? Color.blue : Color.clear)
        )
      
      // Indicator dot for days with shifts
      if hasShifts {
        Circle()
          .fill(isSelected ? .white : .blue)
          .frame(width: 4, height: 4)
      } else {
        Circle()
          .fill(.clear)
          .frame(width: 4, height: 4)
      }
    }
  }
}
