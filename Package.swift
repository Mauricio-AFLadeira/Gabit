// swift-tools-version: 6.0

import PackageDescription

// Only the platform-agnostic core lives in the package, which is what lets the
// Linux container build and test it. The SwiftUI app in App/ consumes MauItKit
// through the Xcode project generated from project.yml.
let package = Package(
    name: "MauIt",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MauItKit", targets: ["MauItKit"])
    ],
    targets: [
        .target(
            name: "MauItKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
