// swift-tools-version: 6.0

import PackageDescription

// Views, view models and design tokens. Apple platforms only — this is the one
// package the Linux container lints but cannot build.
let package = Package(
    name: "GabitUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "GabitUI", targets: ["GabitUI"])
    ],
    dependencies: [
        .package(path: "../GabitDomain"),
        .package(path: "../GabitData"),
    ],
    targets: [
        .target(
            name: "GabitUI",
            dependencies: [
                .product(name: "GabitDomain", package: "GabitDomain"),
                .product(name: "GabitData", package: "GabitData"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GabitUITests",
            dependencies: ["GabitUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
