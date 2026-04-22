// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct CreateDropShiftRequestMutation: GraphQLMutation {
  public static let operationName: String = "CreateDropShiftRequest"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation CreateDropShiftRequest($shiftId: String!, $employeeNotes: String) { createDropShiftRequest(shiftId: $shiftId, employeeNotes: $employeeNotes) { __typename id status submittedDate shift { __typename id date startTime endTime department { __typename name } } } }"#
    ))

  public var shiftId: String
  public var employeeNotes: GraphQLNullable<String>

  public init(
    shiftId: String,
    employeeNotes: GraphQLNullable<String>
  ) {
    self.shiftId = shiftId
    self.employeeNotes = employeeNotes
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "shiftId": shiftId,
    "employeeNotes": employeeNotes
  ] }

  public struct Data: UpShiftAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("createDropShiftRequest", CreateDropShiftRequest.self, arguments: [
        "shiftId": .variable("shiftId"),
        "employeeNotes": .variable("employeeNotes")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      CreateDropShiftRequestMutation.Data.self
    ] }

    public var createDropShiftRequest: CreateDropShiftRequest { __data["createDropShiftRequest"] }

    /// CreateDropShiftRequest
    ///
    /// Parent Type: `DropShiftRequest`
    public struct CreateDropShiftRequest: UpShiftAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.DropShiftRequest }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", UpShiftAPI.ID.self),
        .field("status", String.self),
        .field("submittedDate", UpShiftAPI.DateTime.self),
        .field("shift", Shift?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateDropShiftRequestMutation.Data.CreateDropShiftRequest.self
      ] }

      public var id: UpShiftAPI.ID { __data["id"] }
      public var status: String { __data["status"] }
      public var submittedDate: UpShiftAPI.DateTime { __data["submittedDate"] }
      public var shift: Shift? { __data["shift"] }

      /// CreateDropShiftRequest.Shift
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
          .field("department", Department?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateDropShiftRequestMutation.Data.CreateDropShiftRequest.Shift.self
        ] }

        public var id: UpShiftAPI.ID { __data["id"] }
        public var date: UpShiftAPI.DateTime { __data["date"] }
        public var startTime: UpShiftAPI.DateTime { __data["startTime"] }
        public var endTime: UpShiftAPI.DateTime { __data["endTime"] }
        public var department: Department? { __data["department"] }

        /// CreateDropShiftRequest.Shift.Department
        ///
        /// Parent Type: `Department`
        public struct Department: UpShiftAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { UpShiftAPI.Objects.Department }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateDropShiftRequestMutation.Data.CreateDropShiftRequest.Shift.Department.self
          ] }

          public var name: String { __data["name"] }
        }
      }
    }
  }
}
