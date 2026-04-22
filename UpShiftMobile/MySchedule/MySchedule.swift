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
  @StateObject private var dropShiftViewModel = DropShiftViewModel()
  @State private var showDropRequestSheet: DropRequestSheetID?
  @State private var dropRequestNotes: String = ""
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
      calendarView
      shiftsContentView
      Spacer()
    }
    .task {
      await loadShifts()
      await dropShiftViewModel.loadRequests()
    }
    .sheet(item: $showDropRequestSheet) { sheet in
      VStack(spacing: 16) {
        Text("Request to Drop Shift")
          .font(.headline)
        TextField("Reason (optional)", text: $dropRequestNotes)
          .textFieldStyle(.roundedBorder)
          .frame(minHeight: 44)
        HStack {
          Button("Cancel") {
            showDropRequestSheet = nil
            dropRequestNotes = ""
          }
          Spacer()
          Button("Submit") {
            let shiftId = sheet.shiftId
            let notes = dropRequestNotes
            Task {
              await dropShiftViewModel.submitRequest(shiftId: shiftId, employeeNotes: notes.isEmpty ? nil : notes)
              showDropRequestSheet = nil
              dropRequestNotes = ""
            }
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
      .presentationDetents([.height(220)])
    }
  }



//  private var scrollContent: some View {
//    ScrollView {
//      VStack(spacing: 16) {
//        shiftsContentView
//      }
//    }
//  }

  private var calendarView: some View {
    CalendarView(
      calendar: calendar,
      visibleDateRange: calendarVisibleDateRange,
      calendarHeight: calendarHeight,
      selectedDate: $selectedDate,
      hasShifts: viewModel.hasClaimedShiftForDate,
      shiftsCount: viewModel.myShifts.count // Pass shifts count to trigger re-render
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
                        // Only consider a pending drop request submitted after the current claim.
                        // Historical approved/denied requests from previous claims are ignored,
                        // so re-claiming a shift resets the button state.
                        let dropRequest = dropShiftViewModel.requests.first {
                            $0.shiftId == claim.shiftId
                            && $0.status == .pending
                            && $0.submittedAt >= claim.claimedAt
                        }
                        MyShiftCard(
                            claim: claim,
                            dropRequest: dropRequest,
                            onRequestDrop: {
                                showDropRequestSheet = DropRequestSheetID(shiftId: claim.shiftId)
                            },
                            onCancelDropRequest: {
                                if let reqId = dropRequest?.id {
                                    Task {
                                        try? await dropShiftViewModel.deleteRequest(id: reqId)
                                    }
                                }
                            }
                        )
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
        .refreshable {
            await refreshShifts()
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

  private func refreshShifts() async {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
      return
    }

    let startDate = weekInterval.start
    let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? weekInterval.end

    // Use the new throttled refresh methods
    await viewModel.refreshShifts(startDate: startDate, endDate: endDate)
    await viewModel.refreshMyShifts()

    // Haptic feedback on successful refresh
    if viewModel.errorMessage == nil {
      HapticManager.shared.notification(type: .success)
    }
  }
}

struct MyShiftCard: View {
  let claim: MyShiftClaim
  let dropRequest: DropShiftRequest?
  let onRequestDrop: () -> Void
  let onCancelDropRequest: () -> Void

  private var hasPendingDropRequest: Bool {
    dropRequest?.status == .pending
  }

  private var buttonLabel: String {
    hasPendingDropRequest ? "Pending Drop Request" : "Request to Drop"
  }

  private var buttonTint: Color {
    hasPendingDropRequest ? .orange : .red
  }

  private func buttonTapped() {
    if hasPendingDropRequest {
      onCancelDropRequest()
    } else {
      onRequestDrop()
    }
  }

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

        Button(action: buttonTapped) {
          Text(buttonLabel)
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(buttonTint)
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

struct DropRequestSheetID: Identifiable {
  let shiftId: String
  var id: String { shiftId }
}
