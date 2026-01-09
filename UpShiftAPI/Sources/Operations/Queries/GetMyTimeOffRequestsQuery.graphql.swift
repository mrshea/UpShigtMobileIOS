// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetMyTimeOffRequestsQuery: GraphQLQuery {
  public static let operationName: String = "GetMyTimeOffRequests"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetMyTimeOffRequests { myTimeOffRequests { __typename id startTime endTime status employeeNotes managerNotes submittedDate reviewedDate approvedBy createdAt updatedAt } }"#
    ))

  public init() {}

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("myTimeOffRequests", [MyTimeOffRequest].self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetMyTimeOffRequestsQuery.Data.self
    ] }

    public var myTimeOffRequests: [MyTimeOffRequest] { __data["myTimeOffRequests"] }

    /// MyTimeOffRequest
    ///
    /// Parent Type: `TimeOffRequest`
    public struct MyTimeOffRequest: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.TimeOffRequest }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("startTime", UpShiftAPI.DateTime.self),
        .field("endTime", UpShiftAPI.DateTime.self),
        .field("status", String.self),
        .field("employeeNotes", String?.self),
        .field("managerNotes", String?.self),
        .field("submittedDate", UpShiftAPI.DateTime.self),
        .field("reviewedDate", UpShiftAPI.DateTime?.self),
        .field("approvedBy", String?.self),
        .field("createdAt", UpShiftAPI.DateTime.self),
        .field("updatedAt", UpShiftAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMyTimeOffRequestsQuery.Data.MyTimeOffRequest.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
      public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
      public var status: String { __data["status"] }
      public var employeeNotes: String? { __data["employeeNotes"] }
      public var managerNotes: String? { __data["managerNotes"] }
      public var submittedDate: UpShiftAPI.DateTime { __data["submittedDate"] }
      public var reviewedDate: UpShiftAPI.DateTime? { __data["reviewedDate"] }
      public var approvedBy: String? { __data["approvedBy"] }
      public var createdAt: UpShiftAPI.DateTime { __data["createdAt"] }
      public var updatedAt: UpShiftAPI.DateTime { __data["updatedAt"] }
    }
  }
}
