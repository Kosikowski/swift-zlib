// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SwiftZlib",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "SwiftZlib", targets: ["SwiftZlib"]),
    ],
    targets: [
        // ① thin shim so SwiftPM can find the headers
        .target(
            name: "CZLib",
            path: "Sources/CZLib",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .unsafeFlags(["-L/usr/lib", "-lz.1.2.12"]),
            ]
        ),

        // ② your Swift façade with optional verbose logging
        .target(
            name: "SwiftZlib",
            dependencies: ["CZLib"],
            swiftSettings: [
                .define("ZLIB_VERBOSE_DISABLED"),
            ]
        ),

        .testTarget(
            name: "SwiftZlibTests",
            dependencies: ["SwiftZlib"]
        ),
    ]
)
