//
//  TodayViewModel.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

import Foundation
import Combine
import Apollo
import UpShiftAPI
internal import CoreLocation

@MainActor
class TodayViewModel: ObservableObject {
  @Published var todayShifts: [TodayShift] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var locationManager = LocationManager()
  @Published var showLocationPermissionAlert = false
  @Published var showProximityAlert = false
  @Published var proximityAlertMessage: String = ""

  private let apolloClient = Network.shared.apollo

  // MARK: - Fetch Today's Shifts

  func fetchTodayShifts() async {
    isLoading = true
    errorMessage = nil

    do {
      let today = Calendar.current.startOfDay(for: Date())
      let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()

      // Fetch shifts and time entries in parallel
      async let shiftsResult = fetchMyShifts()
      async let timeEntriesResult = fetchMyTimeEntries(startDate: today, endDate: tomorrow)

      let (shifts, timeEntries) = try await (shiftsResult, timeEntriesResult)

      // Create a map of shift ID to time entry
      let timeEntryMap = Dictionary(uniqueKeysWithValues: timeEntries.compactMap { entry in
        entry.shiftId.flatMap { ($0, entry) }
      })

      // Filter to today's shifts only and attach time entries
      let todayShiftClaims = shifts.compactMap { myShift -> TodayShift? in
        guard let shiftDate = myShift.shift.date.toDate() else {
          return nil
        }

        // Only include shifts that are today
        guard shiftDate >= today && shiftDate < tomorrow else {
          return nil
        }

        let myShiftClaim = MyShiftClaim(
          id: myShift.id,
          shiftId: myShift.shiftId,
          claimedAt: myShift.claimedAt.toDate() ?? Date(),
          shift: ShiftDetail(
            id: myShift.shift.id,
            date: shiftDate,
            startTime: myShift.shift.startTime,
            endTime: myShift.shift.endTime,
            role: myShift.shift.role
          )
        )

        // Get the time entry for this shift
        let timeEntry = timeEntryMap[myShift.shiftId]
        let checkInOutRecord = timeEntry.flatMap { convertTimeEntryToRecord($0, shift: myShiftClaim) }

        return TodayShift(
          id: myShift.id,
          shiftClaim: myShiftClaim,
          checkInOutRecord: checkInOutRecord,
          location: nil  // Location would come from shift data if available
        )
      }

      self.todayShifts = todayShiftClaims.sorted { $0.shiftClaim.shift.date < $1.shiftClaim.shift.date }
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching today's shifts: \(error)")
      todayShifts = []
    }

    isLoading = false
  }

  // MARK: - Helper Methods

  private func fetchMyShifts() async throws -> [GetMyShiftsQuery.Data.MyShift] {
    let query = GetMyShiftsQuery()

    let result = try await withCheckedThrowingContinuation { continuation in
      apolloClient.fetch(
        query: query,
        cachePolicy: .fetchIgnoringCacheData
      ) { result in
        continuation.resume(with: result)
      }
    }

    return result.data?.myShifts ?? []
  }

  private func fetchMyTimeEntries(startDate: Date, endDate: Date) async throws -> [GetMyTimeEntriesQuery.Data.MyTimeEntry] {
    let query = GetMyTimeEntriesQuery(
      startDate: .some(startDate.toISO8601String()),
      endDate: .some(endDate.toISO8601String())
    )

    let result = try await withCheckedThrowingContinuation { continuation in
      apolloClient.fetch(
        query: query,
        cachePolicy: .fetchIgnoringCacheData
      ) { result in
        continuation.resume(with: result)
      }
    }

    return result.data?.myTimeEntries ?? []
  }

  private func convertTimeEntryToRecord(
    _ entry: GetMyTimeEntriesQuery.Data.MyTimeEntry,
    shift: MyShiftClaim
  ) -> CheckInOutRecord {
    let checkInTime = entry.clockInTime.toDate()
    let checkOutTime = entry.clockOutTime?.toDate()

    // Calculate scheduled hours
    let scheduledHours = calculateScheduledHours(
      startTime: shift.shift.startTime,
      endTime: shift.shift.endTime
    )

    // Determine status
    let status: CheckInStatus
    if let checkOutTime = checkOutTime {
      status = .completed
    } else if checkInTime != nil {
      status = .checkedIn
    } else {
      status = .notStarted
    }

    // Calculate timing differences
    let (earlyCheckIn, lateCheckIn) = calculateCheckInTiming(
      checkInTime: checkInTime,
      scheduledStart: shift.shift.startTime,
      shiftDate: shift.shift.date
    )

    let (earlyCheckOut, lateCheckOut) = calculateCheckOutTiming(
      checkOutTime: checkOutTime,
      scheduledEnd: shift.shift.endTime,
      shiftDate: shift.shift.date
    )

    // Determine if requires manager approval (early/late by more than 15 minutes)
    let requiresApproval = (lateCheckIn ?? 0) > 15 || (earlyCheckOut ?? 0) > 15

    return CheckInOutRecord(
      id: entry.id,
      shiftClaimId: shift.id,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      checkInLatitude: entry.clockInLatitude,
      checkInLongitude: entry.clockInLongitude,
      checkOutLatitude: entry.clockOutLatitude,
      checkOutLongitude: entry.clockOutLongitude,
      status: status,
      requiresManagerApproval: requiresApproval,
      earlyCheckInMinutes: earlyCheckIn,
      lateCheckInMinutes: lateCheckIn,
      earlyCheckOutMinutes: earlyCheckOut,
      lateCheckOutMinutes: lateCheckOut,
      actualHoursWorked: entry.hoursWorked,
      scheduledHours: scheduledHours
    )
  }

  private func calculateScheduledHours(startTime: String, endTime: String) -> Double {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"

    guard let start = formatter.date(from: startTime),
          let end = formatter.date(from: endTime) else {
      return 0
    }

    let interval = end.timeIntervalSince(start)
    return interval / 3600
  }

  private func calculateCheckInTiming(
    checkInTime: Date?,
    scheduledStart: String,
    shiftDate: Date
  ) -> (early: Int?, late: Int?) {
    guard let checkInTime = checkInTime else {
      return (nil, nil)
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"

    guard let startTime = formatter.date(from: scheduledStart) else {
      return (nil, nil)
    }

    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    guard let scheduledStartDate = calendar.date(from: combined) else {
      return (nil, nil)
    }

    let difference = checkInTime.timeIntervalSince(scheduledStartDate) / 60 // in minutes

    if difference < 0 {
      return (Int(abs(difference)), nil)
    } else if difference > 0 {
      return (nil, Int(difference))
    }

    return (nil, nil)
  }

  private func calculateCheckOutTiming(
    checkOutTime: Date?,
    scheduledEnd: String,
    shiftDate: Date
  ) -> (early: Int?, late: Int?) {
    guard let checkOutTime = checkOutTime else {
      return (nil, nil)
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"

    guard let endTime = formatter.date(from: scheduledEnd) else {
      return (nil, nil)
    }

    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: shiftDate)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: endTime)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    guard let scheduledEndDate = calendar.date(from: combined) else {
      return (nil, nil)
    }

    let difference = checkOutTime.timeIntervalSince(scheduledEndDate) / 60 // in minutes

    if difference < 0 {
      return (Int(abs(difference)), nil)
    } else if difference > 0 {
      return (nil, Int(difference))
    }

    return (nil, nil)
  }

  // MARK: - Check In

  func checkInShift(_ shift: TodayShift) async {
    // Check location authorization first
    if locationManager.authorizationStatus != .authorizedWhenInUse &&
       locationManager.authorizationStatus != .authorizedAlways {
      if locationManager.authorizationStatus == .notDetermined {
        locationManager.requestWhenInUseAuthorization()
        // Wait a moment for the user to respond
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
      }

      if locationManager.authorizationStatus != .authorizedWhenInUse &&
         locationManager.authorizationStatus != .authorizedAlways {
        showLocationPermissionAlert = true
        return
      }
    }

    isLoading = true
    errorMessage = nil

    do {
      // Get current location
      let location = try await locationManager.getCurrentLocation()

      // If shift has a location, verify proximity
      if let shiftLocation = shift.location {
        let verification = locationManager.verifyProximity(
          userLocation: location,
          shiftLocation: shiftLocation
        )

        if !verification.isWithinRadius {
          proximityAlertMessage = "You are \(verification.distanceDescription) from the shift location. You must be within \(Int(shiftLocation.radius))m to check in."
          showProximityAlert = true
          isLoading = false
          return
        }
      }

      // Call ClockIn mutation
      let mutation = ClockInMutation(
        shiftId: .some(shift.shiftClaim.shiftId),
        latitude: .some(location.coordinate.latitude),
        longitude: .some(location.coordinate.longitude)
      )

      let result = try await withCheckedThrowingContinuation { continuation in
        apolloClient.perform(mutation: mutation) { result in
          continuation.resume(with: result)
        }
      }

      if let data = result.data {
        print("Successfully clocked in:")
        print("- Time Entry ID: \(data.clockIn.id)")
        print("- Clock In Time: \(data.clockIn.clockInTime)")
        print("- Location: (\(data.clockIn.clockInLatitude ?? 0), \(data.clockIn.clockInLongitude ?? 0))")
      }

      // Refresh the shifts list
      await fetchTodayShifts()

    } catch let error as LocationError {
      if case .unauthorized = error {
        showLocationPermissionAlert = true
      } else {
        errorMessage = error.localizedDescription
      }
    } catch {
      errorMessage = "Failed to check in: \(error.localizedDescription)"
    }

    isLoading = false
  }

  // MARK: - Check Out

  func checkOutShift(_ shift: TodayShift) async {
    // Same location verification as check-in
    if locationManager.authorizationStatus != .authorizedWhenInUse &&
       locationManager.authorizationStatus != .authorizedAlways {
      showLocationPermissionAlert = true
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      // Get current location
      let location = try await locationManager.getCurrentLocation()

      // If shift has a location, verify proximity
      if let shiftLocation = shift.location {
        let verification = locationManager.verifyProximity(
          userLocation: location,
          shiftLocation: shiftLocation
        )

        if !verification.isWithinRadius {
          proximityAlertMessage = "You are \(verification.distanceDescription) from the shift location. You must be within \(Int(shiftLocation.radius))m to check out."
          showProximityAlert = true
          isLoading = false
          return
        }
      }

      // Call ClockOut mutation
      let mutation = ClockOutMutation(
        latitude: .some(location.coordinate.latitude),
        longitude: .some(location.coordinate.longitude)
      )

      let result = try await withCheckedThrowingContinuation { continuation in
        apolloClient.perform(mutation: mutation) { result in
          continuation.resume(with: result)
        }
      }

      if let data = result.data {
        print("Successfully clocked out:")
        print("- Time Entry ID: \(data.clockOut.id)")
        print("- Clock Out Time: \(data.clockOut.clockOutTime ?? "N/A")")
        print("- Hours Worked: \(data.clockOut.hoursWorked ?? 0)")
      }

      // Refresh the shifts list
      await fetchTodayShifts()

    } catch let error as LocationError {
      if case .unauthorized = error {
        showLocationPermissionAlert = true
      } else {
        errorMessage = error.localizedDescription
      }
    } catch {
      errorMessage = "Failed to check out: \(error.localizedDescription)"
    }

    isLoading = false
  }
}

// MARK: - Date Extension

extension Date {
  func toISO8601String() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: self)
  }
}
