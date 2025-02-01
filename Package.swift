// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
//        .package(url: "https://github.com/realm/SwiftLint", from: "0.50.0")
    ],
    targets: [
        .target(
            name: "SwiftFSM",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            swiftSettings: [
                .define("DEVELOPMENT", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
//            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),

        .testTarget(
            name: "SwiftFSMTests",
            dependencies: [
                "SwiftFSM",
            ]
        ),
    ]
)
