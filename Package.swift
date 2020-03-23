// swift-tools-version:5.1
//
// Copyright (c) 2020, Jonathan Lynch
//
// This source code is licensed under the BSD 3-Clause License license found in the
// LICENSE file in the root directory of this source tree.
//

import PackageDescription

let package = Package(
    name: "StarTychCore",
    platforms: [
        .macOS(.v10_13), .iOS(.v13),
    ],
    products: [
        .library(
            name: "StarTychCore",
            targets: ["ImageFileManager", "ImageUtils", "StarTychCore"]),
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
            name: "StarTychCore",
            dependencies: ["ImageUtils"]),
    ]
)
