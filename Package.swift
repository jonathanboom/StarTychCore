// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "StarTychCore",
    platforms: [
        .macOS(.v10_13), .iOS(.v13),
    ],
    products: [
        .library(
            name: "StarTychCore",
            targets: ["ImageFileManager", "ImageUtils", "StarTych"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ImageUtils",
            dependencies: ["ObjectiveCHelpers"]),
        .target(
            name: "ImageFileManager",
            dependencies: ["ImageUtils"]),
        .target(
            name: "ObjectiveCHelpers",
            dependencies: []),
        .target(
            name: "StarTych",
            dependencies: ["ImageUtils"]),
        .testTarget(
            name: "StarTychCoreTests",
            dependencies: ["StarTych"]),
    ]
)
