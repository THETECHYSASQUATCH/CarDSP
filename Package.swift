// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [
    .library(name: "CarDSPCore", targets: ["CarDSPCore"])
]

var targets: [Target] = [
    .target(name: "CarDSPCore"),
    .testTarget(name: "CarDSPCoreTests", dependencies: ["CarDSPCore"])
]

#if !os(Windows)
products.append(.executable(name: "CarDSPApp", targets: ["CarDSPApp"]))
targets.append(.executableTarget(
    name: "CarDSPApp",
    dependencies: ["CarDSPCore"],
    path: "Sources/CarDSPApp",
    linkerSettings: [
        .linkedFramework("SwiftUI"),
        .linkedFramework("UIKit"),
        .linkedFramework("AVFoundation"),
        .linkedFramework("AVFAudio"),
        .linkedFramework("CoreAudio"),
        .linkedFramework("MusicKit")
    ]
))
#endif

let package = Package(
    name: "CarDSP",
    platforms: [.iOS(.v16)],
    products: products,
    targets: targets
)
