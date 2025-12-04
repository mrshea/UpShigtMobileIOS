// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetMyTimeEntriesQuery: GraphQLQuery {
  public static let operationName: String = "GetMyTimeEntries"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetMyTimeEntries($startDate: DateTime, $endDate: DateTime) { myTimeEntries(startDate: $startDate, endDate: $endDate) { __typename id orgId shiftId shift { __typename id date startTime endTime role } clerkId clockInTime clockOutTime clockInLatitude clockInLongitude clockOutLatitude clockOutLongitude hoursWorked createdAt updatedAt } }"#
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
      .field("myTimeEntries", [MyTimeEntry].self, arguments: [
        "startDate": .variable("startDate"),
        "endDate": .variable("endDate")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetMyTimeEntriesQuery.Data.self
    ] }

    public var myTimeEntries: [MyTimeEntry] { __data["myTimeEntries"] }

    /// MyTimeEntry
    ///
    /// Parent Type: `TimeEntry`
    public struct MyTimeEntry: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.TimeEntry }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("orgId", String.self),
        .field("shiftId", String?.self),
        .field("shift", Shift?.self),
        .field("clerkId", String.self),
        .field("clockInTime", UpShiftAPI.DateTime.self),
        .field("clockOutTime", UpShiftAPI.DateTime?.self),
        .field("clockInLatitude", Double?.self),
        .field("clockInLongitude", Double?.self),
        .field("clockOutLatitude", Double?.self),
        .field("clockOutLongitude", Double?.self),
        .field("hoursWorked", Double?.self),
        .field("createdAt", UpShiftAPI.DateTime.self),
        .field("updatedAt", UpShiftAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMyTimeEntriesQuery.Data.MyTimeEntry.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var orgId: String { __data["orgId"] }
      public var shiftId: String? { __data["shiftId"] }
      public var shift: Shift? { __data["shift"] }
      public var clerkId: String { __data["clerkId"] }
      public var clockInTime: UpShiftAPI.DateTime { __data["clockInTime"] }
      public var clockOutTime: UpShiftAPI.DateTime? { __data["clockOutTime"] }
      public var clockInLatitude: Double? { __data["clockInLatitude"] }
      public var clockInLongitude: Double? { __data["clockInLongitude"] }
      public var clockOutLatitude: Double? { __data["clockOutLatitude"] }
      public var clockOutLongitude: Double? { __data["clockOutLongitude"] }
      public var hoursWorked: Double? { __data["hoursWorked"] }
      public var createdAt: UpShiftAPI.DateTime { __data["createdAt"] }
      public var updatedAt: UpShiftAPI.DateTime { __data["updatedAt"] }

      /// MyTimeEntry.Shift
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
          .field("role", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetMyTimeEntriesQuery.Data.MyTimeEntry.Shift.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var date: UpShiftAPI.DateTime { __data["date"] }
        public var startTime: String { __data["startTime"] }
        public var endTime: String { __data["endTime"] }
        public var role: String { __data["role"] }
      }
    }
  }
}
