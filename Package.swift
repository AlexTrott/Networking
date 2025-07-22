// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v15),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "NetworkingInterface",
            targets: ["NetworkingInterface"]
        ),
        .library(
            name: "Networking",
            targets: ["Networking"]
        ),
        .library(
            name: "NetworkingInterceptors",
            targets: ["Networking"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/datatheorem/TrustKit", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "NetworkingInterface",
            dependencies: []
        ),
        .target(
            name: "Networking",
            dependencies: [
                "TrustKit",
                "NetworkingInterface"
            ]
        ),
        .target(
            name: "NetworkingInterceptors",
            dependencies: [
                "NetworkingInterface"
            ]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: [
                "Networking",
                "NetworkingInterceptors",
                "NetworkingInterface"
            ]
        ),
    ]
)
