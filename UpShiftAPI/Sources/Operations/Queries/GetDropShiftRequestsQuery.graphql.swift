// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetDropShiftRequestsQuery: GraphQLQuery {
  public static let operationName: String = "GetDropShiftRequests"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetDropShiftRequests { dropShiftRequests(isAdmin: true) { __typename id clerkId shiftId status employeeNotes managerNotes submittedDate reviewedDate approvedBy employeeName employeeEmail shift { __typename id date startTime endTime department { __typename id name } } } }"#
    ))

  public init() {}

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("dropShiftRequests", [DropShiftRequest].self, arguments: ["isAdmin": true]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetDropShiftRequestsQuery.Data.self
    ] }

    public var dropShiftRequests: [DropShiftRequest] { __data["dropShiftRequests"] }

    /// DropShiftRequest
    ///
    /// Parent Type: `DropShiftRequest`
    public struct DropShiftRequest: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DropShiftRequest }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("clerkId", String.self),
        .field("shiftId", String.self),
        .field("status", String.self),
        .field("employeeNotes", String?.self),
        .field("managerNotes", String?.self),
        .field("submittedDate", UpShiftAPI.DateTime.self),
        .field("reviewedDate", UpShiftAPI.DateTime?.self),
        .field("approvedBy", String?.self),
        .field("employeeName", String?.self),
        .field("employeeEmail", String?.self),
        .field("shift", Shift?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetDropShiftRequestsQuery.Data.DropShiftRequest.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var clerkId: String { __data["clerkId"] }
      public var shiftId: String { __data["shiftId"] }
      public var status: String { __data["status"] }
      public var employeeNotes: String? { __data["employeeNotes"] }
      public var managerNotes: String? { __data["managerNotes"] }
      public var submittedDate: UpShiftAPI.DateTime { __data["submittedDate"] }
      public var reviewedDate: UpShiftAPI.DateTime? { __data["reviewedDate"] }
      public var approvedBy: String? { __data["approvedBy"] }
      public var employeeName: String? { __data["employeeName"] }
      public var employeeEmail: String? { __data["employeeEmail"] }
      public var shift: Shift? { __data["shift"] }

      /// DropShiftRequest.Shift
      ///
      /// Parent Type: `Shift`
      public struct Shift: UpShiftAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Shift }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", UpShiftAPI.ID.self),
          .field("date", UpShiftAPI.DateTime.self),
          .field("startTime", UpShiftAPI.DateTime.self),
          .field("endTime", UpShiftAPI.DateTime.self),
          .field("department", Department?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetDropShiftRequestsQuery.Data.DropShiftRequest.Shift.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var date: UpShiftAPI.DateTime { __data["date"] }
        public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
        public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
        public var department: Department? { __data["department"] }

        /// DropShiftRequest.Shift.Department
        ///
        /// Parent Type: `Department`
        public struct Department: UpShiftAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Department }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", UpShiftAPI.ID.self),
            .field("name", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetDropShiftRequestsQuery.Data.DropShiftRequest.Shift.Department.self
          ] }

          public var id: UpShiftAPI.ID { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }
}
