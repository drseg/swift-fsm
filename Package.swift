// swift-tools-version: 5.9
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
//        .library(
//            name: "SwiftFSMMacros",
//            targets: ["SwiftFSMMacros"]
//        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/drseg/reflective-equality", from: "1.0.0"),
//        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
//        .package(url: "https://github.com/drseg/swift-fsm-macros", branch: "master"),
//        .package(url: "https://github.com/realm/SwiftLint", from: "0.50.0")
    ],
    targets: [
        .target(
            name: "SwiftFSM",
            dependencies: [
                .product(name: "ReflectiveEquality", package: "reflective-equality"),
                .product(name: "Algorithms", package: "swift-algorithms"),
//                "SwiftFSMMacros",
            ],
            swiftSettings: [.define("DEVELOPMENT", .when(configuration: .debug))]
//          plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
//        .macro(
//            name: "SwiftFSMMacrosEvent",
//            dependencies: [
//                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
//                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
//            ]
//        ),
//        .target(name: "SwiftFSMMacros", dependencies: ["SwiftFSMMacrosEvent"]),

        .testTarget(
            name: "SwiftFSMTests",
            dependencies: [
                "SwiftFSM",
//                "SwiftFSMMacros"
            ]
        ),
//        .testTarget(
//            name: "SwiftFSMMacrosTests",
//            dependencies: [
//                "SwiftFSMMacrosEvent",
//                "SwiftFSM",
//                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
//            ]
//        ),
    ]
)
