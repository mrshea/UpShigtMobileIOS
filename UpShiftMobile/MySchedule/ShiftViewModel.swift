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
        
        print("🔍 fetchShifts called:")
        print("  - Start: \(startDate)")
        print("  - End: \(endDate)")
        print("  - useCache: \(useCache)")
        print("  - Current shifts count: \(shifts.count)")
        
        do {
            let query = GetShiftsQuery(
                startDate: .some(startDate.iso8601),
                endDate: .some(endDate.iso8601)
            )
            
            print("  - Query dates: \(startDate.iso8601) to \(endDate.iso8601)")
            
            // Use the CacheAndNetwork policy type for async stream when we want fresh data
            if useCache {
                // For cached requests, use SingleResponse cacheFirst
                let cachePolicy: CachePolicy.Query.SingleResponse = .networkOnly
                print("  - Using cache policy: \(cachePolicy)")
                
                let result = try await apolloClient.fetch(
                    query: query,
                    cachePolicy: cachePolicy
                )
                
                print("  - Got result, data is \(result.data != nil ? "present" : "nil")")
                
                if let data = result.data {
                    print("  - Raw shifts from API: \(data.shifts.count)")
                    self.shifts = parseShifts(data.shifts)
                    errorMessage = nil
                    print("📦 Fetched \(self.shifts.count) shifts (cached)")
                }
            } else {
                // For refresh, use CacheAndNetwork async stream
                let cachePolicy: CachePolicy.Query.CacheAndNetwork = .cacheAndNetwork
                print("  - Using cache policy: \(cachePolicy) (async stream)")
                
                var latestShifts: [Shift] = []
                
                for try await result in try apolloClient.fetch(query: query, cachePolicy: cachePolicy) {
                    print("  - Got async result, data is \(result.data != nil ? "present" : "nil")")
                    
                    if let data = result.data {
                        print("  - Raw shifts from API: \(data.shifts.count)")
                        latestShifts = parseShifts(data.shifts)
                        // Update immediately with each result (cache first, then network)
                        self.shifts = latestShifts
                        print("📦 Updated with \(self.shifts.count) shifts from async stream")
                    }
                }
                
                errorMessage = nil
                print("📦 Final fetch result: \(self.shifts.count) shifts (refreshed)")
            }
        } catch {
            // Handle errors
            let errorDescription = error.localizedDescription
            let errorString = String(describing: error)
            
            print("  - Caught error: \(errorString)")
            
            // Check if this is a "no results" type error
            if errorString.contains("noResults") || 
               errorDescription.contains("noResults") ||
               errorDescription.contains("operation completed without returning any results") {
                // Empty result is valid - clear data and error
                self.shifts = []
                errorMessage = nil
                print("📦 Fetched 0 shifts (empty result from server)")
            } else {
                // This is a real error - set error message
                errorMessage = errorDescription
                print("❌ Error fetching shifts: \(error)")
            }
        }
        
        isLoading = false
    }
    
    // Helper to parse shifts (extracted to avoid duplication)
    private func parseShifts(_ shiftsData: [GetShiftsQuery.Data.Shift]) -> [Shift] {
        return shiftsData.compactMap { shift -> Shift? in
            guard let date = shift.date.toDate(),
                  let startTime = shift.startTime.toDate(),
                  let endTime = shift.endTime.toDate() else {
                print("⚠️ Failed to parse dates for shift: \(shift.id)")
                return nil
            }
            
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
    }
  
  // MARK: - Fetch My Shifts
  
  func fetchMyShifts(useCache: Bool = true) async {
    // Only show loading on first load (when cache is empty)
    if myShifts.isEmpty {
      isLoading = true
    }
    errorMessage = nil
    
    print("🔍 fetchMyShifts called:")
    print("  - useCache: \(useCache)")
    print("  - Current myShifts count: \(myShifts.count)")
    
    do {
      let query = GetMyShiftsQuery()
      
      // Use the CacheAndNetwork policy type for async stream when we want fresh data
      if useCache {
        // For cached requests, use SingleResponse cacheFirst
        let cachePolicy: CachePolicy.Query.SingleResponse = .cacheFirst
        print("  - Using cache policy: \(cachePolicy)")
        
        let result = try await apolloClient.fetch(
          query: query,
          cachePolicy: cachePolicy
        )
        
        print("  - Got result, data is \(result.data != nil ? "present" : "nil")")
        
        if let data = result.data {
          print("  - Raw my shifts from API: \(data.myShifts.count)")
          self.myShifts = processMyShifts(data.myShifts)
          errorMessage = nil
          print("📦 Fetched \(self.myShifts.count) my shifts (cached)")
        }
      } else {
        // For refresh, use CacheAndNetwork async stream
        let cachePolicy: CachePolicy.Query.CacheAndNetwork = .cacheAndNetwork
        print("  - Using cache policy: \(cachePolicy) (async stream)")
        
        for try await result in try apolloClient.fetch(query: query, cachePolicy: cachePolicy) {
          print("  - Got async result, data is \(result.data != nil ? "present" : "nil")")
          
          if let data = result.data {
            print("  - Raw my shifts from API: \(data.myShifts.count)")
            self.myShifts = processMyShifts(data.myShifts)
            print("📦 Updated with \(self.myShifts.count) my shifts from async stream")
          }
        }
        
        errorMessage = nil
        print("📦 Final fetch result: \(self.myShifts.count) my shifts (refreshed)")
      }
    } catch {
      // Handle errors
      let errorDescription = error.localizedDescription
      let errorString = String(describing: error)
      
      print("  - Caught error: \(errorString)")
      
      // Check if this is a "no results" type error
      if errorString.contains("noResults") || 
         errorDescription.contains("noResults") ||
         errorDescription.contains("operation completed without returning any results") {
        // Empty result is valid - clear data and error
        self.myShifts = []
        errorMessage = nil
        print("📦 Fetched 0 my shifts (empty result from server)")
      } else {
        // This is a real error - set error message
        errorMessage = errorDescription
        print("❌ Error fetching my shifts: \(error)")
      }
    }
    
    isLoading = false
  }
  
  // MARK: - Helper to process my shifts data
  private func processMyShifts(_ myShiftsData: [GetMyShiftsQuery.Data.MyShift]) -> [MyShiftClaim] {
    return myShiftsData.compactMap { myShift -> MyShiftClaim? in
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
