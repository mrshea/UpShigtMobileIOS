//
//  TimeOffView.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/19/25.
//
import SwiftUI
import Combine

// MARK: - Time Off Request Model
struct TimeOffRequest: Identifiable {
  let id: String
  let startDate: Date
  let endDate: Date
  let reason: String?
  let status: TimeOffStatus
  let submittedAt: Date
  let reviewedAt: Date?
  let reviewedBy: String?
  let reviewNotes: String?

  enum TimeOffStatus: String, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case denied = "Denied"

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

  var dateRangeFormatted: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"

    let startString = formatter.string(from: startDate)

    let calendar = Calendar.current
    if calendar.isDate(startDate, inSameDayAs: endDate) {
      return startString
    } else {
      let endString = formatter.string(from: endDate)
      return "\(startString) - \(endString)"
    }
  }

  var daysCount: Int {
    let calendar = Calendar.current
    let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    return days + 1
  }
}

// MARK: - Time Off View
struct TimeOffView: View {
  @StateObject private var viewModel = TimeOffViewModel()
  @State private var showNewRequestSheet = false
  @State private var selectedFilter: TimeOffRequest.TimeOffStatus? = nil

  var filteredRequests: [TimeOffRequest] {
    if let filter = selectedFilter {
      return viewModel.requests.filter { $0.status == filter }
    }
    return viewModel.requests
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        statsSection
        filterSection
        contentSection
      }
      .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Time Off")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showNewRequestSheet = true
        } label: {
          Label("New Request", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showNewRequestSheet) {
      TimeOffRequestView { request in
        await viewModel.submitRequest(request)
      }
    }
    .task {
      await viewModel.loadRequests()
    }
    .refreshable {
      await viewModel.loadRequests(useCache: false)
    }
  }

  // MARK: - Stats Section

  private var statsSection: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        StatCard(
          title: "Pending",
          count: viewModel.pendingCount,
          icon: "clock.fill",
          color: .orange
        )
        StatCard(
          title: "Approved",
          count: viewModel.approvedCount,
          icon: "checkmark.circle.fill",
          color: .green
        )
        StatCard(
          title: "Days Off",
          count: viewModel.upcomingDaysOff,
          icon: "calendar",
          color: .blue
        )
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal)
    }
    .frame(height: 96)
  }

  // MARK: - Filter Section

  private var filterSection: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        FilterChip(title: "All", isSelected: selectedFilter == nil) {
          withAnimation { selectedFilter = nil }
        }
        ForEach(TimeOffRequest.TimeOffStatus.allCases, id: \.self) { status in
          FilterChip(title: status.rawValue, isSelected: selectedFilter == status) {
            withAnimation { selectedFilter = status }
          }
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal)
    }
    .frame(height: 44)
  }

  // MARK: - Content Section

  @ViewBuilder
  private var contentSection: some View {
    if viewModel.isLoading && viewModel.requests.isEmpty {
      loadingView
    } else if let error = viewModel.errorMessage, viewModel.requests.isEmpty {
      errorView(error)
    } else if viewModel.requests.isEmpty {
      emptyStateView
    } else if filteredRequests.isEmpty {
      noResultsView
    } else {
      requestsListView
    }
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
      Text("Loading requests...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }

  private func errorView(_ error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundStyle(.orange)
      Text("Error Loading Requests")
        .font(.title2.weight(.semibold))
      Text(error)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      Button("Retry") {
        Task { await viewModel.loadRequests(useCache: false) }
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
    .padding(.horizontal)
  }

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "calendar.badge.clock")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)
      Text("No Time Off Requests")
        .font(.title2.weight(.semibold))
      Text("Tap + to submit your first request")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }

  private var noResultsView: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)
      Text("No \(selectedFilter?.rawValue ?? "") Requests")
        .font(.title2.weight(.semibold))
      Text("Try adjusting your filters")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }

  private var requestsListView: some View {
    LazyVStack(spacing: 12) {
      ForEach(filteredRequests) { request in
        TimeOffRequestCard(request: request)
      }
    }
    .padding(.horizontal)
  }
}

// MARK: - Stat Card
struct StatCard: View {
  let title: String
  let count: Int
  let icon: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.caption)
          .foregroundStyle(color)
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Text("\(count)")
        .font(.title.weight(.bold))
        .foregroundStyle(.primary)
    }
    .padding()
    .frame(minWidth: 110, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }
}

// MARK: - Time Off Request Card
struct TimeOffRequestCard: View {
  let request: TimeOffRequest
  @State private var showDetails = false

  var body: some View {
    Button(action: { showDetails = true }) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(request.dateRangeFormatted)
              .font(.headline)
              .foregroundStyle(.primary)
            Text("\(request.daysCount) day\(request.daysCount == 1 ? "" : "s")")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Spacer()
          HStack(spacing: 6) {
            Image(systemName: request.status.icon)
              .font(.caption)
            Text(request.status.rawValue)
              .font(.caption.weight(.semibold))
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(request.status.color.opacity(0.2))
          .foregroundStyle(request.status.color)
          .clipShape(Capsule())
        }

        if let reason = request.reason, !reason.isEmpty {
          Text(reason)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        HStack(spacing: 4) {
          Image(systemName: "clock")
            .font(.caption2)
          Text("Submitted \(request.submittedAt, style: .relative) ago")
            .font(.caption2)
        }
        .foregroundStyle(.tertiary)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
    .sheet(isPresented: $showDetails) {
      TimeOffRequestDetailView(request: request)
    }
  }
}

// MARK: - Time Off Request Detail View
struct TimeOffRequestDetailView: View {
  let request: TimeOffRequest
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section("Date Range") {
          HStack {
            Label("Start Date", systemImage: "calendar")
            Spacer()
            Text(request.startDate, style: .date)
              .foregroundStyle(.secondary)
          }
          HStack {
            Label("End Date", systemImage: "calendar")
            Spacer()
            Text(request.endDate, style: .date)
              .foregroundStyle(.secondary)
          }
          HStack {
            Label("Total Days", systemImage: "clock")
            Spacer()
            Text("\(request.daysCount)")
              .foregroundStyle(.secondary)
          }
        }

        if let reason = request.reason, !reason.isEmpty {
          Section("Reason") {
            Text(reason)
          }
        }

        Section("Status") {
          HStack {
            Label("Current Status", systemImage: request.status.icon)
            Spacer()
            Text(request.status.rawValue)
              .foregroundStyle(request.status.color)
              .fontWeight(.semibold)
          }
          HStack {
            Label("Submitted", systemImage: "paperplane")
            Spacer()
            Text(request.submittedAt, style: .date)
              .foregroundStyle(.secondary)
          }
          if let reviewedAt = request.reviewedAt {
            HStack {
              Label("Reviewed", systemImage: "checkmark.circle")
              Spacer()
              Text(reviewedAt, style: .date)
                .foregroundStyle(.secondary)
            }
          }
          if let reviewedBy = request.reviewedBy {
            HStack {
              Label("Reviewed By", systemImage: "person")
              Spacer()
              Text(reviewedBy)
                .foregroundStyle(.secondary)
            }
          }
        }

        if let reviewNotes = request.reviewNotes, !reviewNotes.isEmpty {
          Section("Review Notes") {
            Text(reviewNotes)
          }
        }
      }
      .navigationTitle("Request Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    TimeOffView()
  }
}
