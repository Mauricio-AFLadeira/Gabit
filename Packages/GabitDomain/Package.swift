// swift-tools-version: 6.0

import PackageDescription

// The innermost package: pure Swift, no dependencies, no Apple UI framework.
// Nothing here may import SwiftUI, UIKit or SwiftData — the build enforces the
// boundary that plan §4 asks for, so it cannot rot into a folder convention.
let package = Package(
    name: "GabitDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GabitDomain", targets: ["GabitDomain"])
    ],
    targets: [
        .target(
            name: "GabitDomain",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GabitDomainTests",
            dependencies: ["GabitDomain"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
