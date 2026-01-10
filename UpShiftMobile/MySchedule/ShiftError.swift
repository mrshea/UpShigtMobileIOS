//
//  ShiftError.swift
//  UpShiftMobile
//
//  Typed errors for shift operations
//  Replaces fragile string-based error parsing with type-safe Swift errors
//

import Foundation

/// Typed errors for shift operations
enum ShiftError: LocalizedError {
    case noResults
    case networkError(underlying: Error)
    case parseError(message: String)
    case unauthorized
    case mutationFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No shifts found for the selected date range"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Failed to parse shift data: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .mutationFailed(let message):
            return message
        }
    }

    /// Indicates whether the error is recoverable and the user can retry
    var isRecoverable: Bool {
        switch self {
        case .noResults:
            return true  // Empty result is valid, not really an error
        case .networkError, .parseError:
            return true  // Can retry these operations
        case .unauthorized, .mutationFailed:
            return false // User action required
        }
    }

    /// Analyzes Apollo errors and converts to typed ShiftError
    /// - Parameter apolloError: Error from Apollo GraphQL operation
    /// - Returns: Typed ShiftError for better error handling
    static func from(apolloError: Error) -> ShiftError {
        let errorString = String(describing: apolloError)
        let errorDescription = apolloError.localizedDescription

        // Check for empty result patterns
        if errorString.contains("noResults") ||
           errorDescription.contains("noResults") ||
           errorDescription.contains("operation completed without returning any results") {
            return .noResults
        }

        // Check for authentication errors
        if errorString.contains("unauthorized") || errorString.contains("401") {
            return .unauthorized
        }

        // Default to network error with underlying error
        return .networkError(underlying: apolloError)
    }
}
