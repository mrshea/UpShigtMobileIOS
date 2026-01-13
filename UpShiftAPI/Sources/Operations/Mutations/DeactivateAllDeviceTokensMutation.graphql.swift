// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct DeactivateAllDeviceTokensMutation: GraphQLMutation {
  public static let operationName: String = "DeactivateAllDeviceTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation DeactivateAllDeviceTokens { deactivateAllDeviceTokens { __typename success message } }"#
    ))

  public init() {}

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("deactivateAllDeviceTokens", DeactivateAllDeviceTokens.self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      DeactivateAllDeviceTokensMutation.Data.self
    ] }

    public var deactivateAllDeviceTokens: DeactivateAllDeviceTokens { __data["deactivateAllDeviceTokens"] }

    /// DeactivateAllDeviceTokens
    ///
    /// Parent Type: `DeviceTokenResponse`
    public struct DeactivateAllDeviceTokens: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DeviceTokenResponse }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("success", Bool.self),
        .field("message", String?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeactivateAllDeviceTokensMutation.Data.DeactivateAllDeviceTokens.self
      ] }

      public var success: Bool { __data["success"] }
      public var message: String? { __data["message"] }
    }
  }
}
