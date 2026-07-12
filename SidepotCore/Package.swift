// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SidepotCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        // `swift test` runs the test executable on the macOS host, not an iOS simulator, so a
        // macOS platform floor is required too even though the shipping app is iOS-only —
        // otherwise SwiftData's macOS-14-and-up APIs (Schema, ModelContainer, ...) fail
        // availability checking under the toolchain's default (much older) macOS minimum.
        .macOS(.v14)
    ],
    products: [
        .library(name: "SidepotCore", targets: ["SidepotCore"])
    ],
    targets: [
        .target(
            name: "SidepotCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SidepotCoreTests",
            dependencies: ["SidepotCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
