
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CarDSPCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CarDSPCore", targets: ["CarDSPCore"])
    ],
    targets: [
        .target(name: "CarDSPCore"),
        .testTarget(name: "CarDSPCoreTests", dependencies: ["CarDSPCore"])
    ]
)
