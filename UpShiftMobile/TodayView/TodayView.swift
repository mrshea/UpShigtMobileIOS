//
//  TodayView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

import SwiftUI
import Clerk
internal import CoreLocation
import Combine

struct TodayView: View {
  var clerk: Clerk
  @Binding var authIsPresented: Bool
  @StateObject private var viewModel: TodayViewModel

  init(clerk: Clerk, authIsPresented: Binding<Bool>) {
    self.clerk = clerk
    self._authIsPresented = authIsPresented
    self._viewModel = StateObject(wrappedValue: TodayViewModel())
  }

  var body: some View {
    NavigationStack {
      if clerk.user != nil {
        authenticatedView
      } else {
        unauthenticatedView
      }
    }
    .alert("Location Permission Required", isPresented: $viewModel.showLocationPermissionAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Open Settings") {
        viewModel.locationManager.openSettings()
      }
    } message: {
      Text("UpShift needs access to your location to verify you're at the shift location. Please enable location services in Settings.")
    }
    .alert("Outside Shift Location", isPresented: $viewModel.showProximityAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(viewModel.proximityAlertMessage)
    }
  }

  // MARK: - Authenticated View

  private var authenticatedView: some View {
    ZStack(alignment: .top) {
      // Background gradient
      LinearGradient(
        colors: [Color.blue.opacity(0.1), Color.clear],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        headerView
        scrollContent
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.fetchTodayShifts()
    }
    .refreshable {
      await viewModel.fetchTodayShifts()
    }
  }

  private var headerView: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Today")
          .font(.system(size: 36, weight: .bold))

        Text(Date(), style: .date)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      UserButton()
        .frame(width: 40, height: 40)
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 12)
  }

  private var scrollContent: some View {
    ScrollView {
      VStack(spacing: 20) {
        if viewModel.locationManager.authorizationStatus == .denied ||
           viewModel.locationManager.authorizationStatus == .restricted {
          locationPermissionBanner
        }

        shiftsContentView
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
  }

  // MARK: - Location Permission Banner

  private var locationPermissionBanner: some View {
    VStack(spacing: 12) {
      Image(systemName: "location.slash.fill")
        .font(.system(size: 48))
        .foregroundStyle(.orange)

      VStack(spacing: 6) {
        Text("Location Disabled")
          .font(.title3)
          .fontWeight(.semibold)

        Text("Enable location services to check in to shifts")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Button {
        viewModel.locationManager.openSettings()
      } label: {
        Text("Enable in Settings")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
      }
      .buttonStyle(.borderedProminent)
      .tint(.orange)
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(Color.orange.opacity(0.1))
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
    )
    .cornerRadius(20)
  }

  // MARK: - Shifts Content

  @ViewBuilder
  private var shiftsContentView: some View {
    if viewModel.isLoading && viewModel.todayShifts.isEmpty {
      loadingView
    } else if let error = viewModel.errorMessage {
      errorView(error)
    } else if viewModel.todayShifts.isEmpty {
      emptyStateView
    } else {
      shiftsListView
    }
  }

  private var loadingView: some View {
    VStack {
      ProgressView()
        .padding()
      Text("Loading today's shifts...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }

  private func errorView(_ error: String) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(.orange)

      Text("Error loading shifts")
        .font(.headline)

      Text(error)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task { await viewModel.fetchTodayShifts() }
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(uiColor: .secondarySystemBackground))
    .cornerRadius(12)
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Spacer()

      Image(systemName: "sun.max.fill")
        .font(.system(size: 80))
        .foregroundStyle(
          LinearGradient(
            colors: [.yellow, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .padding(.bottom, 8)

      Text("No Shifts Today")
        .font(.system(size: 32, weight: .bold))

      Text("Enjoy your day off! Check the Schedule tab to see upcoming shifts or browse available shifts to claim.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var shiftsListView: some View {
    VStack(spacing: 16) {
      ForEach(viewModel.todayShifts) { shift in
        TodayShiftCard(
          shift: shift,
          isProcessing: viewModel.isLoading,
          onCheckIn: {
            Task {
              await viewModel.checkInShift(shift)
            }
          },
          onCheckOut: {
            Task {
              await viewModel.checkOutShift(shift)
            }
          }
        )
      }
    }
  }

  // MARK: - Unauthenticated View

  private var unauthenticatedView: some View {
    VStack(spacing: 20) {
      Text("Sign in to view today's shifts")
        .font(.title2)

      Button("Sign In") {
        authIsPresented = true
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

// MARK: - Today Shift Card

struct TodayShiftCard: View {
  let shift: TodayShift
  let isProcessing: Bool
  let onCheckIn: () -> Void
  let onCheckOut: () -> Void

  @State private var currentTime = Date()

  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Top section with gradient background
      VStack(alignment: .leading, spacing: 12) {
        statusBadge

        VStack(alignment: .leading, spacing: 6) {
          Text(shift.shiftClaim.shift.role)
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.primary)

          HStack(spacing: 6) {
            Image(systemName: "clock.fill")
              .font(.body)
            Text("\(shift.shiftClaim.shift.startTime) - \(shift.shiftClaim.shift.endTime)")
              .font(.title3)
              .fontWeight(.medium)
          }
          .foregroundStyle(.secondary)
        }

        if let location = shift.location, let address = location.address {
          HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
              .font(.title3)
              .foregroundStyle(.blue)
            Text(address)
              .font(.body)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 4)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        LinearGradient(
          colors: gradientColorsForStatus,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )

      // Timer widget section
      timerWidget
        .padding(24)
        .background(Color(uiColor: .systemBackground))

      // Middle section with status info
      if let record = shift.checkInOutRecord {
        statusInfoSection(record: record)
          .padding(24)
          .background(Color(uiColor: .systemBackground))
      }

      // Action button section
      if !shift.isCompleted {
        actionButton
          .padding(24)
          .background(Color(uiColor: .systemBackground))
      }
    }
    .background(Color(uiColor: .systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    .overlay(
      RoundedRectangle(cornerRadius: 24)
        .stroke(borderColorForStatus, lineWidth: 2)
    )
    .onReceive(timer) { _ in
      currentTime = Date()
    }
  }

  // MARK: - Timer Widget

  @ViewBuilder
  private var timerWidget: some View {
    if shift.isCheckedIn, let checkInTime = shift.checkInOutRecord?.checkInTime {
      // Elapsed time since check-in
      elapsedTimeWidget(since: checkInTime)
    } else if !shift.isCompleted {
      // Countdown to shift start
      countdownWidget
    } else if let record = shift.checkInOutRecord, let actualHours = record.actualHoursWorked {
      // Completed shift summary
      completedSummaryWidget(hours: actualHours)
    }
  }

  private func elapsedTimeWidget(since checkInTime: Date) -> some View {
    let elapsed = currentTime.timeIntervalSince(checkInTime)
    let hours = Int(elapsed) / 3600
    let minutes = Int(elapsed) % 3600 / 60
    let seconds = Int(elapsed) % 60

    return VStack(spacing: 12) {
      HStack {
        Circle()
          .fill(Color.green)
          .frame(width: 12, height: 12)

        Text("Currently Working")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()
      }

      HStack(spacing: 4) {
        timeBlock(value: hours, label: "hrs")
        Text(":")
          .font(.system(size: 48, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
        timeBlock(value: minutes, label: "min")
        Text(":")
          .font(.system(size: 48, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
        timeBlock(value: seconds, label: "sec")
      }
      .frame(maxWidth: .infinity)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.green.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.green.opacity(0.2), lineWidth: 2)
    )
  }

  private var countdownWidget: some View {
    let shiftStartTime = getShiftStartDate()
    let timeUntilStart = shiftStartTime.timeIntervalSince(currentTime)

    if timeUntilStart > 0 {
      let hours = Int(timeUntilStart) / 3600
      let minutes = Int(timeUntilStart) % 3600 / 60

      return AnyView(
        VStack(spacing: 12) {
          HStack {
            Image(systemName: "clock.badge.checkmark")
              .foregroundStyle(.blue)

            Text("Shift Starts In")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer()
          }

          HStack(spacing: 8) {
            if hours > 0 {
              VStack(spacing: 4) {
                Text("\(hours)")
                  .font(.system(size: 56, weight: .bold, design: .rounded))
                Text("hours")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

            if hours > 0 {
              Text(":")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }

            VStack(spacing: 4) {
              Text("\(minutes)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
              Text("minutes")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.blue.opacity(0.05))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue.opacity(0.2), lineWidth: 2)
        )
      )
    } else {
      return AnyView(
        VStack(spacing: 8) {
          HStack {
            Image(systemName: "clock.badge.checkmark.fill")
              .foregroundStyle(.green)

            Text("Ready to Check In")
              .font(.headline)

            Spacer()
          }
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.green.opacity(0.05))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.green.opacity(0.2), lineWidth: 2)
        )
      )
    }
  }

  private func completedSummaryWidget(hours: Double) -> some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.blue)

        Text("Shift Completed")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()
      }

      VStack(spacing: 4) {
        Text(String(format: "%.1f", hours))
          .font(.system(size: 64, weight: .bold, design: .rounded))
        Text("hours worked")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.blue.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.blue.opacity(0.2), lineWidth: 2)
    )
  }

  private func timeBlock(value: Int, label: String) -> some View {
    VStack(spacing: 2) {
      Text(String(format: "%02d", value))
        .font(.system(size: 48, weight: .bold, design: .rounded))
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private func getShiftStartDate() -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"

    guard let startTime = dateFormatter.date(from: shift.shiftClaim.shift.startTime) else {
      return shift.shiftClaim.shift.date
    }

    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: shift.shiftClaim.shift.date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    return calendar.date(from: combined) ?? shift.shiftClaim.shift.date
  }

  // MARK: - Status Badge

  private var statusBadge: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(badgeColorForStatus)
        .frame(width: 8, height: 8)

      Text(shift.status.displayName)
        .font(.subheadline)
        .fontWeight(.semibold)
    }
    .foregroundStyle(badgeColorForStatus)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(badgeColorForStatus.opacity(0.15))
    .clipShape(Capsule())
  }

  // MARK: - Status Info Section

  private func statusInfoSection(record: CheckInOutRecord) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      if let checkInTime = record.checkInTime {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 10) {
            ZStack {
              Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 40, height: 40)

              Image(systemName: "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
              Text("Checked In")
                .font(.subheadline)
                .foregroundStyle(.secondary)

              Text(checkInTime, style: .time)
                .font(.title3)
                .fontWeight(.semibold)
            }

            Spacer()

            if record.isEarlyCheckIn {
              timingBadge(text: "\(record.earlyCheckInMinutes ?? 0)m early", color: .orange)
            } else if record.isLateCheckIn {
              timingBadge(text: "\(record.lateCheckInMinutes ?? 0)m late", color: .red)
            }
          }
        }
      }

      if let checkOutTime = record.checkOutTime {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 10) {
            ZStack {
              Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)

              Image(systemName: "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
              Text("Checked Out")
                .font(.subheadline)
                .foregroundStyle(.secondary)

              Text(checkOutTime, style: .time)
                .font(.title3)
                .fontWeight(.semibold)
            }

            Spacer()

            if record.isEarlyCheckOut {
              timingBadge(text: "\(record.earlyCheckOutMinutes ?? 0)m early", color: .orange)
            } else if record.isLateCheckOut {
              timingBadge(text: "\(record.lateCheckOutMinutes ?? 0)m late", color: .red)
            }
          }
        }
      }

      if let actualHours = record.actualHoursWorked {
        Divider()

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Hours Worked")
                .font(.subheadline)
                .foregroundStyle(.secondary)

              Text(String(format: "%.1f hours", actualHours))
                .font(.system(size: 24, weight: .bold))
            }

            Spacer()

            if actualHours != record.scheduledHours {
              VStack(alignment: .trailing, spacing: 4) {
                Text("Scheduled")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Text(String(format: "%.1f hrs", record.scheduledHours))
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
            }
          }
        }
      }

      if record.requiresManagerApproval {
        HStack(spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.yellow)
          Text("Pending manager approval")
            .font(.subheadline)
            .fontWeight(.medium)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }

  private func timingBadge(text: String, color: Color) -> some View {
    Text(text)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(color)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.15))
      .clipShape(Capsule())
  }

  // MARK: - Action Button

  @ViewBuilder
  private var actionButton: some View {
    if shift.canCheckIn {
      Button(action: onCheckIn) {
        HStack(spacing: 12) {
          if isProcessing {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
          } else {
            Image(systemName: "arrow.down.circle.fill")
              .font(.title2)
            Text("Check In Now")
              .font(.headline)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
          LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
      }
      .disabled(isProcessing)
    } else if shift.canCheckOut {
      Button(action: onCheckOut) {
        HStack(spacing: 12) {
          if isProcessing {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
          } else {
            Image(systemName: "arrow.up.circle.fill")
              .font(.title2)
            Text("Check Out Now")
              .font(.headline)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
          LinearGradient(
            colors: [Color.orange, Color.orange.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
      }
      .disabled(isProcessing)
    }
  }

  // MARK: - Styling Helpers

  private var gradientColorsForStatus: [Color] {
    switch shift.status {
    case .checkedIn, .canCheckOut:
      return [Color.green.opacity(0.15), Color.green.opacity(0.05)]
    case .completed:
      return [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]
    case .pendingApproval:
      return [Color.yellow.opacity(0.15), Color.yellow.opacity(0.05)]
    default:
      return [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]
    }
  }

  private var borderColorForStatus: Color {
    switch shift.status {
    case .checkedIn, .canCheckOut:
      return Color.green.opacity(0.2)
    case .completed:
      return Color.blue.opacity(0.2)
    case .pendingApproval:
      return Color.yellow.opacity(0.2)
    default:
      return Color.gray.opacity(0.1)
    }
  }

  private var badgeColorForStatus: Color {
    switch shift.status {
    case .notStarted:
      return Color.gray
    case .canCheckIn:
      return Color.blue
    case .checkedIn, .canCheckOut:
      return Color.green
    case .checkedOut, .completed:
      return Color.blue
    case .pendingApproval:
      return Color.yellow
    }
  }
}
