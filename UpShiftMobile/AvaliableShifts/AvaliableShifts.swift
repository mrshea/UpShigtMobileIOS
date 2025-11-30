import SwiftUI

struct AvaliableShifts: View {
  @StateObject private var viewModel = ShiftViewModel()
  @State private var selectedRole: String = "All"
  @State private var searchText = ""
  @State private var showClaimedAlert = false
  @State private var claimedShift: Shift?
  @State private var selectedDateRange: DateRange = .thisWeek
  @Environment(\.calendar) var calendar
  
  enum DateRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case all = "All"
    
    func dateRange(calendar: Calendar) -> ClosedRange<Date> {
      let now = Date()
      switch self {
      case .today:
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return start...end
      case .thisWeek:
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
          return now...now
        }
        return weekInterval.start...weekInterval.end
      case .nextWeek:
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: nextWeekStart) else {
          return now...now
        }
        return weekInterval.start...weekInterval.end
      case .all:
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .month, value: 3, to: start) ?? now
        return start...end
      }
    }
  }
  
  var availableRoles: [String] {
    var roles = Set<String>()
    roles.insert("All")
    viewModel.shifts.forEach { roles.insert($0.role) }
    return Array(roles).sorted()
  }
  
  var filteredShifts: [Shift] {
    viewModel.shifts.filter { shift in
      // Filter by role
      let matchesRole = selectedRole == "All" || shift.role == selectedRole
      
      // Filter by search
      let matchesSearch = searchText.isEmpty || 
        shift.role.localizedCaseInsensitiveContains(searchText)
      
      // Filter out full shifts
      let notFull = !shift.isFull
      
      return matchesRole && matchesSearch && notFull
    }
  }
  
  // Group shifts by date
  var groupedShifts: [(date: Date, shifts: [Shift])] {
    let grouped = Dictionary(grouping: filteredShifts) { shift in
      calendar.startOfDay(for: shift.date)
    }
    
    return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, shifts: $0.value) }
  }
  
  var dateRangeText: String {
    let range = selectedDateRange.dateRange(calendar: calendar)
    let formatter = DateFormatter()
    
    switch selectedDateRange {
    case .today:
      formatter.dateStyle = .full
      return formatter.string(from: range.lowerBound)
      
    case .thisWeek, .nextWeek:
      formatter.dateFormat = "MMM d"
      let startString = formatter.string(from: range.lowerBound)
      let endDate = calendar.date(byAdding: .day, value: -1, to: range.upperBound) ?? range.upperBound
      
      // Check if dates are in the same month
      let startMonth = calendar.component(.month, from: range.lowerBound)
      let endMonth = calendar.component(.month, from: endDate)
      
      if startMonth == endMonth {
        formatter.dateFormat = "d"
        let endDay = formatter.string(from: endDate)
        return "\(startString) - \(endDay)"
      } else {
        let endString = formatter.string(from: endDate)
        return "\(startString) - \(endString)"
      }
      
    case .all:
      formatter.dateFormat = "MMM d"
      let startString = formatter.string(from: range.lowerBound)
      let endDate = calendar.date(byAdding: .day, value: -1, to: range.upperBound) ?? range.upperBound
      let endString = formatter.string(from: endDate)
      
      // Check if dates are in the same year
      let startYear = calendar.component(.year, from: range.lowerBound)
      let endYear = calendar.component(.year, from: endDate)
      
      if startYear != endYear {
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: endDate))"
      }
      
      return "\(startString) - \(endString)"
    }
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Date Range Filter
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(DateRange.allCases, id: \.self) { range in
              FilterChip(
                title: range.rawValue,
                isSelected: selectedDateRange == range
              ) {
                withAnimation {
                  selectedDateRange = range
                  Task {
                    await loadShifts()
                  }
                }
              }
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        
        // Date Range Display
        HStack {
          Image(systemName: "calendar")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text(dateRangeText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        
        Divider()
        
        // Role Filter
        if !availableRoles.isEmpty && availableRoles.count > 2 {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(availableRoles, id: \.self) { role in
                FilterChip(
                  title: role,
                  isSelected: selectedRole == role
                ) {
                  withAnimation {
                    selectedRole = role
                  }
                }
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
          }
          .background(Color(.systemBackground))
          
          Divider()
        }
        
        // Content
        if viewModel.isLoading {
          VStack(spacing: 16) {
            ProgressView()
            Text("Loading available shifts...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
          ErrorStateView(error: error) {
            Task { await loadShifts() }
          }
        } else if filteredShifts.isEmpty {
          EmptyStateView()
        } else {
          ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
              ForEach(groupedShifts, id: \.date) { dateGroup in
                Section {
                  ForEach(dateGroup.shifts) { shift in
                    AvailableShiftCard(shift: shift) {
                      Task {
                        await claimShift(shift)
                      }
                    }
                  }
                } header: {
                  HStack {
                    Text(dateGroup.date, style: .date)
                      .font(.headline)
                      .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(dateGroup.shifts.count) shift\(dateGroup.shifts.count == 1 ? "" : "s")")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 8)
                  .background(Color(.systemBackground))
                }
              }
            }
            .padding()
          }
          .refreshable {
              await loadShifts()
          }
        }
      }
      .navigationTitle("Available Shifts")
      .searchable(text: $searchText, prompt: "Search roles")
      .alert("Shift Claimed!", isPresented: $showClaimedAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        if let shift = claimedShift {
          Text("You've successfully claimed the \(shift.role) shift on \(shift.date.formatted(date: .abbreviated, time: .omitted))")
        }
      }
      .task {
        await loadShifts()
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func loadShifts() async {
    let dateRange = selectedDateRange.dateRange(calendar: calendar)
    print("🔄 Loading shifts from \(dateRange.lowerBound) to \(dateRange.upperBound)")
    await viewModel.fetchShifts(startDate: dateRange.lowerBound, endDate: dateRange.upperBound)
    print("✅ Loaded \(viewModel.shifts.count) total shifts")
  }
  
  private func claimShift(_ shift: Shift) async {
    do {
      try await viewModel.claimShift(shiftId: shift.id)
      claimedShift = shift
      showClaimedAlert = true
      await loadShifts()
    } catch {
      viewModel.errorMessage = error.localizedDescription
    }
  }
}

// MARK: - Filter Chip
struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color(.systemGray6))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(Capsule())
    }
  }
}

// MARK: - Available Shift Card
struct AvailableShiftCard: View {
  let shift: Shift
  let onClaim: () -> Void
  
  var urgencyLevel: (color: Color, label: String) {
    if shift.availableSpots == 1 {
      return (.red, "Critical - Last Spot!")
    } else if shift.availableSpots <= 3 {
      return (.orange, "Urgent - Few Spots Left")
    } else {
      return (.blue, "Available")
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(shift.role)
            .font(.headline)
          
          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.caption)
            Text("\(shift.startTime) - \(shift.endTime)")
              .font(.subheadline)
          }
          .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        // Urgency Badge
        Text(urgencyLevel.label)
          .font(.caption.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(urgencyLevel.color.opacity(0.2))
          .foregroundStyle(urgencyLevel.color)
          .clipShape(Capsule())
      }
      
      Divider()
      
      // Shift Details
      HStack(spacing: 20) {
        DetailItem(
          icon: "calendar",
          title: "Date",
          value: shift.date.formatted(date: .abbreviated, time: .omitted)
        )
        
        DetailItem(
          icon: "person.2",
          title: "Spots",
          value: "\(shift.availableSpots)/\(shift.peopleNeeded)"
        )
      }
      
      // Already claimed by
      if let claimedBy = shift.claimedBy, !claimedBy.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("Already Claimed By:")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          ForEach(claimedBy.prefix(3)) { employee in
            HStack(spacing: 6) {
              Image(systemName: "person.circle.fill")
                .font(.caption2)
                .foregroundStyle(.blue)
              
              Text(employee.employeeName ?? employee.employeeEmail ?? "Unknown")
                .font(.caption)
            }
          }
          
          if claimedBy.count > 3 {
            Text("and \(claimedBy.count - 3) more...")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.top, 4)
      }
      
      // Claim Button
      Button(action: onClaim) {
        HStack {
          Image(systemName: "hand.raised.fill")
          Text("Claim This Shift")
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Detail Item
struct DetailItem: View {
  let icon: String
  let title: String
  let value: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Label(title, systemImage: icon)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.subheadline.weight(.medium))
    }
  }
}

// MARK: - Empty State
struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "calendar.badge.clock")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)
      
      Text("No Shifts Available")
        .font(.title2.weight(.semibold))
      
      Text("Check back later for new opportunities or adjust your filters")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Error State
struct ErrorStateView: View {
  let error: String
  let onRetry: () -> Void
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundStyle(.orange)
      
      Text("Error Loading Shifts")
        .font(.title2.weight(.semibold))
      
      Text(error)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
      Button("Retry") {
        onRetry()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
