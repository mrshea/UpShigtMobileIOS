// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetShiftsQuery: GraphQLQuery {
  public static let operationName: String = "GetShifts"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetShifts($startDate: DateTime, $endDate: DateTime) { shifts(startDate: $startDate, endDate: $endDate) { __typename id date startTime endTime peopleNeeded role availableSpots claimedBy { __typename id clerkId employeeName employeeEmail } } }"#
    ))

  public var startDate: GraphQLNullable<DateTime>
  public var endDate: GraphQLNullable<DateTime>

  public init(
    startDate: GraphQLNullable<DateTime>,
    endDate: GraphQLNullable<DateTime>
  ) {
    self.startDate = startDate
    self.endDate = endDate
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "startDate": startDate,
    "endDate": endDate
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("shifts", [Shift].self, arguments: [
        "startDate": .variable("startDate"),
        "endDate": .variable("endDate")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetShiftsQuery.Data.self
    ] }

    public var shifts: [Shift] { __data["shifts"] }

    /// Shift
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
        .field("startTime", String.self),
        .field("endTime", String.self),
        .field("peopleNeeded", Int.self),
        .field("role", String.self),
        .field("availableSpots", Int.self),
        .field("claimedBy", [ClaimedBy].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetShiftsQuery.Data.Shift.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var date: UpShiftAPI.DateTime { __data["date"] }
      public var startTime: String { __data["startTime"] }
      public var endTime: String { __data["endTime"] }
      public var peopleNeeded: Int { __data["peopleNeeded"] }
      public var role: String { __data["role"] }
      public var availableSpots: Int { __data["availableSpots"] }
      public var claimedBy: [ClaimedBy] { __data["claimedBy"] }

      /// Shift.ClaimedBy
      ///
      /// Parent Type: `ShiftClaim`
      public struct ClaimedBy: UpShiftAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.ShiftClaim }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", UpShiftAPI.ID.self),
          .field("clerkId", String.self),
          .field("employeeName", String?.self),
          .field("employeeEmail", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetShiftsQuery.Data.Shift.ClaimedBy.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var clerkId: String { __data["clerkId"] }
        public var employeeName: String? { __data["employeeName"] }
        public var employeeEmail: String? { __data["employeeEmail"] }
      }
    }
  }
}
