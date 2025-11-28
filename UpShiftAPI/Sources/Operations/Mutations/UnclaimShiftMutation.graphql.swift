// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct UnclaimShiftMutation: GraphQLMutation {
  public static let operationName: String = "UnclaimShift"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UnclaimShift($shiftId: ID!) { unclaimShift(shiftId: $shiftId) }"#
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
      .field("unclaimShift", Bool.self, arguments: ["shiftId": .variable("shiftId")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      UnclaimShiftMutation.Data.self
    ] }

    public var unclaimShift: Bool { __data["unclaimShift"] }
  }
}
