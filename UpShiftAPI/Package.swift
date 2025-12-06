// swift-tools-version:6.1

import PackageDescription

let package = Package(
  name: "UpShiftAPI",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "UpShiftAPI", targets: ["UpShiftAPI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios", exact: "2.0.3"),
  ],
  targets: [
    .target(
      name: "UpShiftAPI",
      dependencies: [
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      path: "./Sources"
    ),
  ],
  swiftLanguageModes: [.v6, .v5]
)
