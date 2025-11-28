// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct ClaimShiftMutation: GraphQLMutation {
  public static let operationName: String = "ClaimShift"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation ClaimShift($shiftId: ID!) { claimShift(shiftId: $shiftId) { __typename id shiftId claimedAt shift { __typename id date startTime endTime role } } }"#
    ))

  public var shiftId: ID

  public init(shiftId: ID) {
    self.shiftId = shiftId
  }

  @_spi(Unsafe) public var __variables: Variables? { ["shiftId": shiftId] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("claimShift", ClaimShift.self, arguments: ["shiftId": .variable("shiftId")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ClaimShiftMutation.Data.self
    ] }

    public var claimShift: ClaimShift { __data["claimShift"] }

    /// ClaimShift
    ///
    /// Parent Type: `ShiftClaim`
    public struct ClaimShift: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.ShiftClaim }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("shiftId", String.self),
        .field("claimedAt", UpShiftAPI.DateTime.self),
        .field("shift", Shift.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ClaimShiftMutation.Data.ClaimShift.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var shiftId: String { __data["shiftId"] }
      public var claimedAt: UpShiftAPI.DateTime { __data["claimedAt"] }
      public var shift: Shift { __data["shift"] }

      /// ClaimShift.Shift
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
          ClaimShiftMutation.Data.ClaimShift.Shift.self
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
