//
//  TimeOffRequestView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/19/25.
//
import SwiftUI

struct TimeOffRequestView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var startDate = Date()
  @State private var endDate = Date()
  @State private var startTime = Date()
  @State private var endTime = Date()
  @State private var isAllDay = true
  @State private var reason = ""
  @State private var isSubmitting = false
  @State private var showSuccessAlert = false
  @State private var errorMessage: String?
  let onSubmit: (TimeOffRequest) async -> Void
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          Toggle("All Day", isOn: $isAllDay)

          DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
          
          if !isAllDay {
            DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
          }
          
          DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
          
          if !isAllDay {
            DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
          }
        } header: {
          Text("Time Off Period")
        } footer: {
          if isAllDay {
            Text("Full day time off from 12:00 AM to 11:59 PM")
              .font(.caption)
          } else if isValidDateTimeRange {
            Text(durationText)
              .font(.caption)
          }
        }
        
        Section {
          TextField("Reason (optional)", text: $reason, axis: .vertical)
            .lineLimit(3...6)
        } header: {
          Text("Details")
        }
        
        Section {
          Button(action: submitRequest) {
            if isSubmitting {
              HStack {
                Spacer()
                ProgressView()
                  .tint(.white)
                Spacer()
              }
            } else {
              HStack {
                Spacer()
                Text("Submit Request")
                  .fontWeight(.semibold)
                Spacer()
              }
            }
          }
          .disabled(isSubmitting || !isValidDateTimeRange)
          .listRowBackground(
            isValidDateTimeRange && !isSubmitting ? Color.blue : Color.gray.opacity(0.5)
          )
          .foregroundStyle(.white)
        }
        
        if !isValidDateTimeRange {
          Section {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
              Text(validationErrorMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("Request Time Off")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Request Submitted", isPresented: $showSuccessAlert) {
        Button("OK") {
          dismiss()
        }
      } message: {
        Text("Your time off request has been submitted successfully.")
      }
      .alert("Error", isPresented: .constant(errorMessage != nil)) {
        Button("OK") {
          errorMessage = nil
        }
      } message: {
        if let error = errorMessage {
          Text(error)
        }
      }
    }
  }
  
  // MARK: - Computed Properties
  
  private var isValidDateTimeRange: Bool {
    if isAllDay {
      return endDate >= startDate
    } else {
      let fullStartDateTime = combinedDateTime(date: startDate, time: startTime)
      let fullEndDateTime = combinedDateTime(date: endDate, time: endTime)
      return fullEndDateTime > fullStartDateTime
    }
  }
  
  private var validationErrorMessage: String {
    if isAllDay {
      return "End date must be on or after start date"
    } else {
      return "End date and time must be after start date and time"
    }
  }
  
  private var durationText: String {
    let fullStartDateTime = combinedDateTime(date: startDate, time: startTime)
    let fullEndDateTime = combinedDateTime(date: endDate, time: endTime)
    
    let components = Calendar.current.dateComponents(
      [.day, .hour, .minute],
      from: fullStartDateTime,
      to: fullEndDateTime
    )
    
    var parts: [String] = []
    
    if let days = components.day, days > 0 {
      parts.append("\(days) day\(days == 1 ? "" : "s")")
    }
    
    if let hours = components.hour, hours > 0 {
      parts.append("\(hours) hour\(hours == 1 ? "" : "s")")
    }
    
    if let minutes = components.minute, minutes > 0 {
      parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
    }
    
    if parts.isEmpty {
      return "Less than 1 minute"
    }
    
    return "Duration: " + parts.joined(separator: ", ")
  }
  
  private func combinedDateTime(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    
    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute
    
    return calendar.date(from: combined) ?? date
  }
  
  private func allDayStartDateTime(for date: Date) -> Date {
    let calendar = Calendar.current
    return calendar.startOfDay(for: date) // 12:00 AM
  }
  
  private func allDayEndDateTime(for date: Date) -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    components.hour = 23
    components.minute = 59
    components.second = 59
    return calendar.date(from: components) ?? date
  }
  
  // MARK: - Methods
  
  private func submitRequest1() {
    isSubmitting = true
    
    // TODO: Implement API call to submit time off request
    // For now, simulate a network request
    Task {
      do {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Prepare the actual start and end date/times
        let actualStartDateTime: Date
        let actualEndDateTime: Date
        
        if isAllDay {
          actualStartDateTime = allDayStartDateTime(for: startDate)
          actualEndDateTime = allDayEndDateTime(for: endDate)
        } else {
          actualStartDateTime = combinedDateTime(date: startDate, time: startTime)
          actualEndDateTime = combinedDateTime(date: endDate, time: endTime)
        }
        
        // TODO: Replace with actual API call
        // Example:
        // try await TimeOffService.shared.submitRequest(
        //   startDateTime: actualStartDateTime,
        //   endDateTime: actualEndDateTime,
        //   reason: reason,
        //   isAllDay: isAllDay
        // )
        
        print("Submitting request:")
        print("Start: \(actualStartDateTime)")
        print("End: \(actualEndDateTime)")
        print("All Day: \(isAllDay)")
        print("Reason: \(reason)")
        
        await MainActor.run {
          isSubmitting = false
          showSuccessAlert = true
        }
      } catch {
        await MainActor.run {
          isSubmitting = false
          errorMessage = error.localizedDescription
        }
      }
    }
  }
    
    
    
    private func submitRequest() {
      isSubmitting = true
      
      Task {
        // Prepare the actual start and end date/times
        let actualStartDateTime: Date
        let actualEndDateTime: Date
        
        if isAllDay {
          actualStartDateTime = allDayStartDateTime(for: startDate)
          actualEndDateTime = allDayEndDateTime(for: endDate)
        } else {
          actualStartDateTime = combinedDateTime(date: startDate, time: startTime)
          actualEndDateTime = combinedDateTime(date: endDate, time: endTime)
        }
        
        // Create request object
        let request = TimeOffRequest(
          id: UUID().uuidString,
          startDate: actualStartDateTime,
          endDate: actualEndDateTime,
          reason: reason.isEmpty ? nil : reason,
          status: .pending,
          submittedAt: Date(),
          reviewedAt: nil,
          reviewedBy: nil,
          reviewNotes: nil
        )
        
        await onSubmit(request)
        
        await MainActor.run {
          isSubmitting = false
          dismiss()
        }
      }
    }
}

