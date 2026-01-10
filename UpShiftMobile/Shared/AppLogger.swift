//
//  AppLogger.swift
//  UpShiftMobile
//
//  Centralized logging infrastructure using OSLog
//  Provides production-ready logging with privacy, performance, and proper categorization
//

import OSLog

/// Centralized logging infrastructure for the UpShift app
/// Uses OSLog for performance and privacy, with proper subsystem categorization
///
/// Usage Examples:
/// ```
/// AppLogger.shifts.info("Fetching shifts from \(startDate) to \(endDate)")
/// AppLogger.shifts.debug("Current shifts count: \(count)")
/// AppLogger.shifts.error("Failed to parse shift: \(error.localizedDescription)")
/// AppLogger.cache.notice("Cache cleared after mutation")
/// ```
///
/// Benefits:
/// - Privacy by default - OSLog automatically redacts sensitive data
/// - Performance - OSLog is highly optimized with minimal overhead
/// - Console integration - Works with Xcode Console and macOS Console.app
/// - Filtering - Can filter logs by subsystem/category in production
/// - Levels - info/debug/error/fault/notice for proper severity
enum AppLogger {
    /// Logger for shift-related operations (fetching, claiming, unclaiming)
    static let shifts = Logger(subsystem: "com.upshift.mobile", category: "shifts")

    /// Logger for network/Apollo operations
    static let network = Logger(subsystem: "com.upshift.mobile", category: "network")

    /// Logger for cache operations
    static let cache = Logger(subsystem: "com.upshift.mobile", category: "cache")

    /// Logger for authentication operations
    static let auth = Logger(subsystem: "com.upshift.mobile", category: "auth")

    /// Logger for time tracking operations
    static let timeTracking = Logger(subsystem: "com.upshift.mobile", category: "timeTracking")
}
