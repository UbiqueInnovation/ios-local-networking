// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UBLocalNetworking",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v8),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "UBLocalNetworking",
            targets: ["UBLocalNetworking"]),
    ],
    targets: [
        .target(name: "UBLocalNetworking"),
        .testTarget(
            name: "UBLocalNetworkingTests",
            dependencies: ["UBLocalNetworking"],
            resources: [
                .copy("Resources")
            ]
        ),
        
    ]
)
