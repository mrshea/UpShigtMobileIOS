//
//  ShiftModels.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation

// MARK: - Shift Models

struct Shift: Identifiable, Codable {
  let id: String
  let date: Date
  let startTime: String
  let endTime: String
  let peopleNeeded: Int
  let role: String
  let availableSpots: Int
  let claimedBy: [ClaimedEmployee]?
  
  var isClaimed: Bool {
    availableSpots < peopleNeeded
  }
  
  var isFull: Bool {
    availableSpots == 0
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
  let startTime: String
  let endTime: String
  let role: String
}

// MARK: - Response Wrappers

struct ShiftsResponse: Codable {
  let shifts: [Shift]
}

struct MyShiftsResponse: Codable {
  let myShifts: [MyShiftClaim]
}
