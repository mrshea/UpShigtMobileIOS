// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct ClockOutMutation: GraphQLMutation {
  public static let operationName: String = "ClockOut"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation ClockOut($latitude: Float, $longitude: Float) { clockOut(latitude: $latitude, longitude: $longitude) { __typename id shiftId clerkId clockInTime clockOutTime shift { __typename id date startTime endTime departmentId department { __typename id name description orgId } } } }"#
    ))

  public var latitude: GraphQLNullable<Double>
  public var longitude: GraphQLNullable<Double>

  public init(
    latitude: GraphQLNullable<Double>,
    longitude: GraphQLNullable<Double>
  ) {
    self.latitude = latitude
    self.longitude = longitude
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "latitude": latitude,
    "longitude": longitude
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("clockOut", ClockOut.self, arguments: [
        "latitude": .variable("latitude"),
        "longitude": .variable("longitude")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ClockOutMutation.Data.self
    ] }

    public var clockOut: ClockOut { __data["clockOut"] }

    /// ClockOut
    ///
    /// Parent Type: `TimeEntry`
    public struct ClockOut: UpShiftAPI.SelectionSet {
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
        ClockOutMutation.Data.ClockOut.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var shiftId: String? { __data["shiftId"] }
      public var clerkId: String { __data["clerkId"] }
      public var clockInTime: UpShiftAPI.DateTime { __data["clockInTime"] }
      public var clockOutTime: UpShiftAPI.DateTime? { __data["clockOutTime"] }
      public var shift: Shift? { __data["shift"] }

      /// ClockOut.Shift
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
          ClockOutMutation.Data.ClockOut.Shift.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var date: UpShiftAPI.DateTime { __data["date"] }
        public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
        public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
        public var departmentId: String? { __data["departmentId"] }
        public var department: Department? { __data["department"] }

        /// ClockOut.Shift.Department
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
            ClockOutMutation.Data.ClockOut.Shift.Department.self
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
