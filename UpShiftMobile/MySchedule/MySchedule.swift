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
import SwiftUIIntrospect

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
    
    private var calendarHeight: CGFloat {
      let now = Date()
      let components = calendar.dateComponents([.year, .month], from: now)
      guard let startDate = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: startDate),
            let firstWeekday = calendar.dateComponents([.weekday], from: startDate).weekday else {
        return 400
      }
      
      let daysInMonth = range.count
      let offset = firstWeekday - calendar.firstWeekday
      let totalCells = daysInMonth + offset
      let numberOfWeeks = ceil(Double(totalCells) / 7.0)
      
      // Base calculation:
      // - Month header: ~40
      // - Days of week header: ~40
      // - Each week row: ~50 (day circle + indicator dot + spacing)
      // - Padding: ~40
      let estimatedHeight = 40 + 40 + (numberOfWeeks * 50)
      
      return estimatedHeight
    }
  
  var body: some View {
    NavigationStack {
      if clerk.user != nil {
        authenticatedView
      }
    }
  }

  // MARK: - Authenticated View

  private var authenticatedView: some View {
    VStack(spacing: 0) {
      headerView
      Divider()
      scrollContent
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadShifts()
    }
  }

  private var headerView: some View {
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
  }

  private var scrollContent: some View {
    ScrollView {
      VStack(spacing: 16) {
        calendarView
        shiftsContentView
      }
    }
  }

  private var calendarView: some View {
    CalendarViewRepresentable(
      calendar: calendar,
      visibleDateRange: calendarVisibleDateRange,
      monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
      dataDependency: selectedDate
    )
    .days { day in
      dayView(for: day)
    }
    .onDaySelection { day in
      if let dayDate = calendar.date(from: day.components) {
        selectedDate = dayDate
      }
    }
    .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26)) { scrollView in
      scrollView.isScrollEnabled = false
    }
    .frame(height: calendarHeight)
    .padding(.horizontal)
    .padding(.vertical)
  }

  private func dayView(for day: DayComponents) -> some View {
    let dayDate = calendar.date(from: day.components) ?? Date()
    return DayView(
      day: day,
      isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate),
      hasShifts: viewModel.hasClaimedShiftForDate(for: dayDate)
    )
  }

  private var shiftsContentView: some View {
    VStack(alignment: .leading, spacing: 12) {
      shiftsHeaderView
      shiftsBodyView
    }
    .padding()
  }

  private var shiftsHeaderView: some View {
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
  }

  @ViewBuilder
  private var shiftsBodyView: some View {
    if viewModel.isLoading {
      loadingView
    } else if let error = viewModel.errorMessage {
      errorView(error)
    } else {
      shiftsListView
    }
  }

  private var loadingView: some View {
    ProgressView()
      .frame(maxWidth: .infinity)
      .padding()
  }

  private func errorView(_ error: String) -> some View {
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
  }

  @ViewBuilder
  private var shiftsListView: some View {
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

    if myShiftsToday.isEmpty {
      Text("No shifts scheduled")
        .foregroundStyle(.secondary)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
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
