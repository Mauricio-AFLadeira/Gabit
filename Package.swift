// swift-tools-version: 6.0

import PackageDescription

// Only the platform-agnostic core lives in the package, which is what lets the
// Linux container build and test it. The SwiftUI app in App/ consumes GabitKit
// through the Xcode project generated from project.yml.
let package = Package(
    name: "Gabit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GabitKit", targets: ["GabitKit"])
    ],
    targets: [
        .target(
            name: "GabitKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
