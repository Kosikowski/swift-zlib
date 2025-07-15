//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class StringExtensionsTests: XCTestCase {
    // MARK: Static Properties

    // MARK: - Test Discovery

    static var allTests = [
        ("testStringExtensions", testStringExtensions),
        ("testStringExtensionsAdvanced", testStringExtensionsAdvanced),
        ("testConcurrentStringOperations", testConcurrentStringOperations),
    ]

    // MARK: Functions

    // MARK: - Helper Functions

    func assertNoDoubleWrappedZLibError(_ error: Error) {
        if let zlibError = error as? ZLibError {
            switch zlibError {
                case let .fileError(underlyingError):
                    XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped inside another ZLibError")
                case let .compressionFailed(code):
                    XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
                case let .decompressionFailed(code):
                    XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
                case let .streamError(code):
                    XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
                default:
                    break
            }
        }
    }

    // MARK: - String Extension Tests

    func testStringExtensions() throws {
        let originalString = "Hello, World!"

        // Test compression
        let compressed = try originalString.compressed()
        XCTAssertGreaterThan(compressed.count, 0, "Compressed data should not be empty")

        // Test decompression
        let decompressedString = try String.decompressed(from: compressed)
        XCTAssertEqual(decompressedString, originalString)
    }

    func testStringExtensionsAdvanced() throws {
        let originalString = "Advanced string extension test"

        // Test with different compression levels
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]

        for level in levels {
            let compressed = try originalString.compressed(level: level)
            let decompressedString = try String.decompressed(from: compressed)
            XCTAssertEqual(decompressedString, originalString)
        }
    }

    func testConcurrentStringOperations() async throws {
        let testString = "Concurrent string operations test string"
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try testString.compressed()
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent string compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed to original string
        for compressed in allResults {
            let decompressedString = try String.decompressed(from: compressed)
            XCTAssertEqual(decompressedString, testString)
        }
    }
}
