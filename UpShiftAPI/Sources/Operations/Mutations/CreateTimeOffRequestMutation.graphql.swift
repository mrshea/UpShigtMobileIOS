// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct CreateTimeOffRequestMutation: GraphQLMutation {
  public static let operationName: String = "CreateTimeOffRequest"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation CreateTimeOffRequest($startTime: DateTime!, $endTime: DateTime!, $employeeNotes: String) { createTimeOffRequest( startTime: $startTime endTime: $endTime employeeNotes: $employeeNotes ) { __typename id startTime endTime employeeNotes status submittedDate } }"#
    ))

  public var startTime: DateTime
  public var endTime: DateTime
  public var employeeNotes: GraphQLNullable<String>

  public init(
    startTime: DateTime,
    endTime: DateTime,
    employeeNotes: GraphQLNullable<String>
  ) {
    self.startTime = startTime
    self.endTime = endTime
    self.employeeNotes = employeeNotes
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "startTime": startTime,
    "endTime": endTime,
    "employeeNotes": employeeNotes
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("createTimeOffRequest", CreateTimeOffRequest.self, arguments: [
        "startTime": .variable("startTime"),
        "endTime": .variable("endTime"),
        "employeeNotes": .variable("employeeNotes")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CreateTimeOffRequestMutation.Data.self
    ] }

    public var createTimeOffRequest: CreateTimeOffRequest { __data["createTimeOffRequest"] }

    /// CreateTimeOffRequest
    ///
    /// Parent Type: `TimeOffRequest`
    public struct CreateTimeOffRequest: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.TimeOffRequest }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("startTime", UpShiftAPI.DateTime.self),
        .field("endTime", UpShiftAPI.DateTime.self),
        .field("employeeNotes", String?.self),
        .field("status", String.self),
        .field("submittedDate", UpShiftAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateTimeOffRequestMutation.Data.CreateTimeOffRequest.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
      public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
      public var employeeNotes: String? { __data["employeeNotes"] }
      public var status: String { __data["status"] }
      public var submittedDate: UpShiftAPI.DateTime { __data["submittedDate"] }
    }
  }
}
