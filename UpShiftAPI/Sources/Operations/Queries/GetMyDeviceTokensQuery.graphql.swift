// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct GetMyDeviceTokensQuery: GraphQLQuery {
  public static let operationName: String = "GetMyDeviceTokens"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetMyDeviceTokens { myDeviceTokens { __typename id platform isActive createdAt updatedAt } }"#
    ))

  public init() {}

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("myDeviceTokens", [MyDeviceToken].self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      GetMyDeviceTokensQuery.Data.self
    ] }

    public var myDeviceTokens: [MyDeviceToken] { __data["myDeviceTokens"] }

    /// MyDeviceToken
    ///
    /// Parent Type: `DeviceToken`
    public struct MyDeviceToken: UpShiftAPI.SelectionSet {
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
        GetMyDeviceTokensQuery.Data.MyDeviceToken.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var platform: GraphQLEnum<UpShiftAPI.Platform> { __data["platform"] }
      public var isActive: Bool { __data["isActive"] }
      public var createdAt: UpShiftAPI.DateTime { __data["createdAt"] }
      public var updatedAt: UpShiftAPI.DateTime { __data["updatedAt"] }
    }
  }
}
