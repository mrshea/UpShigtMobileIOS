import Foundation
import SwiftUI

struct DropShiftRequest: Identifiable {
    let id: String
    let shiftId: String
    let status: Status
    let employeeNotes: String?
    let managerNotes: String?
    let submittedAt: Date
    let reviewedAt: Date?
    let approvedBy: String?
    let shift: ShiftSummary

    enum Status: String, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"

        var color: Color {
            switch self {
            case .pending: return .orange
            case .approved: return .green
            case .denied: return .red
            }
        }

        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .approved: return "checkmark.circle.fill"
            case .denied: return "xmark.circle.fill"
            }
        }
    }

    struct ShiftSummary {
        let id: String
        let date: Date
        let startTime: Date
        let endTime: Date
        let departmentName: String
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: shift.date)
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: shift.startTime)) - \(formatter.string(from: shift.endTime))"
    }
}