// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaneViewController",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "PaneViewController",
            targets: ["PaneViewController"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PaneViewController",
            path: "Sources/PaneViewController",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "PaneViewControllerTests",
            dependencies: ["PaneViewController"]),
    ],
    swiftLanguageVersions: [.v5]
)
