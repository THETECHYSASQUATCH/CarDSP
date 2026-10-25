// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [.library(name: "CarDSPCore", targets: ["CarDSPCore"])]
var targets: [Target] = [
    .target(name: "CarDSPCore"),
    .testTarget(name: "CarDSPCoreTests", dependencies: ["CarDSPCore"])
]

// Apple app targets require Apple SDKs; keep the reusable Swift core testable
// on Windows and Linux. iOS cross-builds run on a macOS host.
#if os(macOS)
products.append(.executable(name: "CarDSPApp", targets: ["CarDSPApp"]))
targets.append(
        .executableTarget(
            name: "CarDSPApp",
            dependencies: ["CarDSPCore"],
            path: "Sources/CarDSPApp",
            exclude: ["Info.plist", "Info-macOS.plist"],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVFAudio"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("MusicKit")
            ]
        )
)
#endif

let package = Package(
    name: "CarDSP",
    platforms: [.iOS("18.0"), .macOS("14.0")],
    products: products,
    targets: targets
)
