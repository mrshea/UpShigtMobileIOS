//
//  ShiftViewModel.swift
//  UpShiftMobile
//
//  ViewModel for managing shift data with Apollo iOS
//  Supports both available shifts and user's claimed shifts
//  Uses proper cache management and typed errors following Apollo iOS best practices
//

import Foundation
import Combine
import Apollo
import ApolloAPI
import UpShiftAPI
import OSLog

@MainActor
class ShiftViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var shifts: [Shift] = []
    @Published var myShifts: [MyShiftClaim] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apolloClient: ApolloClient
    private let logger = AppLogger.shifts

    // MARK: - Refresh State

    private var refreshTask: Task<Void, Never>?
    private var lastRefreshTime: Date?
    private let minimumRefreshInterval: TimeInterval = 3.0

    // MARK: - Initialization

    /// Initialize with optional Apollo client (supports dependency injection for testing)
    /// - Parameter apolloClient: Custom Apollo client, defaults to Network.shared.apollo
    init(apolloClient: ApolloClient = Network.shared.apollo) {
        self.apolloClient = apolloClient
    }

    // MARK: - Public Fetch Methods

    /// Fetches available shifts for a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    ///   - useCache: If true, uses cacheFirst; if false, uses cacheAndNetwork
    func fetchShifts(startDate: Date, endDate: Date, useCache: Bool = true) async {
        // Only show loading on first load (when cache is empty)
        if shifts.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        logger.info("fetchShifts called: \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted)), useCache=\(useCache)")

        do {
            let query = GetShiftsQuery(
                startDate: .some(startDate.iso8601),
                endDate: .some(endDate.iso8601)
            )

            if useCache {
                // Use cacheFirst for initial load - returns cache immediately if available
                let cachePolicy: CachePolicy.Query.SingleResponse = .cacheFirst
                logger.debug("fetchShifts: Using cache policy cacheFirst")

                let result = try await apolloClient.fetch(
                    query: query,
                    cachePolicy: cachePolicy
                )

                if let data = result.data {
                    self.shifts = parseShifts(data.shifts)
                    logger.info("fetchShifts completed: \(self.shifts.count) items (cached)")
                }
            } else {
                // Use cacheAndNetwork for refresh - async stream returns cache then network
                let cachePolicy: CachePolicy.Query.CacheAndNetwork = .cacheAndNetwork
                logger.debug("fetchShifts: Using cache policy cacheAndNetwork (async stream)")

                for try await result in try apolloClient.fetch(query: query, cachePolicy: cachePolicy) {
                    if let data = result.data {
                        self.shifts = parseShifts(data.shifts)
                        logger.debug("fetchShifts stream update: \(self.shifts.count) items")
                    }
                }

                logger.info("fetchShifts completed (refreshed)")
            }

            errorMessage = nil

        } catch {
            handleFetchError(error, operationName: "fetchShifts", resultSetter: { self.shifts = $0 })
        }

        isLoading = false
    }

    /// Fetches user's claimed shifts
    /// - Parameter useCache: If true, uses cacheFirst; if false, uses cacheAndNetwork
    func fetchMyShifts(useCache: Bool = true) async {
        // Only show loading on first load (when cache is empty)
        if myShifts.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        logger.info("fetchMyShifts called: useCache=\(useCache)")

        do {
            let query = GetMyShiftsQuery()

            if useCache {
                // Use cacheFirst for initial load - returns cache immediately if available
                let cachePolicy: CachePolicy.Query.SingleResponse = .cacheFirst
                logger.debug("fetchMyShifts: Using cache policy cacheFirst")

                let result = try await apolloClient.fetch(
                    query: query,
                    cachePolicy: cachePolicy
                )

                if let data = result.data {
                    self.myShifts = processMyShifts(data.myShifts)
                    logger.info("fetchMyShifts completed: \(self.myShifts.count) items (cached)")
                }
            } else {
                // Use cacheAndNetwork for refresh - async stream returns cache then network
                let cachePolicy: CachePolicy.Query.CacheAndNetwork = .cacheAndNetwork
                logger.debug("fetchMyShifts: Using cache policy cacheAndNetwork (async stream)")

                for try await result in try apolloClient.fetch(query: query, cachePolicy: cachePolicy) {
                    if let data = result.data {
                        self.myShifts = processMyShifts(data.myShifts)
                        logger.debug("fetchMyShifts stream update: \(self.myShifts.count) items")
                    }
                }

                logger.info("fetchMyShifts completed (refreshed)")
            }

            errorMessage = nil

        } catch {
            handleFetchError(error, operationName: "fetchMyShifts", resultSetter: { self.myShifts = $0 })
        }

        isLoading = false
    }

    // MARK: - Refresh Methods

    /// Refreshes shifts data with throttling to prevent spam
    /// Designed to be used with SwiftUI's .refreshable modifier
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    func refreshShifts(startDate: Date, endDate: Date) async {
        // Throttle refresh requests
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            logger.debug("Refresh throttled - too soon since last refresh")
            return
        }

        // Cancel any existing refresh task
        refreshTask?.cancel()

        refreshTask = Task {
            guard !Task.isCancelled else { return }

            logger.info("Refreshing shifts (throttled)")
            await fetchShifts(startDate: startDate, endDate: endDate, useCache: false)

            lastRefreshTime = Date()
        }

        await refreshTask?.value
    }

    /// Refreshes myShifts data with throttling to prevent spam
    /// Designed to be used with SwiftUI's .refreshable modifier
    func refreshMyShifts() async {
        // Throttle refresh requests
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            logger.debug("Refresh throttled - too soon since last refresh")
            return
        }

        // Cancel any existing refresh task
        refreshTask?.cancel()

        refreshTask = Task {
            guard !Task.isCancelled else { return }

            logger.info("Refreshing myShifts (throttled)")
            await fetchMyShifts(useCache: false)

            lastRefreshTime = Date()
        }

        await refreshTask?.value
    }

    /// Handles errors from fetch operations with typed error conversion
    private func handleFetchError<T>(
        _ error: Error,
        operationName: String,
        resultSetter: @escaping ([T]) -> Void
    ) {
        let shiftError = ShiftError.from(apolloError: error)

        logger.error("\(operationName) error: \(shiftError.localizedDescription ?? "unknown")")

        if case .noResults = shiftError {
            // Empty result is valid - clear data but don't show error
            resultSetter([])
            errorMessage = nil
            logger.info("\(operationName) returned no results (valid empty state)")
        } else if shiftError.isRecoverable {
            // Recoverable error - show message but don't clear data
            errorMessage = shiftError.errorDescription
        } else {
            // Non-recoverable error - show message and clear data
            resultSetter([])
            errorMessage = shiftError.errorDescription
        }
    }

    // MARK: - Parsing Methods

    /// Parses GetShiftsQuery response into Shift models
    private func parseShifts(_ shiftsData: [GetShiftsQuery.Data.Shift]) -> [Shift] {
        return shiftsData.compactMap { shift -> Shift? in
            guard let date = shift.date.toDate(),
                  let startTime = shift.startTime.toDate(),
                  let endTime = shift.endTime.toDate() else {
                logger.warning("Failed to parse dates for shift \(shift.id)")
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

    /// Parses GetMyShiftsQuery response into MyShiftClaim models
    private func processMyShifts(_ myShiftsData: [GetMyShiftsQuery.Data.MyShift]) -> [MyShiftClaim] {
        return myShiftsData.compactMap { myShift -> MyShiftClaim? in
            guard let claimedAt = myShift.claimedAt.toDate(),
                  let shiftDate = myShift.shift.date.toDate(),
                  let startTime = myShift.shift.startTime.toDate(),
                  let endTime = myShift.shift.endTime.toDate() else {
                logger.warning("Failed to parse dates for my shift \(myShift.id)")
                return nil
            }

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

    // MARK: - Mutations

    /// Claims a shift for the current user
    /// Uses selective refetch instead of nuclear cache clearing (Apollo iOS best practice)
    /// - Parameter shiftId: ID of the shift to claim
    /// - Throws: ShiftError if claim fails
    func claimShift(shiftId: String) async throws {
        logger.info("Claiming shift \(shiftId)")

        let mutation = ClaimShiftMutation(shiftId: shiftId)

        let result = try await apolloClient.perform(mutation: mutation)

        if let error = result.errors?.first {
            let errorMsg = error.message ?? "Unknown error"
            logger.error("Claim shift mutation failed: \(errorMsg)")
            throw ShiftError.mutationFailed(message: errorMsg)
        }

        logger.notice("Shift \(shiftId) claimed successfully")

        // Instead of clearing entire cache, refetch affected queries
        // This is Apollo iOS best practice for cache updates
        await refetchAfterMutation()
    }

    /// Unclaims a shift for the current user
    /// Uses selective refetch instead of nuclear cache clearing (Apollo iOS best practice)
    /// - Parameter shiftId: ID of the shift to unclaim
    /// - Throws: ShiftError if unclaim fails
    func unclaimShift(shiftId: String) async throws {
        logger.info("Unclaiming shift \(shiftId)")

        let mutation = UnclaimShiftMutation(shiftId: shiftId)

        let result = try await apolloClient.perform(mutation: mutation)

        if let error = result.errors?.first {
            let errorMsg = error.message ?? "Unknown error"
            logger.error("Unclaim shift mutation failed: \(errorMsg)")
            throw ShiftError.mutationFailed(message: errorMsg)
        }

        logger.notice("Shift \(shiftId) unclaimed successfully")

        // Instead of clearing entire cache, refetch affected queries
        await refetchAfterMutation()
    }

    /// Refetches data after a mutation instead of clearing entire Apollo cache
    /// This is the Apollo iOS best practice - selective refetch instead of nuclear cache clearing
    private func refetchAfterMutation() async {
        logger.debug("Refetching data after mutation (selective refetch)")

        // Refetch both shifts and myShifts with network-only policy
        // This updates the cache with fresh data without destroying other cached queries

        // Refetch shifts if we have any loaded (infer date range from existing data)
        if !self.shifts.isEmpty {
            if let minDate = self.shifts.map(\.date).min(),
               let maxDate = self.shifts.map(\.date).max() {
                await self.fetchShifts(startDate: minDate, endDate: maxDate, useCache: false)
            }
        }

        // Refetch myShifts
        await self.fetchMyShifts(useCache: false)
    }

    // MARK: - Helper Methods (Preserved for backward compatibility)

    /// Returns shifts for a specific date
    func shiftsForDate(_ date: Date) -> [Shift] {
        let calendar = Calendar.current
        return shifts.filter { shift in
            calendar.isDate(shift.date, inSameDayAs: date)
        }
    }

    /// Returns user's claimed shifts for a specific date
    func myShiftsForDate(_ date: Date) -> [MyShiftClaim] {
        let calendar = Calendar.current
        return myShifts.filter { claim in
            calendar.isDate(claim.shift.date, inSameDayAs: date)
        }
    }

    /// Checks if user has claimed any shift for a specific date
    func hasClaimedShiftForDate(for date: Date) -> Bool {
        return !myShiftsForDate(date).isEmpty
    }

    /// Checks if there are any shifts (claimed or available) for a specific date
    func hasShifts(for date: Date) -> Bool {
        let calendar = Calendar.current
        return shifts.contains { shift in
            calendar.isDate(shift.date, inSameDayAs: date)
        } || myShifts.contains { claim in
            calendar.isDate(claim.shift.date, inSameDayAs: date)
        }
    }
}
