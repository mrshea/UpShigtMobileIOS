//
//  DateExtensions.swift
//  UpShiftMobile
//
//  Centralized date utilities for the UpShift app
//  Handles conversion between Date objects and ISO8601/DateTime strings from GraphQL API
//

import Foundation

// MARK: - Date Extensions

extension Date {
    /// Converts Date to ISO8601 string with fractional seconds
    /// Used for GraphQL query variables that expect DateTime strings
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    /// Converts Date to ISO8601 string (method form for backward compatibility)
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    var startOfWeek: Date {
      let calendar = Calendar.current
      let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
      return calendar.date(from: components) ?? self
    }
}

// MARK: - String Extensions for Date Parsing

extension String {
    /// Parses ISO8601/DateTime strings from GraphQL API into Date objects
    /// Supports multiple formats: ISO8601 with/without fractional seconds, Prisma format
    /// - Returns: Date object if parsing succeeds, nil otherwise
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()

        // Try ISO8601 with fractional seconds first (most common from GraphQL)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: self) {
            return date
        }

        // Fallback to custom date formats for Prisma/PostgreSQL output
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Prisma format: "2025-12-10 20:30:00 +00:00"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // With milliseconds: "2025-12-10 20:30:00.123 +00:00"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Standard ISO8601: "2025-12-10T20:30:00.123Z"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Without milliseconds
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.date(from: self)
    }
}
