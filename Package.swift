// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MagiCache",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "MagiCache",
            targets: ["MagiCache"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "MagiCache",
            dependencies: []),
        .testTarget(
            name: "MagiCacheTests",
            dependencies: ["MagiCache"]),
    ]
)
