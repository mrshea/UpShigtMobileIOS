//
//  Extensions.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/12/25.
//

import Foundation

// MARK: - Date Extensions

extension Date {
  var iso8601: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: self)
  }
  
  func toISO8601String() -> String {
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
