// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Dynamic",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2)
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
