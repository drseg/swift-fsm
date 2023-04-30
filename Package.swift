// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-fsm",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "SwiftFSM",
            targets: ["SwiftFSM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/drseg/reflective-equality", branch: "main")
    ],
    targets: [
        .target(
            name: "SwiftFSM",
            dependencies:
                [.product(name: "ReflectiveEquality", package: "reflective-equality"),
                 .product(name: "Algorithms", package: "swift-algorithms")],
            swiftSettings: [.define("DEVELOPMENT", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "SwiftFSMTests",
            dependencies: ["SwiftFSM"]
        ),
    ]
)
