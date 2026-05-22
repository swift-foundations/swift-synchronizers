// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-synchronizers",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        // MARK: - Namespace
        .library(name: "Synchronizer Namespace", targets: ["Synchronizer Namespace"]),
        // MARK: - Protocol
        .library(name: "Synchronizer Protocol", targets: ["Synchronizer Protocol"]),
        // MARK: - Witness
        .library(name: "Synchronize", targets: ["Synchronize"]),
        // MARK: - Attachable
        .library(name: "Synchronizable", targets: ["Synchronizable"]),
        // MARK: - Variants
        .library(name: "Synchronizer Blocking", targets: ["Synchronizer Blocking"]),
        // MARK: - Umbrella
        .library(name: "Synchronizers", targets: ["Synchronizers"]),
        // MARK: - Test Support
        .library(name: "Synchronizers Test Support", targets: ["Synchronizers Test Support"]),
    ],
    dependencies: [
        .package(path: "../swift-kernel"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Synchronizer Namespace",
            dependencies: []
        ),

        // MARK: - Protocol
        .target(
            name: "Synchronizer Protocol",
            dependencies: [
                "Synchronizer Namespace",
            ]
        ),

        // MARK: - Witness
        .target(
            name: "Synchronize",
            dependencies: [
                "Synchronizer Protocol",
            ]
        ),

        // MARK: - Attachable
        .target(
            name: "Synchronizable",
            dependencies: [
                "Synchronizer Protocol",
            ]
        ),

        // MARK: - Variants
        .target(
            name: "Synchronizer Blocking",
            dependencies: [
                "Synchronizer Protocol",
                .product(name: "Kernel", package: "swift-kernel"),
            ]
        ),

        // MARK: - Umbrella
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

        // MARK: - Test Support
        .target(
            name: "Synchronizers Test Support",
            dependencies: [
                "Synchronizers",
                .product(name: "Kernel Test Support", package: "swift-kernel"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
