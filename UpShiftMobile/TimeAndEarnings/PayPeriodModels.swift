//
//  PayPeriodModels.swift
//  UpShiftMobile
//

import Foundation

// MARK: - API response envelope

struct APIResponse<T: Decodable>: Decodable {
  let data: T?
}

// MARK: - Config model (matches GET /api/pay-period-config)

enum PayFrequency: String, Decodable {
  case weekly = "WEEKLY"
  case biweekly = "BIWEEKLY"
  case semimonthly = "SEMIMONTHLY"
  case monthly = "MONTHLY"
}

struct PayPeriodConfig: Decodable {
  let id: String
  let orgId: String
  let frequency: PayFrequency
  let anchorDayOfWeek: Int?
  let anchorDate: Date?
  let firstDayOfMonth: Int?
  let secondDayOfMonth: Int?
  let dayOfMonth: Int?
  let timezone: String?
}

// MARK: - Computed pay period

struct PayPeriod: Equatable {
  /// Inclusive start (local midnight).
  let start: Date
  /// Exclusive end (local midnight of the day after the last day).
  let end: Date
  let label: String

  /// Inclusive last day (used for display and some filtering needs).
  var lastDay: Date {
    Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: end) ?? end
  }
}

// MARK: - Calculator

enum PayPeriodCalculator {

  static func period(for config: PayPeriodConfig, offset: Int, now: Date = Date()) -> PayPeriod {
    var cal = Calendar(identifier: .gregorian)
    if let tz = config.timezone, let timeZone = TimeZone(identifier: tz) {
      cal.timeZone = timeZone
    } else {
      cal.timeZone = TimeZone(identifier: "America/New_York") ?? .current
    }

    switch config.frequency {
    case .weekly:
      return weeklyPeriod(cal: cal, anchorDOW: config.anchorDayOfWeek ?? 1, offset: offset, now: now)
    case .biweekly:
      return biweeklyPeriod(
        cal: cal,
        anchorDOW: config.anchorDayOfWeek ?? 1,
        anchorDate: config.anchorDate ?? now,
        offset: offset,
        now: now
      )
    case .semimonthly:
      return semimonthlyPeriod(
        cal: cal,
        firstDay: config.firstDayOfMonth ?? 1,
        secondDay: config.secondDayOfMonth ?? 15,
        offset: offset,
        now: now
      )
    case .monthly:
      return monthlyPeriod(cal: cal, dayOfMonth: config.dayOfMonth ?? 1, offset: offset, now: now)
    }
  }

  // MARK: Weekly

  private static func weeklyPeriod(cal: Calendar, anchorDOW: Int, offset: Int, now: Date) -> PayPeriod {
    let start = currentWeekStart(cal: cal, anchorDOW: anchorDOW, reference: now)
    let shifted = cal.date(byAdding: .day, value: offset * 7, to: start) ?? start
    let end = cal.date(byAdding: .day, value: 7, to: shifted) ?? shifted
    return PayPeriod(start: shifted, end: end, label: label(cal: cal, start: shifted, end: end))
  }

  private static func currentWeekStart(cal: Calendar, anchorDOW: Int, reference: Date) -> Date {
    // Calendar weekday: 1=Sunday ... 7=Saturday. API anchorDOW: 0=Sunday ... 6=Saturday.
    let targetWeekday = (anchorDOW % 7) + 1
    let today = cal.startOfDay(for: reference)
    let currentWeekday = cal.component(.weekday, from: today)
    var delta = currentWeekday - targetWeekday
    if delta < 0 { delta += 7 }
    return cal.date(byAdding: .day, value: -delta, to: today) ?? today
  }

  // MARK: Biweekly

  private static func biweeklyPeriod(
    cal: Calendar,
    anchorDOW: Int,
    anchorDate: Date,
    offset: Int,
    now: Date
  ) -> PayPeriod {
    // The server sends anchorDate as midnight UTC representing a calendar date
    // (e.g. "2026-04-20T00:00:00.000Z" means April 20). Extract that wall-clock
    // date in UTC, then rebuild it at local midnight in the org's timezone.
    var utcCal = Calendar(identifier: .gregorian)
    utcCal.timeZone = TimeZone(identifier: "UTC") ?? .current
    let ymd = utcCal.dateComponents([.year, .month, .day], from: anchorDate)
    var local = DateComponents()
    local.year = ymd.year
    local.month = ymd.month
    local.day = ymd.day
    local.hour = 0
    local.minute = 0
    local.second = 0
    let anchorDay = cal.date(from: local) ?? cal.startOfDay(for: anchorDate)

    // Find the most recent period start on or before `now` by walking 14-day
    // increments from the anchor.
    let today = cal.startOfDay(for: now)

    let daysBetween = cal.dateComponents([.day], from: anchorDay, to: today).day ?? 0
    // Number of full 14-day periods since anchor (can be negative if anchor is in the future).
    let periodsSinceAnchor = Int((Double(daysBetween) / 14.0).rounded(.down))
    let currentStart = cal.date(byAdding: .day, value: periodsSinceAnchor * 14, to: anchorDay) ?? anchorDay

    let shifted = cal.date(byAdding: .day, value: offset * 14, to: currentStart) ?? currentStart
    let end = cal.date(byAdding: .day, value: 14, to: shifted) ?? shifted
    return PayPeriod(start: shifted, end: end, label: label(cal: cal, start: shifted, end: end))
  }

  // MARK: Semimonthly

  private static func semimonthlyPeriod(
    cal: Calendar,
    firstDay: Int,
    secondDay: Int,
    offset: Int,
    now: Date
  ) -> PayPeriod {
    let (d1, d2) = firstDay <= secondDay ? (firstDay, secondDay) : (secondDay, firstDay)
    let today = cal.startOfDay(for: now)

    // Determine which half of the current month we're in.
    let currentDay = cal.component(.day, from: today)
    var year = cal.component(.year, from: today)
    var month = cal.component(.month, from: today)
    // halfIndex: 0 = first-of-month anchor, 1 = second anchor
    var halfIndex: Int
    if currentDay >= d2 {
      halfIndex = 1
    } else if currentDay >= d1 {
      halfIndex = 0
    } else {
      // Before first anchor -> belongs to previous month's second half.
      halfIndex = 1
      month -= 1
      if month < 1 { month = 12; year -= 1 }
    }

    // Step by `offset` half-months.
    var totalHalves = (year * 12 + (month - 1)) * 2 + halfIndex + offset
    var shiftedHalfIndex = ((totalHalves % 2) + 2) % 2
    var shiftedMonthsTotal = Int((Double(totalHalves - shiftedHalfIndex) / 2.0).rounded())
    var shiftedYear = shiftedMonthsTotal / 12
    var shiftedMonth = (shiftedMonthsTotal % 12) + 1

    let startDay = shiftedHalfIndex == 0 ? d1 : d2
    let start = date(cal: cal, year: shiftedYear, month: shiftedMonth, day: startDay)

    // Compute end = next half's start.
    var nextHalfIndex = shiftedHalfIndex + 1
    var nextYear = shiftedYear
    var nextMonth = shiftedMonth
    if nextHalfIndex > 1 {
      nextHalfIndex = 0
      nextMonth += 1
      if nextMonth > 12 { nextMonth = 1; nextYear += 1 }
    }
    let nextStartDay = nextHalfIndex == 0 ? d1 : d2
    let end = date(cal: cal, year: nextYear, month: nextMonth, day: nextStartDay)

    // Suppress "unused" warnings for mutable locals.
    _ = (totalHalves, shiftedHalfIndex, shiftedMonthsTotal, shiftedYear, shiftedMonth,
         nextHalfIndex, nextYear, nextMonth)

    return PayPeriod(start: start, end: end, label: label(cal: cal, start: start, end: end))
  }

  // MARK: Monthly

  private static func monthlyPeriod(cal: Calendar, dayOfMonth: Int, offset: Int, now: Date) -> PayPeriod {
    let today = cal.startOfDay(for: now)
    var year = cal.component(.year, from: today)
    var month = cal.component(.month, from: today)

    let currentStartDayInMonth = monthlyStartDay(cal: cal, year: year, month: month, dayOfMonth: dayOfMonth)
    let currentDayNum = cal.component(.day, from: today)

    // If today is before this month's start, use previous month's anchor.
    if currentDayNum < currentStartDayInMonth {
      month -= 1
      if month < 1 { month = 12; year -= 1 }
    }

    // Apply offset in months.
    var shiftedMonthsTotal = year * 12 + (month - 1) + offset
    var shiftedYear = shiftedMonthsTotal / 12
    var shiftedMonth = (shiftedMonthsTotal % 12) + 1
    if shiftedMonth < 1 { shiftedMonth += 12; shiftedYear -= 1 }

    let startDay = monthlyStartDay(cal: cal, year: shiftedYear, month: shiftedMonth, dayOfMonth: dayOfMonth)
    let start = date(cal: cal, year: shiftedYear, month: shiftedMonth, day: startDay)

    var nextYear = shiftedYear
    var nextMonth = shiftedMonth + 1
    if nextMonth > 12 { nextMonth = 1; nextYear += 1 }
    let nextStartDay = monthlyStartDay(cal: cal, year: nextYear, month: nextMonth, dayOfMonth: dayOfMonth)
    let end = date(cal: cal, year: nextYear, month: nextMonth, day: nextStartDay)

    _ = shiftedMonthsTotal
    return PayPeriod(start: start, end: end, label: label(cal: cal, start: start, end: end))
  }

  /// Resolves the actual start day for a month, accounting for `0` (last day) and short months.
  private static func monthlyStartDay(cal: Calendar, year: Int, month: Int, dayOfMonth: Int) -> Int {
    let range = daysInMonth(cal: cal, year: year, month: month)
    if dayOfMonth == 0 { return range }
    return min(max(dayOfMonth, 1), range)
  }

  private static func daysInMonth(cal: Calendar, year: Int, month: Int) -> Int {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = 1
    let date = cal.date(from: comps) ?? Date()
    return cal.range(of: .day, in: .month, for: date)?.count ?? 30
  }

  private static func date(cal: Calendar, year: Int, month: Int, day: Int) -> Date {
    let maxDay = daysInMonth(cal: cal, year: year, month: month)
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = min(day, maxDay)
    comps.hour = 0
    comps.minute = 0
    comps.second = 0
    return cal.date(from: comps) ?? Date()
  }

  // MARK: Label

  private static func label(cal: Calendar, start: Date, end: Date) -> String {
    let last = cal.date(byAdding: .day, value: -1, to: end) ?? end
    let formatter = DateFormatter()
    formatter.calendar = cal
    formatter.timeZone = cal.timeZone

    let startYear = cal.component(.year, from: start)
    let lastYear = cal.component(.year, from: last)
    let startMonth = cal.component(.month, from: start)
    let lastMonth = cal.component(.month, from: last)

    if startYear == lastYear && startMonth == lastMonth {
      formatter.dateFormat = "MMM d"
      let s = formatter.string(from: start)
      formatter.dateFormat = "d, yyyy"
      let e = formatter.string(from: last)
      return "\(s) – \(e)"
    } else if startYear == lastYear {
      formatter.dateFormat = "MMM d"
      let s = formatter.string(from: start)
      formatter.dateFormat = "MMM d, yyyy"
      let e = formatter.string(from: last)
      return "\(s) – \(e)"
    } else {
      formatter.dateFormat = "MMM d, yyyy"
      let s = formatter.string(from: start)
      let e = formatter.string(from: last)
      return "\(s) – \(e)"
    }
  }
}
