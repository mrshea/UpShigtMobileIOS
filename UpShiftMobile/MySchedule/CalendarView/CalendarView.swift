//
//  CalendarView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 1/9/26.
//

import SwiftUI
import HorizonCalendar
import SwiftUIIntrospect
struct CalendarView: View {
  let calendar: Calendar
  let visibleDateRange: ClosedRange<Date>
  let calendarHeight: CGFloat
  @Binding var selectedDate: Date
  let hasShifts: (Date) -> Bool
  
  var body: some View {
    CalendarViewRepresentable(
      calendar: calendar,
      visibleDateRange: visibleDateRange,
      monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
      dataDependency: selectedDate
    )
    .days { day in
      dayView(for: day)
    }
    .onDaySelection { day in
      if let dayDate = calendar.date(from: day.components) {
        selectedDate = dayDate
      }
    }
    .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26)) { scrollView in
      scrollView.isScrollEnabled = false
    }
    .frame(height: calendarHeight)
    .padding(.horizontal)
    .padding(.vertical)
  }
  
  private func dayView(for day: DayComponents) -> some View {
    let dayDate = calendar.date(from: day.components) ?? Date()
    return DayView(
      day: day,
      isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate),
      hasShifts: hasShifts(dayDate)
    )
  }
}

// MARK: - Custom Calendar Day View

struct DayView: View {
  let day: DayComponents
  let isSelected: Bool
  let hasShifts: Bool
  @Environment(\.calendar) var calendar
  
  private var dayDate: Date {
    calendar.date(from: day.components) ?? Date()
  }
  
  var body: some View {
    VStack(spacing: 4) {
      Text("\(day.day)")
        .font(.system(size: 18))
        .fontWeight(isSelected ? .bold : .regular)
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(width: 36, height: 36)
        .background(
          Circle()
            .fill(isSelected ? Color.blue : Color.clear)
        )
      
      // Indicator dot for days with shifts
      if hasShifts {
        Circle()
          .fill(isSelected ? .white : .blue)
          .frame(width: 4, height: 4)
      } else {
        Circle()
          .fill(.clear)
          .frame(width: 4, height: 4)
      }
    }
  }
}

