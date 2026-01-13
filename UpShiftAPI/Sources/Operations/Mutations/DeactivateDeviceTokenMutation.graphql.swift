// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct DeactivateDeviceTokenMutation: GraphQLMutation {
  public static let operationName: String = "DeactivateDeviceToken"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation DeactivateDeviceToken($token: String!) { deactivateDeviceToken(token: $token) { __typename success message } }"#
    ))

  public var token: String

  public init(token: String) {
    self.token = token
  }

  @_spi(Unsafe) public var __variables: Variables? { ["token": token] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("deactivateDeviceToken", DeactivateDeviceToken.self, arguments: ["token": .variable("token")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      DeactivateDeviceTokenMutation.Data.self
    ] }

    public var deactivateDeviceToken: DeactivateDeviceToken { __data["deactivateDeviceToken"] }

    /// DeactivateDeviceToken
    ///
    /// Parent Type: `DeviceTokenResponse`
    public struct DeactivateDeviceToken: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DeviceTokenResponse }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("success", Bool.self),
        .field("message", String?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeactivateDeviceTokenMutation.Data.DeactivateDeviceToken.self
      ] }

      public var success: Bool { __data["success"] }
      public var message: String? { __data["message"] }
    }
  }
}
