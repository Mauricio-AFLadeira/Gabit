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
        // The only third-party dependency in the project, per plan §2. It is
        // used by the test target alone, so nothing ships in the app binary.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.4"),
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
            dependencies: [
                "GabitUI",
                .product(name: "GabitDomain", package: "GabitDomain"),
                .product(name: "GabitData", package: "GabitData"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
