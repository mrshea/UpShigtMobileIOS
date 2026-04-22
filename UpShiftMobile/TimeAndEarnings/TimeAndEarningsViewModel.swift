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
import Clerk

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
    dateFormatter.dateFormat = "HH:mm" // 24-hour format

    guard let start = dateFormatter.date(from: startTime) else {
        return 0
      }
            
    guard let end = dateFormatter.date(from: endTime) else {
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

  // Pay period state
  @Published var payPeriodConfig: PayPeriodConfig?
  @Published var payPeriod: PayPeriod?
  @Published var periodOffset: Int = 0
  @Published var isConfigured: Bool = true
  @Published var isLoadingConfig: Bool = false

  private let apolloClient = Network.shared.apollo
  private let clerk: Clerk
  private let defaultHourlyRate: Double = 15.0 // Fallback rate if not found in metadata

  init(clerk: Clerk) {
    self.clerk = clerk
  }

  // MARK: - Pay Period Config

  func loadPayPeriodConfig() async {
    isLoadingConfig = true
    defer { isLoadingConfig = false }
    do {
      let response = try await APIClient.shared.get(
        "/api/pay-period-config",
        as: APIResponse<PayPeriodConfig>.self
      )
      if let config = response.data {
        self.payPeriodConfig = config
        self.isConfigured = true
        recomputePeriod()
      } else {
        self.payPeriodConfig = nil
        self.payPeriod = nil
        self.isConfigured = false
      }
    } catch {
      print("Failed to load pay period config: \(error)")
      self.errorMessage = error.localizedDescription
      self.isConfigured = false
    }
  }

  func recomputePeriod() {
    guard let config = payPeriodConfig else {
      payPeriod = nil
      return
    }
    payPeriod = PayPeriodCalculator.period(for: config, offset: periodOffset)
  }

  func goToPreviousPeriod() {
    periodOffset -= 1
    recomputePeriod()
  }

  func goToNextPeriod() {
    guard periodOffset < 0 else { return }
    periodOffset += 1
    recomputePeriod()
  }

  var isCurrentPeriod: Bool { periodOffset == 0 }

  // Get hourly rate from Clerk user metadata (public so view can display it)
  var currentHourlyRate: Double {
    // Try to get payPerHour from publicMetadata
    if let publicMetadata = clerk.user?.publicMetadata,
       let payPerHourJSON = publicMetadata["payPerHour"] {

      // Handle Clerk.JSON type - it can be .number, .string, etc.
      switch payPerHourJSON {
          case .number(let value):
            // Direct number value
            return value

          case .string(let stringValue):
            // If it's stored as a string, try to convert
            if let doubleValue = Double(stringValue) {
              return doubleValue
            }

          default:
            break
      }
    }
    // Return default if not found or conversion failed
    return defaultHourlyRate
  }

  // MARK: - Fetch Week Data

  func fetchWeekData(startDate: Date, endDate: Date, useCache: Bool = true) async {
    // Only show loading on first load (when cache is empty)
    if weekShifts.isEmpty {
      isLoading = true
    }
    errorMessage = nil

    do {
      // Fetch my shifts from the API
      let query = GetMyShiftsQuery()

      if useCache {
        // Use cache and network: returns cache first, then network
        for try await result in try apolloClient.fetch(
          query: query,
          cachePolicy: .cacheAndNetwork
        ) {
          if let data = result.data {
            processShiftsData(data: data, startDate: startDate, endDate: endDate)
          }
        }
      } else {
        // Network only: skip cache
        let result = try await apolloClient.fetch(
          query: query,
          cachePolicy: .networkOnly
        )
        
        if let data = result.data {
          processShiftsData(data: data, startDate: startDate, endDate: endDate)
        }
      }
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching week data: \(error)")
      weekShifts = []
      weekSummary = .empty
    }

    isLoading = false
  }
  
  // MARK: - Process Shifts Data
  
  private func processShiftsData(data: GetMyShiftsQuery.Data, startDate: Date, endDate: Date) {
    // Filter shifts that fall within the week and are in the past
    let now = Date()

    let completedShifts = data.myShifts.compactMap { myShift -> CompletedShift? in
      guard let shiftDate = myShift.shift.date.toDate(),
            let startTime = myShift.shift.startTime.toDate(),
            let endTime = myShift.shift.endTime.toDate() else {
        print("Failed to parse dates for shift: \(myShift.id)")
        return nil
      }

      // Only include shifts that:
      // 1. Are within the selected period range (end is exclusive)
      // 2. Are in the past (completed)
      guard shiftDate >= startDate,
            shiftDate < endDate,
            shiftDate < now else {
        return nil
      }
      
      // Get department name, fallback to "Unknown"
      let departmentName = myShift.shift.department?.name ?? "Unknown"
      
      // Format times to HH:mm
      let timeFormatter = DateFormatter()
      timeFormatter.dateFormat = "HH:mm"
      let startTimeString = timeFormatter.string(from: startTime)
      let endTimeString = timeFormatter.string(from: endTime)

      return CompletedShift(
        id: myShift.id,
        date: shiftDate,
        startTime: startTimeString,
        endTime: endTimeString,
        role: departmentName,
        hourlyRate: self.currentHourlyRate
      )
    }

    // Sort by date (most recent first)
    self.weekShifts = completedShifts.sorted { $0.date > $1.date }

    // Calculate week summary
    calculateWeekSummary()

    errorMessage = nil
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
