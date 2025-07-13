//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class FileChunkedCompressorTests: XCTestCase {
    // MARK: Static Properties

    // MARK: - Test Discovery

    static var allTests = [
        ("testFileChunkedCompressor", testFileChunkedCompressor),
        ("testFileChunkedCompressorWithLargeData", testFileChunkedCompressorWithLargeData),
        ("testFileChunkedCompressorProgressStream", testFileChunkedCompressorProgressStream),
        ("testFileChunkedCompressorErrorHandling", testFileChunkedCompressorErrorHandling),
        ("testFileChunkedCompressorAsyncErrorHandling", testFileChunkedCompressorAsyncErrorHandling),
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

    // MARK: - FileChunkedCompressor Tests

    func testFileChunkedCompressor() async throws {
        let testData = "Test data for file chunked compressor".data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_source.txt")
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_compressed.gz")

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destURL)
        }

        // Write test data to source file
        try testData.write(to: sourceURL)

        // Test compression
        let compressor = FileChunkedCompressor()
        try await compressor.compressFile(from: sourceURL.path, to: destURL.path)

        // Verify file exists and has content
        XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))
        let compressedData = try Data(contentsOf: destURL)
        XCTAssertGreaterThan(compressedData.count, 0)

        // Test decompression
        let decompressor = FileChunkedDecompressor()
        let decompressDestURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_decompressed.txt")
        defer { try? FileManager.default.removeItem(at: decompressDestURL) }
        try await decompressor.decompressFile(from: destURL.path, to: decompressDestURL.path)

        let decompressedData = try Data(contentsOf: decompressDestURL)
        XCTAssertEqual(decompressedData, testData)
    }

    func testFileChunkedCompressorWithLargeData() async throws {
        let largeData = String(repeating: "Large test data ", count: 1000).data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_large_source.txt")
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_large_compressed.gz")

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destURL)
        }

        // Write large test data to source file
        try largeData.write(to: sourceURL)

        // Test compression of large data
        let compressor = FileChunkedCompressor()
        try await compressor.compressFile(from: sourceURL.path, to: destURL.path)

        // Verify file exists and has content
        XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))
        let compressedData = try Data(contentsOf: destURL)
        XCTAssertGreaterThan(compressedData.count, 0)

        // Test decompression
        let decompressor = FileChunkedDecompressor()
        let decompressDestURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_large_decompressed.txt")
        defer { try? FileManager.default.removeItem(at: decompressDestURL) }
        try await decompressor.decompressFile(from: destURL.path, to: decompressDestURL.path)

        let decompressedData = try Data(contentsOf: decompressDestURL)
        XCTAssertEqual(decompressedData, largeData)
    }

    func testFileChunkedCompressorProgressStream() async throws {
        let testData = "Test data for progress stream".data(using: .utf8)!
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_progress_source.txt")
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_progress.gz")

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destURL)
        }

        // Write test data to source file
        try testData.write(to: sourceURL)

        var progressCount = 0
        var totalBytes: Int64 = 0

        // Test compression with progress
        let compressor = FileChunkedCompressor()
        let progressStream = compressor.compressFileProgressStream(
            from: sourceURL.path,
            to: destURL.path,
            progressInterval: 0.1
        )

        for try await progressInfo in progressStream {
            progressCount += 1
            totalBytes = Int64(progressInfo.processedBytes)
        }

        // Verify progress was called
        XCTAssertGreaterThan(progressCount, 0)
        XCTAssertGreaterThan(totalBytes, 0)

        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))

        // Test decompression
        let decompressor = FileChunkedDecompressor()
        let decompressDestURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_progress_decompressed.txt")
        defer { try? FileManager.default.removeItem(at: decompressDestURL) }
        try await decompressor.decompressFile(from: destURL.path, to: decompressDestURL.path)

        let decompressedData = try Data(contentsOf: decompressDestURL)
        XCTAssertEqual(decompressedData, testData)
    }

    func testFileChunkedCompressorErrorHandling() throws {
        // Test with invalid URL (directory that doesn't exist)
        let invalidSourcePath = "/nonexistent/directory/test_source.txt"
        let invalidDestPath = "/nonexistent/directory/test.gz"

        let compressor = FileChunkedCompressor()
        XCTAssertThrowsError(try compressor.compressFile(from: invalidSourcePath, to: invalidDestPath)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testFileChunkedCompressorAsyncErrorHandling() async throws {
        // Test with invalid URL (directory that doesn't exist)
        let invalidSourcePath = "/nonexistent/directory/test_async_source.txt"
        let invalidDestPath = "/nonexistent/directory/test_async.gz"

        let compressor = FileChunkedCompressor()
        let progressStream = compressor.compressFileProgressStream(
            from: invalidSourcePath,
            to: invalidDestPath,
            progressInterval: 0.1
        )

        do {
            for try await _ in progressStream {
                // Should not reach here
            }
            XCTFail("Expected error for invalid URL")
        } catch {
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }
}
