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
      HeaderView(title: "My Schedule")
      Divider()
      CalendarView(
          calendar: calendar,
          visibleDateRange: calendarVisibleDateRange,
          calendarHeight: calendarHeight,
          selectedDate: $selectedDate,
          hasShifts: viewModel.hasClaimedShiftForDate
        )
      shiftsContentView
      Spacer()
    }
    .task {
      await loadShifts()
    }
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
        ScrollView{
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
    }
  
  // MARK: - Helper Methods
  
  private func loadShifts(useCache: Bool = true) async {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
      return
    }
    
    let startDate = weekInterval.start
    let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? weekInterval.end
    
    // Fetch shifts with caching - will show cached data first, then update with fresh data
    await viewModel.fetchShifts(startDate: startDate, endDate: endDate, useCache: useCache)
    await viewModel.fetchMyShifts(useCache: useCache)
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
            Text(claim.shift.timeRangeFormatted)
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

