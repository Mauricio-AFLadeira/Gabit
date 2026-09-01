// swift-tools-version: 6.0

import PackageDescription

// Persistence. Depends on the domain; the domain does not depend on it.
let package = Package(
    name: "GabitData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GabitData", targets: ["GabitData"])
    ],
    dependencies: [
        .package(path: "../GabitDomain")
    ],
    targets: [
        .target(
            name: "GabitData",
            dependencies: [.product(name: "GabitDomain", package: "GabitDomain")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GabitDataTests",
            dependencies: ["GabitData"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
