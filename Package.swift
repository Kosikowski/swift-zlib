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
            sources: [
                "zlib_shim.c",
                "adler32.c",
                "compress.c",
                "crc32.c",
                "deflate.c",
                "gzclose.c",
                "gzlib.c",
                "gzread.c",
                "gzwrite.c",
                "infback.c",
                "inffast.c",
                "inflate.c",
                "inftrees.c",
                "trees.c",
                "uncompr.c",
                "zutil.c",
            ],
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
                .define("_NO_CRT_MATH_INLINE"),
                .define("_NO_CRT_STRING_INLINE"),
                .define("_NO_CRT_WCTYPE_INLINE"),
                .define("_NO_CRT_LOCALE_INLINE"),
                .define("_NO_CRT_STDLIB_INLINE"),
                .define("_NO_CRT_CTYPE_INLINE"),
                .define("_NO_CRT_ERRNO_INLINE"),
                .define("_NO_CRT_SETJMP_INLINE"),
                .define("_NO_CRT_SIGNAL_INLINE"),
                .define("_NO_CRT_ASSERT_INLINE"),
                .define("_NO_CRT_MEMORY_INLINE"),
                .define("_NO_CRT_MALLOC_INLINE"),
                .define("_NO_CRT_FREE_INLINE"),
                .define("_NO_CRT_MEMSET_INLINE"),
                .define("_NO_CRT_MEMCPY_INLINE"),
                .define("_NO_CRT_MEMCMP_INLINE"),
                .define("_NO_CRT_STRLEN_INLINE"),
                .define("_NO_CRT_STRCPY_INLINE"),
                .define("_NO_CRT_STRCAT_INLINE"),
                .define("_NO_CRT_STRCMP_INLINE"),
                .define("_NO_CRT_SPRINTF_INLINE"),
                .define("_NO_CRT_VSPRINTF_INLINE"),
                .define("_NO_CRT_PRINTF_INLINE"),
                .define("_NO_CRT_FFLUSH_INLINE"),
                .define("_NO_CRT_WCHAR_INLINE"),
                .define("_NO_CRT_MBSTOWCS_INLINE"),
                .define("_NO_CRT_WCSTOMBS_INLINE"),
                .define("_NO_CRT_MBTOWC_INLINE"),
                .define("_NO_CRT_WCTOMB_INLINE"),
                .define("_NO_CRT_MBLEN_INLINE"),
                .define("_NO_CRT_MBRLEN_INLINE"),
                .define("_NO_CRT_MBRTOWC_INLINE"),
                .define("_NO_CRT_WCRTOMB_INLINE"),
                .define("_NO_CRT_MBSRTOWCS_INLINE"),
                .define("_NO_CRT_WCSRTOMBS_INLINE"),
                .define("_NO_CRT_MBSTOWCS_S_INLINE"),
                .define("_NO_CRT_WCSTOMBS_S_INLINE"),
                .define("_NO_CRT_MBSRTOWCS_S_INLINE"),
                .define("_NO_CRT_WCSRTOMBS_S_INLINE"),
            ],
            linkerSettings: [
                // Only link zlib on non-Windows platforms since we use our own implementation on Windows
                .linkedLibrary("z", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .linux])),
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
