
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CarDSP",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CarDSPCore", targets: ["CarDSPCore"]),
        .executable(name: "CarDSPApp", targets: ["CarDSPApp"])
    ],
    targets: [
        .target(name: "CarDSPCore"),
        .executableTarget(
            name: "CarDSPApp",
            dependencies: ["CarDSPCore"],
            path: "Sources/CarDSPApp"
        ),
        .testTarget(name: "CarDSPCoreTests", dependencies: ["CarDSPCore"])
    ]
)
