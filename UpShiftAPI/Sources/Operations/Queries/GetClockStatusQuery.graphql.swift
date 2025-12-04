// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetClockStatusQuery: GraphQLQuery {
  public static let operationName: String = "GetClockStatus"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetClockStatus { clockStatus { __typename isClockedIn activeEntry { __typename id orgId shiftId clerkId clockInTime clockOutTime clockInLatitude clockInLongitude clockOutLatitude clockOutLongitude hoursWorked createdAt updatedAt } } }"#
    ))

  public init() {}

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("clockStatus", ClockStatus.self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetClockStatusQuery.Data.self
    ] }

    public var clockStatus: ClockStatus { __data["clockStatus"] }

    /// ClockStatus
    ///
    /// Parent Type: `ClockStatus`
    public struct ClockStatus: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.ClockStatus }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("isClockedIn", Bool.self),
        .field("activeEntry", ActiveEntry?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetClockStatusQuery.Data.ClockStatus.self
      ] }

      public var isClockedIn: Bool { __data["isClockedIn"] }
      public var activeEntry: ActiveEntry? { __data["activeEntry"] }

      /// ClockStatus.ActiveEntry
      ///
      /// Parent Type: `TimeEntry`
      public struct ActiveEntry: UpShiftAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.TimeEntry }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", UpShiftAPI.ID.self),
          .field("orgId", String.self),
          .field("shiftId", String?.self),
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
          GetClockStatusQuery.Data.ClockStatus.ActiveEntry.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var orgId: String { __data["orgId"] }
        public var shiftId: String? { __data["shiftId"] }
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
      }
    }
  }
}
