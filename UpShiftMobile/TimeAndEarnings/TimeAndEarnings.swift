//
//  TimeAndEarnings.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

import SwiftUI
import Clerk

struct TimeAndEarnings: View {
  var clerk: Clerk
  @Binding var authIsPresented: Bool
  @StateObject private var viewModel = TimeAndEarningsViewModel()
  @Environment(\.calendar) var calendar
  @State private var selectedWeekStart: Date = Date().startOfWeek

  var body: some View {
    NavigationStack {
      if clerk.user != nil {
        authenticatedView
      } else {
        unauthenticatedView
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
      await loadWeekData()
    }
    .onChange(of: selectedWeekStart) { _, _ in
      Task {
        await loadWeekData()
      }
    }
  }

  private var headerView: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Time & Earnings")
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
        weekNavigationView
        weekSummaryCard
        shiftsListView
      }
      .padding()
    }
  }

  // MARK: - Week Navigation

  private var weekNavigationView: some View {
    HStack {
      Button(action: previousWeek) {
        Image(systemName: "chevron.left")
          .font(.title3)
          .foregroundStyle(.blue)
      }

      Spacer()

      VStack(spacing: 2) {
        Text(weekRangeText)
          .font(.headline)

        if calendar.isDate(selectedWeekStart, equalTo: Date().startOfWeek, toGranularity: .day) {
          Text("Current Week")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Button(action: nextWeek) {
        Image(systemName: "chevron.right")
          .font(.title3)
          .foregroundStyle(isCurrentWeek ? .gray : .blue)
      }
      .disabled(isCurrentWeek)
    }
    .padding(.vertical, 8)
  }

  private var weekRangeText: String {
    let endDate = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"

    let startString = formatter.string(from: selectedWeekStart)
    let endString = formatter.string(from: endDate)

    let startMonth = calendar.component(.month, from: selectedWeekStart)
    let endMonth = calendar.component(.month, from: endDate)

    if startMonth == endMonth {
      formatter.dateFormat = "d"
      let endDay = formatter.string(from: endDate)
      return "\(startString) - \(endDay)"
    } else {
      return "\(startString) - \(endString)"
    }
  }

  private var isCurrentWeek: Bool {
    calendar.isDate(selectedWeekStart, equalTo: Date().startOfWeek, toGranularity: .day)
  }

  private func previousWeek() {
    if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) {
      selectedWeekStart = newDate
    }
  }

  private func nextWeek() {
    guard !isCurrentWeek else { return }
    if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) {
      selectedWeekStart = newDate
    }
  }

  // MARK: - Week Summary Card

  private var weekSummaryCard: some View {
    VStack(spacing: 16) {
      if viewModel.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else if let error = viewModel.errorMessage {
        errorView(error)
      } else {
        summaryContent
      }
    }
    .padding()
    .background(Color(uiColor: .secondarySystemBackground))
    .cornerRadius(12)
  }

  private var summaryContent: some View {
    VStack(spacing: 16) {
      HStack {
        summaryItem(
          title: "Hours Worked",
          value: String(format: "%.1f", viewModel.weekSummary.totalHours),
          icon: "clock.fill",
          color: .blue
        )

        Divider()
          .frame(height: 60)

        summaryItem(
          title: "Shifts",
          value: "\(viewModel.weekSummary.shiftsCount)",
          icon: "calendar",
          color: .green
        )
      }

      Divider()

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Label("Projected Pay", systemImage: "dollarsign.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Text("$\(String(format: "%.2f", viewModel.weekSummary.projectedPay))")
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(.primary)
        }

        Spacer()

        if viewModel.weekSummary.shiftsCount > 0 {
          VStack(alignment: .trailing, spacing: 4) {
            Text("Avg. Rate")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text("$\(String(format: "%.2f", viewModel.weekSummary.averageHourlyRate))/hr")
              .font(.subheadline)
              .fontWeight(.semibold)
          }
        }
      }
    }
  }

  private func summaryItem(title: String, value: String, icon: String, color: Color) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(color)

      Text(value)
        .font(.system(size: 28, weight: .bold))

      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  private func errorView(_ error: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 32))
        .foregroundStyle(.orange)

      Text("Error loading data")
        .font(.headline)

      Text(error)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task { await loadWeekData() }
      }
      .buttonStyle(.bordered)
    }
  }

  // MARK: - Shifts List

  @ViewBuilder
  private var shiftsListView: some View {
    if viewModel.isLoading {
      EmptyView()
    } else if viewModel.weekShifts.isEmpty {
      emptyStateView
    } else {
      VStack(alignment: .leading, spacing: 12) {
        Text("Completed Shifts")
          .font(.headline)
          .padding(.horizontal, 4)

        ForEach(viewModel.weekShifts) { shift in
          CompletedShiftCard(shift: shift)
        }
      }
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 12) {
      Image(systemName: "calendar.badge.clock")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("No shifts this week")
        .font(.headline)

      Text("Completed shifts will appear here")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .background(Color(uiColor: .secondarySystemBackground))
    .cornerRadius(12)
  }

  // MARK: - Unauthenticated View

  private var unauthenticatedView: some View {
    VStack(spacing: 20) {
      Text("Sign in to view your earnings")
        .font(.title2)

      Button("Sign In") {
        authIsPresented = true
      }
      .buttonStyle(.borderedProminent)
    }
  }

  // MARK: - Helper Methods

  private func loadWeekData() async {
    let weekEnd = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart
    await viewModel.fetchWeekData(startDate: selectedWeekStart, endDate: weekEnd)
  }
}

// MARK: - Completed Shift Card

struct CompletedShiftCard: View {
  let shift: CompletedShift

  var body: some View {
    HStack(spacing: 12) {
      VStack(spacing: 4) {
        Text(dayOfWeek)
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(dayNumber)
          .font(.title3)
          .fontWeight(.bold)
      }
      .frame(width: 44)

      VStack(alignment: .leading, spacing: 4) {
        Text(shift.role)
          .font(.headline)

        HStack(spacing: 12) {
          Label(shift.timeRange, systemImage: "clock")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Label(shift.hoursWorked, systemImage: "hourglass")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        Text("$\(String(format: "%.2f", shift.pay))")
          .font(.headline)
          .foregroundStyle(.green)

        Text("$\(String(format: "%.2f", shift.hourlyRate))/hr")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(uiColor: .secondarySystemBackground))
    .cornerRadius(10)
  }

  private var dayOfWeek: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: shift.date).uppercased()
  }

  private var dayNumber: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: shift.date)
  }
}

// MARK: - Date Extension

extension Date {
  var startOfWeek: Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
    return calendar.date(from: components) ?? self
  }
}
