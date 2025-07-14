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
        // ① thin shim so SwiftPM can find the headers
        .target(
            name: "CZLib",
            path: "Sources/CZLib",
            cSettings: [
                .headerSearchPath("include"),
                .define("_CRT_SECURE_NO_WARNINGS"),
                .define("_WIN32_WINNT", to: "0x0601"),
                .define("WIN32_LEAN_AND_MEAN"),
                .define("__NO_INTRINSICS__"),
                .define("_NO_CRT_STDIO_INLINE"),
                .define("_CRT_NO_POSIX_ERROR_CODES"),
                .define("_NO_CRT_RAND_S"),
                .define("_NO_CRT_TIME_INLINE"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
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

        .executableTarget(
            name: "SwiftZlibCLI",
            dependencies: ["SwiftZlib"]
        ),
    ]
)
