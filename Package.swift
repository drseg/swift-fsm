// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFSM",
    platforms: [
            .macOS(.v13),
            .iOS(.v16)
        ],
    products: [
        .library(
            name: "SwiftFSM",
            targets: ["SwiftFSM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/drseg/reflective-equality", branch: "main")
    ],
    targets: [
        .target(
            name: "SwiftFSM",
            dependencies:
                [.product(name: "Algorithms", package: "swift-algorithms"),
                 .product(name: "ReflectiveEquality", package: "reflective-equality")]),
        .testTarget(
            name: "SwiftFSMTests",
            dependencies: ["SwiftFSM"]),
    ]
)
