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
