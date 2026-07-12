// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SidepotCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
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
