//
//  TodayModels.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

import Foundation

// MARK: - Check-In/Out Status

enum CheckInStatus: String, Codable {
  case notStarted = "NOT_STARTED"
  case canCheckIn = "CAN_CHECK_IN"
  case checkedIn = "CHECKED_IN"
  case canCheckOut = "CAN_CHECK_OUT"
  case checkedOut = "CHECKED_OUT"
  case completed = "COMPLETED"
  case pendingApproval = "PENDING_APPROVAL"

  var displayName: String {
    switch self {
    case .notStarted: return "Not Started"
    case .canCheckIn: return "Ready"
    case .checkedIn: return "Checked In"
    case .canCheckOut: return "Ready to Check Out"
    case .checkedOut: return "Checked Out"
    case .completed: return "Completed"
    case .pendingApproval: return "Pending Approval"
    }
  }
}

// MARK: - Check-In/Out Record

struct CheckInOutRecord: Identifiable, Codable {
  let id: String
  let shiftClaimId: String
  let checkInTime: Date?
  let checkOutTime: Date?
  let checkInLatitude: Double?
  let checkInLongitude: Double?
  let checkOutLatitude: Double?
  let checkOutLongitude: Double?
  let status: CheckInStatus
  let requiresManagerApproval: Bool
  let earlyCheckInMinutes: Int?
  let lateCheckInMinutes: Int?
  let earlyCheckOutMinutes: Int?
  let lateCheckOutMinutes: Int?
  let actualHoursWorked: Double?
  let scheduledHours: Double

  var isEarlyCheckIn: Bool {
    earlyCheckInMinutes ?? 0 > 0
  }

  var isLateCheckIn: Bool {
    lateCheckInMinutes ?? 0 > 0
  }

  var isEarlyCheckOut: Bool {
    earlyCheckOutMinutes ?? 0 > 0
  }

  var isLateCheckOut: Bool {
    lateCheckOutMinutes ?? 0 > 0
  }
}

// MARK: - Shift Location

struct ShiftLocation: Codable {
  let latitude: Double
  let longitude: Double
  let radius: Double  // In meters
  let address: String?

  static var defaultRadius: Double {
    100.0 // meters
  }
}

// MARK: - Today's Shift

struct TodayShift: Identifiable {
  let id: String
  let shiftClaim: MyShiftClaim
  let checkInOutRecord: CheckInOutRecord?
  let location: ShiftLocation?

  var canCheckIn: Bool {
    guard let record = checkInOutRecord else { return true }
    return record.checkInTime == nil
  }

  var canCheckOut: Bool {
    guard let record = checkInOutRecord else { return false }
    return record.checkInTime != nil && record.checkOutTime == nil
  }

  var status: CheckInStatus {
    checkInOutRecord?.status ?? .notStarted
  }

  var isCheckedIn: Bool {
    checkInOutRecord?.checkInTime != nil && checkInOutRecord?.checkOutTime == nil
  }

  var isCompleted: Bool {
    checkInOutRecord?.status == .completed || checkInOutRecord?.checkOutTime != nil
  }
}

// MARK: - Location Verification Result

struct LocationVerification {
  let isWithinRadius: Bool
  let distanceInMeters: Double
  let userLatitude: Double
  let userLongitude: Double

  var distanceDescription: String {
    if distanceInMeters < 1000 {
      return "\(Int(distanceInMeters))m away"
    } else {
      return String(format: "%.1fkm away", distanceInMeters / 1000)
    }
  }
}
