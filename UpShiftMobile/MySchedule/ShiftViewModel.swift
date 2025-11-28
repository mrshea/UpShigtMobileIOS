//
//  ShiftViewModel.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 11/28/25.
//

import Foundation
import Combine
import Apollo
import ApolloAPI
import UpShiftAPI

@MainActor
class ShiftViewModel: ObservableObject {
  @Published var shifts: [Shift] = []
  @Published var myShifts: [MyShiftClaim] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  
  private let apolloClient = Network.shared.apollo
  
  // MARK: - Fetch All Shifts
  
  func fetchShifts(startDate: Date, endDate: Date) async {
    isLoading = true
    errorMessage = nil
    
    do {
      let query = GetShiftsQuery(
        startDate: .some(startDate.iso8601),
        endDate: .some(endDate.iso8601)
      )
      
      let result = try await apolloClient.fetch(query: query)
      
      if let data = result.data {
        // Map GraphQL response to local Shift model
        self.shifts = data.shifts.compactMap { shift in
          // Convert DateTime string to Date
          guard let date = shift.date.toDate() else {
            print("Failed to parse date: \(shift.date)")
            return nil
          }
          
          return Shift(
            id: shift.id,
            date: date,
            startTime: shift.startTime,
            endTime: shift.endTime,
            peopleNeeded: shift.peopleNeeded,
            role: shift.role,
            availableSpots: shift.availableSpots,
            claimedBy: shift.claimedBy.map { claimedBy in
              ClaimedEmployee(
                id: claimedBy.id,
                clerkId: claimedBy.clerkId,
                employeeName: claimedBy.employeeName,
                employeeEmail: claimedBy.employeeEmail
              )
            }
          )
        }
        errorMessage = nil
      }
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching shifts: \(error)")
    }
    
    isLoading = false
  }
  
  // MARK: - Fetch My Shifts
  
  func fetchMyShifts() async {
    isLoading = true
    errorMessage = nil
    
    do {
      let query = GetMyShiftsQuery()
      
      let result = try await apolloClient.fetch(query: query)
      
      if let data = result.data {
        // Map GraphQL response to local MyShiftClaim model
        self.myShifts = data.myShifts.compactMap { myShift in
          // Convert DateTime strings to Dates
          guard let claimedAt = myShift.claimedAt.toDate(),
                let shiftDate = myShift.shift.date.toDate() else {
            print("Failed to parse dates for shift: \(myShift.id)")
            return nil
          }
          
          return MyShiftClaim(
            id: myShift.id,
            shiftId: myShift.shiftId,
            claimedAt: claimedAt,
            shift: ShiftDetail(
              id: myShift.shift.id,
              date: shiftDate,
              startTime: myShift.shift.startTime,
              endTime: myShift.shift.endTime,
              role: myShift.shift.role
            )
          )
        }
        errorMessage = nil
      }
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching my shifts: \(error)")
    }
    
    isLoading = false
  }
  
  // MARK: - Claim Shift
  
  func claimShift(shiftId: String) async throws {
    let mutation = ClaimShiftMutation(shiftId: shiftId)
    
    let result = try await apolloClient.perform(mutation: mutation)
    
    if let error = result.errors?.first {
      throw NSError(
        domain: "ShiftViewModel",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: error.message]
      )
    }
  }
  
  // MARK: - Unclaim Shift
  
  func unclaimShift(shiftId: String) async throws {
    let mutation = UnclaimShiftMutation(shiftId: shiftId)
    
    let result = try await apolloClient.perform(mutation: mutation)
    
    if let error = result.errors?.first {
      throw NSError(
        domain: "ShiftViewModel",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: error.message]
      )
    }
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

// MARK: - Date Extension for ISO8601 formatting

extension Date {
  var iso8601: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: self)
  }
}

// MARK: - String Extension for parsing DateTime strings

extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    // Try with fractional seconds first
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: self) {
      return date
    }
    
    // Try without fractional seconds
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: self) {
      return date
    }
    
    // Try standard date formatter as fallback
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    if let date = dateFormatter.date(from: self) {
      return date
    }
    
    // Try without milliseconds
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter.date(from: self)
  }
}
