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
  
    func fetchShifts(startDate: Date, endDate: Date, useCache: Bool = true) async {
        // Only show loading on first load (when cache is empty)
        if shifts.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            let query = GetShiftsQuery(
                startDate: .some(startDate.iso8601),
                endDate: .some(endDate.iso8601)
            )
            
            // Use cache-first policy: show cached data immediately, then fetch fresh data
            let cachePolicy: CachePolicy = useCache ? .returnCacheDataAndFetch : .fetchIgnoringCacheData
            
            let result = try await withCheckedThrowingContinuation { continuation in
                apolloClient.fetch(
                    query: query,
                    cachePolicy: cachePolicy
                ) { result in
                    continuation.resume(with: result)
                }
            }
            
            if let data = result.data {
                self.shifts = data.shifts.compactMap { shift -> Shift? in
                    guard let date = shift.date.toDate(),
                          let startTime = shift.startTime.toDate(),
                          let endTime = shift.endTime.toDate() else {
                        print("Failed to parse dates for shift: \(shift.id)")
                        print("  - date: \(shift.date)")
                        print("  - startTime: \(shift.startTime)")
                        print("  - endTime: \(shift.endTime)")
                        return nil
                    }
                    
                    // Map department if available
                    let department: Department? = shift.department.map { dept in
                        Department(
                            id: dept.id,
                            name: dept.name,
                            description: dept.description,
                            orgId: dept.orgId
                        )
                    }
                    
                    return Shift(
                        id: shift.id,
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        peopleNeeded: shift.peopleNeeded,
                        departmentId: shift.departmentId,
                        department: department,
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
            }else{
                print(result.errors)
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
        self.myShifts = data.myShifts.compactMap { myShift -> MyShiftClaim? in
          // Convert DateTime strings to Dates
          guard let claimedAt = myShift.claimedAt.toDate(),
                let shiftDate = myShift.shift.date.toDate(),
                let startTime = myShift.shift.startTime.toDate(),
                let endTime = myShift.shift.endTime.toDate() else {
            print("Failed to parse dates for shift: \(myShift.id)")
            print("  - claimedAt: \(myShift.claimedAt)")
            print("  - shiftDate: \(myShift.shift.date)")
            print("  - startTime: \(myShift.shift.startTime)")
            print("  - endTime: \(myShift.shift.endTime)")
            return nil
          }
          
          // Debug: Log department data
          print("🔍 Shift \(myShift.shift.id):")
          print("  - departmentId: \(myShift.shift.departmentId ?? "nil")")
          print("  - department object: \(myShift.shift.department != nil ? "present" : "nil")")
          if let dept = myShift.shift.department {
            print("  - department.name: \(dept.name)")
          }
          
          // Map department if available
          let department: Department? = myShift.shift.department.map { dept in
              Department(
                  id: dept.id,
                  name: dept.name,
                  description: dept.description,
                  orgId: dept.orgId
              )
          }
          
          return MyShiftClaim(
            id: myShift.id,
            shiftId: myShift.shiftId,
            claimedAt: claimedAt,
            shift: ShiftDetail(
              id: myShift.shift.id,
              date: shiftDate,
              startTime: startTime,
              endTime: endTime,
              departmentId: myShift.shift.departmentId,
              department: department
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
    
    // Clear the Apollo cache to force fresh data on next fetch
    try? await apolloClient.store.clearCache()
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
    
    // Clear the Apollo cache to force fresh data on next fetch
    try? await apolloClient.store.clearCache()
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
    func hasClaimedShiftForDate(for date: Date) -> Bool {
        return !myShiftsForDate(date).isEmpty
    }
  
  func hasShifts(for date: Date) -> Bool {
    let calendar = Calendar.current
    return shifts.contains { shift in
      calendar.isDate(shift.date, inSameDayAs: date)
    } || myShifts.contains { claim in
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
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Try Prisma/PostgreSQL format: "2025-12-10 20:30:00 +00:00"
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    if let date = dateFormatter.date(from: self) {
      return date
    }
    
    // Try with milliseconds: "2025-12-10 20:30:00.123 +00:00"
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
    if let date = dateFormatter.date(from: self) {
      return date
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    if let date = dateFormatter.date(from: self) {
      return date
    }
    
    // Try without milliseconds
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter.date(from: self)
  }
}
