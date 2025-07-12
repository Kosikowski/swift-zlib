// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SwiftZlib",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "SwiftZlib", targets: ["SwiftZlib"])
    ],
    targets: [
        // ① thin shim so SwiftPM can find the headers
        .target(
            name: "CZLib",
            path: "Sources/CZLib",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .unsafeFlags(["-L/usr/lib", "-lz.1.2.12"])
            ]
        ),

        // ② your Swift façade
        .target(
            name: "SwiftZlib",
            dependencies: ["CZLib"]
        ),
        .testTarget(
            name: "SwiftZlibTests",
            dependencies: ["SwiftZlib"]
        )
    ]
)