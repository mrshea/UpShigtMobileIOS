// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct UpdateDropShiftRequestStatusMutation: GraphQLMutation {
  public static let operationName: String = "UpdateDropShiftRequestStatus"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UpdateDropShiftRequestStatus($requestId: String!, $status: String!, $managerNotes: String) { updateDropShiftRequestStatus( requestId: $requestId status: $status managerNotes: $managerNotes ) { __typename id status reviewedDate approvedBy managerNotes } }"#
    ))

  public var requestId: String
  public var status: String
  public var managerNotes: GraphQLNullable<String>

  public init(
    requestId: String,
    status: String,
    managerNotes: GraphQLNullable<String>
  ) {
    self.requestId = requestId
    self.status = status
    self.managerNotes = managerNotes
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "requestId": requestId,
    "status": status,
    "managerNotes": managerNotes
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("updateDropShiftRequestStatus", UpdateDropShiftRequestStatus.self, arguments: [
        "requestId": .variable("requestId"),
        "status": .variable("status"),
        "managerNotes": .variable("managerNotes")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      UpdateDropShiftRequestStatusMutation.Data.self
    ] }

    public var updateDropShiftRequestStatus: UpdateDropShiftRequestStatus { __data["updateDropShiftRequestStatus"] }

    /// UpdateDropShiftRequestStatus
    ///
    /// Parent Type: `DropShiftRequest`
    public struct UpdateDropShiftRequestStatus: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DropShiftRequest }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("status", String.self),
        .field("reviewedDate", UpShiftAPI.DateTime?.self),
        .field("approvedBy", String?.self),
        .field("managerNotes", String?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateDropShiftRequestStatusMutation.Data.UpdateDropShiftRequestStatus.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var status: String { __data["status"] }
      public var reviewedDate: UpShiftAPI.DateTime? { __data["reviewedDate"] }
      public var approvedBy: String? { __data["approvedBy"] }
      public var managerNotes: String? { __data["managerNotes"] }
    }
  }
}
