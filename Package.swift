// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CarDSP",
    platforms: [
        .iOS("18.0"),
        .macOS("14.0")
    ],
    products: [
        .library(name: "CarDSPCore", targets: ["CarDSPCore"]),
        .executable(name: "CarDSPApp", targets: ["CarDSPApp"])
    ],
    targets: [
        .target(name: "CarDSPCore"),
        .executableTarget(
            name: "CarDSPApp",
            dependencies: ["CarDSPCore"],
            path: "Sources/CarDSPApp",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVFAudio"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("MusicKit")
            ]
        ),
        .testTarget(name: "CarDSPCoreTests", dependencies: ["CarDSPCore"])
    ]
)
