//
//  TimeOffViewModel.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/20/25.
//

import Foundation
import Combine
import Apollo
import ApolloAPI
import UpShiftAPI

@MainActor
class TimeOffViewModel: ObservableObject {
  @Published var requests: [TimeOffRequest] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  
  private let apolloClient = Network.shared.apollo
  
  // MARK: - Fetch Time Off Requests
  
  func loadRequests(useCache: Bool = true) async {
    // Only show loading on first load (when cache is empty)
    if requests.isEmpty {
      isLoading = true
    }
    errorMessage = nil
    
    do {
      let query = GetMyTimeOffRequestsQuery()
      
      // Choose fetch strategy based on useCache parameter
      if useCache {
        // Use cache and network: returns cache first, then network
        for try await result in try apolloClient.fetch(
          query: query,
          cachePolicy: .cacheAndNetwork
        ) {
          if let data = result.data {
            self.requests = processTimeOffRequests(data.myTimeOffRequests)
            errorMessage = nil
          }
        }
      } else {
        // Network only: skip cache
        let result = try await apolloClient.fetch(
          query: query,
          cachePolicy: .networkOnly
        )
        
        if let data = result.data {
          self.requests = processTimeOffRequests(data.myTimeOffRequests)
          errorMessage = nil
        }
      }
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching time off requests: \(error)")
    }
    
    isLoading = false
  }
  
  // MARK: - Helper to process time off requests
  private func processTimeOffRequests(_ requestsData: [GetMyTimeOffRequestsQuery.Data.MyTimeOffRequest]) -> [TimeOffRequest] {
    return requestsData.compactMap { request -> TimeOffRequest? in
      // Convert DateTime strings to Dates
      guard let startDate = request.startTime.toDate(),
            let endDate = request.endTime.toDate(),
            let submittedAt = request.submittedDate.toDate() else {
        print("Failed to parse dates for time off request: \(request.id)")
        return nil
      }
      
      // Parse optional reviewedDate
      let reviewedAt = request.reviewedDate?.toDate()
      
      // Map status string to enum
      let status: TimeOffRequest.TimeOffStatus
      switch request.status.lowercased() {
      case "pending":
        status = .pending
      case "approved":
        status = .approved
      case "denied":
        status = .denied
      default:
        status = .pending
      }
      
      return TimeOffRequest(
        id: request.id,
        startDate: startDate,
        endDate: endDate,
        reason: request.employeeNotes,  // Map employeeNotes to reason
        status: status,
        submittedAt: submittedAt,
        reviewedAt: reviewedAt,
        reviewedBy: request.approvedBy,  // Map approvedBy to reviewedBy
        reviewNotes: request.managerNotes  // Map managerNotes to reviewNotes
      )
    }
  }
  
  // MARK: - Submit New Request
  
  func submitRequest(_ request: TimeOffRequest) async {
    isLoading = true
    errorMessage = nil
    errorMessage = nil
    
    do {
      let mutation = CreateTimeOffRequestMutation(
        startTime: request.startDate.iso8601,
        endTime: request.endDate.iso8601,
        employeeNotes: .some(request.reason ?? "")
      )
      
      let result = try await apolloClient.perform(mutation: mutation)
      
      if let error = result.errors?.first {
        print("❌ GraphQL Error:", error.message)
        throw NSError(
          domain: "TimeOffViewModel",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: error.message]
        )
      }
      
      print("✅ Time off request created successfully")
      
      // Clear the Apollo cache and reload
      try? await apolloClient.store.clearCache()
      await loadRequests(useCache: false)
    } catch {
      errorMessage = error.localizedDescription
      print("❌ Error submitting time off request: \(error)")
    }
    
    isLoading = false
  }
  
  // MARK: - Delete Request
  
  func deleteRequest(id: String) async throws {
    let mutation = DeleteTimeOffRequestMutation(id: id)
    
    let result = try await apolloClient.perform(mutation: mutation)
    
    if let error = result.errors?.first {
      throw NSError(
        domain: "TimeOffViewModel",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: error.message]
      )
    }
    
    // Clear the Apollo cache and reload
    try? await apolloClient.store.clearCache()
    await loadRequests(useCache: false)
  }
  
  // MARK: - Stats Helpers
  
  var pendingCount: Int {
    requests.filter { $0.status == .pending }.count
  }
  
  var approvedCount: Int {
    requests.filter { $0.status == .approved }.count
  }
  
  var deniedCount: Int {
    requests.filter { $0.status == .denied }.count
  }
  
  var upcomingDaysOff: Int {
    let now = Date()
    return requests
      .filter { $0.status == .approved && $0.startDate >= now }
      .reduce(0) { $0 + $1.daysCount }
  }
  
  var totalDaysOff: Int {
    requests
      .filter { $0.status == .approved }
      .reduce(0) { $0 + $1.daysCount }
  }
}
