//
//  DepartmentViewModel.swift
//  UpShiftMobile
//
//  Created by Assistant on 12/10/25.
//

import Foundation
import Combine
import Apollo
import ApolloAPI
import UpShiftAPI

/// ViewModel for managing department data
/// Use this if you need to fetch and display departments in your UI
@MainActor
class DepartmentViewModel: ObservableObject {
  @Published var departments: [Department] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  
  private let apolloClient = Network.shared.apollo
  
  // MARK: - Fetch All Departments
  
  /// Fetches all departments for the current organization
  func fetchDepartments() async {
    isLoading = true
    errorMessage = nil
    
    do {
      // Note: You'll need to create a GetDepartmentsQuery in your GraphQL operations
      // Example query:
      // query GetDepartments {
      //   departments {
      //     id
      //     name
      //     description
      //     orgId
      //   }
      // }
      
      // Uncomment when GraphQL query is ready:
      /*
      let query = GetDepartmentsQuery()
      
      let result = try await withCheckedThrowingContinuation { continuation in
        apolloClient.fetch(
          query: query,
          cachePolicy: .fetchIgnoringCacheData
        ) { result in
          continuation.resume(with: result)
        }
      }
      
      if let data = result.data {
        self.departments = data.departments.map { dept in
          Department(
            id: dept.id,
            name: dept.name,
            description: dept.description,
            orgId: dept.orgId
          )
        }
        errorMessage = nil
      } else if let errors = result.errors, !errors.isEmpty {
        errorMessage = errors.first?.message ?? "Unknown error"
      }
      */
      
      // TODO: Remove this mock implementation after GraphQL query is ready
      print("⚠️ DepartmentViewModel: GraphQL query not implemented yet")
      errorMessage = "Department fetching not yet implemented"
      
    } catch {
      errorMessage = error.localizedDescription
      print("Error fetching departments: \(error)")
    }
    
    isLoading = false
  }
  
  // MARK: - Helper Methods
  
  /// Returns a department by its ID
  func department(withId id: String) -> Department? {
    departments.first { $0.id == id }
  }
  
  /// Returns departments sorted alphabetically by name
  var sortedDepartments: [Department] {
    departments.sorted { $0.name < $1.name }
  }
  
  /// Returns a unique list of department names
  var departmentNames: [String] {
    departments.map(\.name).sorted()
  }
}

// MARK: - Usage Example

/*
 
 // In your SwiftUI view:
 
 struct DepartmentPickerView: View {
   @StateObject private var viewModel = DepartmentViewModel()
   @Binding var selectedDepartmentId: String?
   
   var body: some View {
     NavigationStack {
       List {
         if viewModel.isLoading {
           ProgressView()
         } else if let error = viewModel.errorMessage {
           Text("Error: \(error)")
             .foregroundStyle(.red)
         } else {
           ForEach(viewModel.sortedDepartments) { department in
             Button {
               selectedDepartmentId = department.id
             } label: {
               VStack(alignment: .leading) {
                 Text(department.name)
                   .font(.headline)
                 
                 if let description = department.description {
                   Text(description)
                     .font(.caption)
                     .foregroundStyle(.secondary)
                 }
               }
             }
           }
         }
       }
       .navigationTitle("Select Department")
       .task {
         await viewModel.fetchDepartments()
       }
     }
   }
 }
 
 // In AvailableShifts for department filtering:
 
 struct AvailableShifts: View {
   @StateObject private var shiftViewModel = ShiftViewModel()
   @StateObject private var departmentViewModel = DepartmentViewModel()
   @State private var selectedDepartmentId: String? = nil
   
   var filteredShifts: [Shift] {
     shiftViewModel.shifts.filter { shift in
       guard let selectedId = selectedDepartmentId else { return true }
       return shift.departmentId == selectedId
     }
   }
   
   var body: some View {
     VStack {
       // Department filter picker
       if !departmentViewModel.departments.isEmpty {
         Picker("Department", selection: $selectedDepartmentId) {
           Text("All Departments").tag(nil as String?)
           ForEach(departmentViewModel.sortedDepartments) { dept in
             Text(dept.name).tag(dept.id as String?)
           }
         }
         .pickerStyle(.menu)
       }
       
       // Shifts list...
     }
     .task {
       await departmentViewModel.fetchDepartments()
     }
   }
 }
 
 */
