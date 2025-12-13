// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetClockStatusQuery: GraphQLQuery {
  public static let operationName: String = "GetClockStatus"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetClockStatus { clockStatus { __typename isClockedIn activeEntry { __typename id shiftId clerkId clockInTime clockOutTime shift { __typename id date startTime endTime departmentId department { __typename id name description orgId } } } } }"#
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
          .field("shiftId", String?.self),
          .field("clerkId", String.self),
          .field("clockInTime", UpShiftAPI.DateTime.self),
          .field("clockOutTime", UpShiftAPI.DateTime?.self),
          .field("shift", Shift?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetClockStatusQuery.Data.ClockStatus.ActiveEntry.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var shiftId: String? { __data["shiftId"] }
        public var clerkId: String { __data["clerkId"] }
        public var clockInTime: UpShiftAPI.DateTime { __data["clockInTime"] }
        public var clockOutTime: UpShiftAPI.DateTime? { __data["clockOutTime"] }
        public var shift: Shift? { __data["shift"] }

        /// ClockStatus.ActiveEntry.Shift
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
            .field("departmentId", String?.self),
            .field("department", Department?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetClockStatusQuery.Data.ClockStatus.ActiveEntry.Shift.self
          ] }

          public var id: UpShiftAPI.ID { __data["id"] }
          public var date: UpShiftAPI.DateTime { __data["date"] }
          public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
          public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
          public var departmentId: String? { __data["departmentId"] }
          public var department: Department? { __data["department"] }

          /// ClockStatus.ActiveEntry.Shift.Department
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
              .field("description", String?.self),
              .field("orgId", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetClockStatusQuery.Data.ClockStatus.ActiveEntry.Shift.Department.self
            ] }

            public var id: UpShiftAPI.ID { __data["id"] }
            public var name: String { __data["name"] }
            public var description: String? { __data["description"] }
            public var orgId: String { __data["orgId"] }
          }
        }
      }
    }
  }
}
