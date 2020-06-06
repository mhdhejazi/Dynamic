// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Dynamic",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "Dynamic", targets: ["Dynamic"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Dynamic", dependencies: []),
        .testTarget(name: "DynamicTests", dependencies: ["Dynamic"])
    ],
    swiftLanguageVersions: [.v5]
)
