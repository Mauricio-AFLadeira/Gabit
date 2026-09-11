// swift-tools-version: 6.0

import PackageDescription

// The platform-agnostic core (MauItKit) and the Postgres-backed API server
// (Server) both live in this package, which is what lets the Linux container
// build and test them. The SwiftUI app in App/ consumes MauItKit through the
// Xcode project generated from project.yml — it does not depend on Server.
let package = Package(
    name: "MauIt",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MauItKit", targets: ["MauItKit"]),
        .executable(name: "Server", targets: ["Server"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.11.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.1.2"),
    ],
    targets: [
        .target(
            name: "MauItKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "Server",
            dependencies: [
                .target(name: "MauItKit"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT", package: "jwt"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MauItKitTests",
            dependencies: [.target(name: "MauItKit")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: [
                .target(name: "Server"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
