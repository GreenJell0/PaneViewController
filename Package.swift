// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaneViewController",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "PaneViewController",
            targets: ["PaneViewController"]),
    ],
    dependencies: [
        .package(name: "Signals", url: "https://github.com/artman/Signals.git", from: "6.1.0"),
    ],
    targets: [
        .target(
            name: "PaneViewController",
            dependencies: ["Signals"]),
        .testTarget(
            name: "PaneViewControllerTests",
            dependencies: ["PaneViewController"]),
    ],
    swiftLanguageVersions: [.v5]
)
