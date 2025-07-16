// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftZlib",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "SwiftZlib", targets: ["SwiftZlib"]),
        .executable(name: "SwiftZlibCLI", targets: ["SwiftZlibCLI"]),
    ],
    targets: [
        // Swift façade with direct zlib import
        .target(
            name: "SwiftZlib",
            dependencies: ["SwiftZlibCShims"],
            swiftSettings: [
                .define("ZLIB_VERBOSE_DISABLED"),
            ],
            linkerSettings: [
                // Link system zlib on all platforms
                .linkedLibrary("z"),
            ]
        ),

        // C shims for missing zlib functions
        .target(
            name: "SwiftZlibCShims",
            path: "Sources/SwiftZlibCShims",
            sources: [
                "inflate_pending_shim.c",
                "inflate_back_shim.c",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
            ]
        ),

        .testTarget(
            name: "SwiftZlibTests",
            dependencies: ["SwiftZlib"]
        ),

        .executableTarget(
            name: "SwiftZlibCLI",
            dependencies: ["SwiftZlib"]
        ),
    ]
)
