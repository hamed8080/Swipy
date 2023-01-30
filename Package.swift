// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swipy",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Swipy",
            targets: ["Swipy"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Swipy",
            dependencies: []),
        .testTarget(
            name: "SwipyTests",
            dependencies: ["Swipy"]),
    ]
)
