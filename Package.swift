// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-synchronizers",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "Synchronizer Namespace", targets: ["Synchronizer Namespace"]),

        .library(name: "Synchronizer Protocol", targets: ["Synchronizer Protocol"]),

        .library(name: "Synchronize", targets: ["Synchronize"]),

        .library(name: "Synchronizable", targets: ["Synchronizable"]),

        .library(name: "Synchronizer Blocking", targets: ["Synchronizer Blocking"]),

        .library(name: "Synchronizers", targets: ["Synchronizers"]),

        .library(name: "Synchronizers Test Support", targets: ["Synchronizers Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main")
    ],
    targets: [

        .target(
            name: "Synchronizer Namespace",
            dependencies: []
        ),

        .target(
            name: "Synchronizer Protocol",
            dependencies: [
                "Synchronizer Namespace"
            ]
        ),

        .target(
            name: "Synchronize",
            dependencies: [
                "Synchronizer Protocol"
            ]
        ),

        .target(
            name: "Synchronizable",
            dependencies: [
                "Synchronizer Protocol"
            ]
        ),

        .target(
            name: "Synchronizer Blocking",
            dependencies: [
                "Synchronizer Protocol",
                .product(name: "Kernel", package: "swift-kernel"),
            ]
        ),

        .target(
            name: "Synchronizers",
            dependencies: [
                "Synchronizer Namespace",
                "Synchronizer Protocol",
                "Synchronize",
                "Synchronizable",
                "Synchronizer Blocking",
            ]
        ),

        .target(
            name: "Synchronizers Test Support",
            dependencies: [
                "Synchronizers",
                .product(name: "Kernel Test Support", package: "swift-kernel"),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Synchronize Tests",
            dependencies: [
                "Synchronize",
                "Synchronizer Blocking",
                "Synchronizers Test Support",
            ]
        ),
        .testTarget(
            name: "Synchronizer Blocking Tests",
            dependencies: [
                "Synchronizer Blocking",
                "Synchronizers Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
