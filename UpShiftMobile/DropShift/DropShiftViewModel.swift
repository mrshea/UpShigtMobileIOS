import Foundation
import Combine
import Apollo
import ApolloAPI
import UpShiftAPI

@MainActor
class DropShiftViewModel: ObservableObject {
    @Published var requests: [DropShiftRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apolloClient = Network.shared.apollo

    // MARK: - Fetch Drop Shift Requests
    func loadRequests(useCache: Bool = true) async {
        if requests.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            let query = GetMyDropShiftRequestsQuery()
            if useCache {
                for try await result in try apolloClient.fetch(query: query, cachePolicy: .cacheAndNetwork) {
                    if let data = result.data {
                        self.requests = processRequests(data.myDropShiftRequests)
                        errorMessage = nil
                    }
                }
            } else {
                let result = try await apolloClient.fetch(query: query, cachePolicy: .networkOnly)
                if let data = result.data {
                    self.requests = processRequests(data.myDropShiftRequests)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching drop shift requests: \(error)")
        }
        isLoading = false
    }

    private func processRequests(_ gqlRequests: [GetMyDropShiftRequestsQuery.Data.MyDropShiftRequest]) -> [DropShiftRequest] {
        return gqlRequests.compactMap { gql in
            guard let shift = gql.shift,
                  let submittedAt = gql.submittedDate.toDate(),
                  let shiftDate = shift.date.toDate(),
                  let startTime = shift.startTime.toDate(),
                  let endTime = shift.endTime.toDate() else { return nil }

            let status: DropShiftRequest.Status
            switch gql.status.lowercased() {
            case "approved": status = .approved
            case "denied": status = .denied
            default: status = .pending
            }

            return DropShiftRequest(
                id: gql.id,
                shiftId: gql.shiftId,
                status: status,
                employeeNotes: gql.employeeNotes,
                managerNotes: gql.managerNotes,
                submittedAt: submittedAt,
                reviewedAt: gql.reviewedDate?.toDate(),
                approvedBy: nil,
                shift: DropShiftRequest.ShiftSummary(
                    id: shift.id,
                    date: shiftDate,
                    startTime: startTime,
                    endTime: endTime,
                    departmentName: shift.department?.name ?? ""
                )
            )
        }
    }

    // MARK: - Submit New Request
    func submitRequest(shiftId: String, employeeNotes: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            let notes: GraphQLNullable<String> = employeeNotes.map { .some($0) } ?? .null
            let mutation = CreateDropShiftRequestMutation(shiftId: shiftId, employeeNotes: notes)
            let result = try await apolloClient.perform(mutation: mutation)
            if let error = result.errors?.first {
                throw NSError(domain: "DropShiftViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: error.message ?? "Unknown error"])
            }
            try? await apolloClient.store.clearCache()
            await loadRequests(useCache: false)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete Request
    func deleteRequest(id: String) async throws {
        let mutation = DeleteDropShiftRequestMutation(id: id)
        let result = try await apolloClient.perform(mutation: mutation)
        if let error = result.errors?.first {
            throw NSError(domain: "DropShiftViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: error.message ?? "Unknown error"])
        }
        try? await apolloClient.store.clearCache()
        await loadRequests(useCache: false)
    }
}
