// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "AndroidTVRemoteControl",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "AndroidTVRemoteControl",
            targets: ["AndroidTVRemoteControl"]),
    ],
    targets: [
        .target(
            name: "AndroidTVRemoteControl"),
        .testTarget(
            name: "AndroidTVRemoteControlTests",
            dependencies: ["AndroidTVRemoteControl"]),
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
