// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-fsm",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftFSM",
            targets: ["SwiftFSM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/drseg/reflective-equality", from: "1.0.0"),
        .package(url: "https://github.com/drseg/swift-fsm-macros", branch: "master")
//        .package(url: "https://github.com/realm/SwiftLint", from: "0.50.0")
    ],
    targets: [
        .target(
            name: "SwiftFSM",
            dependencies:
                [.product(name: "ReflectiveEquality", package: "reflective-equality"),
                 .product(name: "Algorithms", package: "swift-algorithms"),
                 .product(name: "SwiftFSMMacros", package: "swift-fsm-macros")],
            swiftSettings: [.define("DEVELOPMENT", .when(configuration: .debug))]
//            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SwiftFSMTests",
            dependencies: ["SwiftFSM"]
        ),
    ]
)
