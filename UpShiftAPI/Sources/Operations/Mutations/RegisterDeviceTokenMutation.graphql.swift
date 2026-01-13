// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct RegisterDeviceTokenMutation: GraphQLMutation {
  public static let operationName: String = "RegisterDeviceToken"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation RegisterDeviceToken($token: String!, $platform: Platform!) { registerDeviceToken(token: $token, platform: $platform) { __typename success message deviceToken { __typename id platform isActive createdAt updatedAt } } }"#
    ))

  public var token: String
  public var platform: GraphQLEnum<Platform>

  public init(
    token: String,
    platform: GraphQLEnum<Platform>
  ) {
    self.token = token
    self.platform = platform
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "token": token,
    "platform": platform
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("registerDeviceToken", RegisterDeviceToken.self, arguments: [
        "token": .variable("token"),
        "platform": .variable("platform")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      RegisterDeviceTokenMutation.Data.self
    ] }

    public var registerDeviceToken: RegisterDeviceToken { __data["registerDeviceToken"] }

    /// RegisterDeviceToken
    ///
    /// Parent Type: `DeviceTokenResponse`
    public struct RegisterDeviceToken: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DeviceTokenResponse }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("success", Bool.self),
        .field("message", String?.self),
        .field("deviceToken", DeviceToken?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterDeviceTokenMutation.Data.RegisterDeviceToken.self
      ] }

      public var success: Bool { __data["success"] }
      public var message: String? { __data["message"] }
      public var deviceToken: DeviceToken? { __data["deviceToken"] }

      /// RegisterDeviceToken.DeviceToken
      ///
      /// Parent Type: `DeviceToken`
      public struct DeviceToken: UpShiftAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DeviceToken }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", UpShiftAPI.ID.self),
          .field("platform", GraphQLEnum<UpShiftAPI.Platform>.self),
          .field("isActive", Bool.self),
          .field("createdAt", UpShiftAPI.DateTime.self),
          .field("updatedAt", UpShiftAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterDeviceTokenMutation.Data.RegisterDeviceToken.DeviceToken.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var platform: GraphQLEnum<UpShiftAPI.Platform> { __data["platform"] }
        public var isActive: Bool { __data["isActive"] }
        public var createdAt: UpShiftAPI.DateTime { __data["createdAt"] }
        public var updatedAt: UpShiftAPI.DateTime { __data["updatedAt"] }
      }
    }
  }
}
