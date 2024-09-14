// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Synology",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6)
  ],
  products: [
    .library(
      name: "Synology",
      targets: ["Synology"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/Alamofire/Alamofire.git",
      .upToNextMajor(from: "5.8.0")
    ),
    .package(
      url: "https://github.com/swiftlang/swift-testing.git",
      .upToNextMajor(from: "0.12.0")
    ),
    .package(
      url: "https://github.com/AliSoftware/OHHTTPStubs.git",
      .upToNextMajor(from: "9.1.0"))
  ],
  targets: [
    .target(
      name: "Synology",
      dependencies: [
        .product(name: "Alamofire", package: "Alamofire")
      ]
    ),
    .testTarget(
      name: "SynologyTests",
      dependencies: [
        "Synology",
        .product(name: "Testing", package: "swift-testing"),
        .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
      ]
    )
  ]
)
