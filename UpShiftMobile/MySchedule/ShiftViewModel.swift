//
//  ShiftViewModel.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation
import Combine

@MainActor
class ShiftViewModel: ObservableObject {
  @Published var shifts: [Shift] = []
  @Published var myShifts: [MyShiftClaim] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  
  
  // MARK: - Fetch All Shifts
  
  func fetchShifts(startDate: Date, endDate: Date) async {
    isLoading = true
    errorMessage = nil
    
    // TODO: Implement shift fetching
    
    isLoading = false
  }
  
  // MARK: - Fetch My Shifts
  
  func fetchMyShifts() async {
    isLoading = true
    errorMessage = nil
    
    // TODO: Implement my shifts fetching
    
    isLoading = false
  }
  
  // MARK: - Claim Shift
  
  func claimShift(shiftId: String) async throws {
    // TODO: Implement shift claiming
  }
  
  // MARK: - Unclaim Shift
  
  func unclaimShift(shiftId: String) async throws {
    // TODO: Implement shift unclaiming
  }
  
  // MARK: - Helper to get shifts for a specific date
  
  func shiftsForDate(_ date: Date) -> [Shift] {
    let calendar = Calendar.current
    return shifts.filter { shift in
      calendar.isDate(shift.date, inSameDayAs: date)
    }
  }
  
  func myShiftsForDate(_ date: Date) -> [MyShiftClaim] {
    let calendar = Calendar.current
    return myShifts.filter { claim in
      calendar.isDate(claim.shift.date, inSameDayAs: date)
    }
  }
}
