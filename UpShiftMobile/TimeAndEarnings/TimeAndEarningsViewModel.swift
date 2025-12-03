//
//  TimeAndEarningsViewModel.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

import Foundation
import Combine
import Apollo
import UpShiftAPI

// MARK: - Completed Shift Model

struct CompletedShift: Identifiable, Codable {
  let id: String
  let date: Date
  let startTime: String
  let endTime: String
  let role: String
  let hourlyRate: Double

  var hoursWorked: String {
    let hours = calculateHours()
    return String(format: "%.1fh", hours)
  }

  var timeRange: String {
    "\(startTime) - \(endTime)"
  }

  var pay: Double {
    calculateHours() * hourlyRate
  }

  func calculateHours() -> Double {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"

    guard let start = dateFormatter.date(from: startTime),
          let end = dateFormatter.date(from: endTime) else {
      return 0
    }

    let diff = end.timeIntervalSince(start)
    return diff / 3600 // Convert seconds to hours
  }
}

// MARK: - Week Summary Model

struct WeekSummary {
  let totalHours: Double
  let projectedPay: Double
  let shiftsCount: Int

  var averageHourlyRate: Double {
    guard totalHours > 0 else { return 0 }
    return projectedPay / totalHours
  }

  static var empty: WeekSummary {
    WeekSummary(totalHours: 0, projectedPay: 0, shiftsCount: 0)
  }
}

// MARK: - View Model

@MainActor
class TimeAndEarningsViewModel: ObservableObject {
  @Published var weekShifts: [CompletedShift] = []
  @Published var weekSummary: WeekSummary = .empty
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let apolloClient = Network.shared.apollo
  private let defaultHourlyRate: Double = 15.0 // Default rate, can be configured

  // MARK: - Fetch Week Data

  func fetchWeekData(startDate: Date, endDate: Date) async {
    isLoading = true
    errorMessage = nil

    do {
      // Fetch my shifts from the API
      let query = GetMyShiftsQuery()

      let result = try await withCheckedThrowingContinuation { continuation in
        apolloClient.fetch(
          query: query,
          cachePolicy: .fetchIgnoringCacheData
        ) { result in
          continuation.resume(with: result)
        }
      }

      if let data = result.data {
        // Filter shifts that fall within the week and are in the past
        let now = Date()
        let calendar = Calendar.current

        let completedShifts = data.myShifts.compactMap { myShift -> CompletedShift? in
          guard let shiftDate = myShift.shift.date.toDate() else {
            return nil
          }

          // Only include shifts that:
          // 1. Are within the selected week range
          // 2. Are in the past (completed)
          guard shiftDate >= startDate,
                shiftDate <= endDate,
                shiftDate < now else {
            return nil
          }

          return CompletedShift(
            id: myShift.id,
            date: shiftDate,
            startTime: myShift.shift.startTime,
            endTime: myShift.shift.endTime,
            role: myShift.shift.role,
            hourlyRate: defaultHourlyRate
          )
        }

        // Sort by date (most recent first)
        self.weekShifts = completedShifts.sorted { $0.date > $1.date }

        // Calculate week summary
        calculateWeekSummary()

        errorMessage = nil
      }
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching week data: \(error)")
      weekShifts = []
      weekSummary = .empty
    }

    isLoading = false
  }

  // MARK: - Calculate Summary

  private func calculateWeekSummary() {
    let totalHours = weekShifts.reduce(0.0) { sum, shift in
      sum + shift.calculateHours()
    }

    let totalPay = weekShifts.reduce(0.0) { sum, shift in
      sum + shift.pay
    }

    weekSummary = WeekSummary(
      totalHours: totalHours,
      projectedPay: totalPay,
      shiftsCount: weekShifts.count
    )
  }
}
