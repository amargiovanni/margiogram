// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Margiogram",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0")
    ],
    products: [
        .library(
            name: "Margiogram",
            targets: ["Margiogram"]
        ),
    ],
    dependencies: [
        // TDLib Swift wrapper
        // .package(url: "https://github.com/Swiftgram/TDLibKit.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Margiogram",
            dependencies: [
                // "TDLibKit"
            ],
            path: "Margiogram",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MargiogramTests",
            dependencies: ["Margiogram"],
            path: "MargiogramTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
