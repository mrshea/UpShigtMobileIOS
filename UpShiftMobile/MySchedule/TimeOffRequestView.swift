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
  @State private var reason = ""
  @State private var isSubmitting = false
  @State private var showSuccessAlert = false
  @State private var errorMessage: String?
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
          DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
        } header: {
          Text("Time Off Period")
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
          .disabled(isSubmitting || !isValidDateRange)
          .listRowBackground(
            isValidDateRange && !isSubmitting ? Color.blue : Color.gray.opacity(0.5)
          )
          .foregroundStyle(.white)
        }
        
        if !isValidDateRange {
          Section {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
              Text("End date must be on or after start date")
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
  
  private var isValidDateRange: Bool {
    endDate >= startDate
  }
  
  // MARK: - Methods
  
  private func submitRequest() {
    isSubmitting = true
    
    // TODO: Implement API call to submit time off request
    // For now, simulate a network request
    Task {
      do {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // TODO: Replace with actual API call
        // Example:
        // try await TimeOffService.shared.submitRequest(
        //   startDate: startDate,
        //   endDate: endDate,
        //   reason: reason
        // )
        
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
}

#Preview {
  TimeOffRequestView()
}
