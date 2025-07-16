//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class DataExtensionsTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testDataExtensions", testDataExtensions),
        ("testDataExtensionsAdvanced", testDataExtensionsAdvanced),
        ("testConcurrentDataExtensions", testConcurrentDataExtensions),
    ]

    // MARK: Functions

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

    // MARK: - Data Extension Tests

    func testDataExtensions() throws {
        let originalData = "Test data for extension methods".data(using: .utf8)!

        // Test Data extension
        let compressedData = try originalData.compressed()
        let decompressedData = try compressedData.decompressed()

        XCTAssertEqual(decompressedData, originalData)
    }

    func testDataExtensionsAdvanced() throws {
        let originalData = "Advanced data extension test".data(using: .utf8)!

        // Test with different compression levels
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]

        for level in levels {
            let compressed = try originalData.compressed(level: level)
            let decompressed = try compressed.decompressed()
            XCTAssertEqual(decompressed, originalData)
        }
    }

    func testConcurrentDataExtensions() async throws {
        let testData = "Concurrent data extensions test data".data(using: .utf8)!
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try testData.compressed()
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent data extension compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try compressed.decompressed()
            XCTAssertEqual(decompressed, testData)
        }
    }
}
