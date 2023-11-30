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
      url: "https://github.com/kishikawakatsumi/KeychainAccess",
      .upToNextMajor(from: "4.2.0")
    )
  ],
  targets: [
    .target(
      name: "Synology",
      dependencies: [
        .product(
          name: "Alamofire",
          package: "Alamofire"
        ),
        .product(
          name: "KeychainAccess",
          package: "KeychainAccess"
        )
      ]
    ),
    .testTarget(
      name: "SynologyTests",
      dependencies: ["Synology"]
    )
  ]
)
