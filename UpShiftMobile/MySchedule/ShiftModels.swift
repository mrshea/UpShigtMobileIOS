//
//  ShiftModels.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation

// MARK: - Department Models

struct Department: Identifiable, Codable {
  let id: String
  let name: String
  let description: String?
  let orgId: String
  
  var displayName: String {
    name
  }
}

// MARK: - Shift Models

struct Shift: Identifiable, Codable {
  let id: String
  let date: Date
  let startTime: Date
  let endTime: Date
  let peopleNeeded: Int
  let departmentId: String?
  let department: Department?
  let availableSpots: Int
  let claimedBy: [ClaimedEmployee]?
  
  // Legacy support - returns department name or "Unknown"
  var role: String {
    department?.name ?? "Unknown"
  }
  
  var isClaimed: Bool {
    availableSpots < peopleNeeded
  }
  
  var isFull: Bool {
    availableSpots == 0
  }
  
  // Formatted time strings for display
  var startTimeFormatted: String {
    startTime.formatted(date: .omitted, time: .shortened)
  }
  
  var endTimeFormatted: String {
    endTime.formatted(date: .omitted, time: .shortened)
  }
  
  var timeRangeFormatted: String {
    "\(startTimeFormatted) - \(endTimeFormatted)"
  }
}

struct ClaimedEmployee: Identifiable, Codable {
  let id: String
  let clerkId: String
  let employeeName: String?
  let employeeEmail: String?
}

struct MyShiftClaim: Identifiable, Codable {
  let id: String
  let shiftId: String
  let claimedAt: Date
  let shift: ShiftDetail
}

struct ShiftDetail: Identifiable, Codable {
  let id: String
  let date: Date
  let startTime: Date
  let endTime: Date
  let departmentId: String?
  let department: Department?
  
  // Legacy support - returns department name or "Unknown"
  var role: String {
    department?.name ?? "Unknown"
  }
  
  // Formatted time strings for display
  var startTimeFormatted: String {
    startTime.formatted(date: .omitted, time: .shortened)
  }
  
  var endTimeFormatted: String {
    endTime.formatted(date: .omitted, time: .shortened)
  }
  
  var timeRangeFormatted: String {
    "\(startTimeFormatted) - \(endTimeFormatted)"
  }
}

// MARK: - Response Wrappers

struct ShiftsResponse: Codable {
  let shifts: [Shift]
}

struct MyShiftsResponse: Codable {
  let myShifts: [MyShiftClaim]
}
