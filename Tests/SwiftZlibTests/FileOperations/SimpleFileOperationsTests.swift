//
//  SimpleFileOperationsTests.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import XCTest
@testable import SwiftZlib

final class SimpleFileOperationsTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testSimpleFileCompression", testSimpleFileCompression),
        ("testSimpleFileDecompression", testSimpleFileDecompression),
        ("testSimpleFileCompressionWithProgress", testSimpleFileCompressionWithProgress),
        ("testSimpleFileDecompressionWithProgress", testSimpleFileDecompressionWithProgress),
        ("testSimpleFileCompressionAsync", testSimpleFileCompressionAsync),
        ("testSimpleFileDecompressionAsync", testSimpleFileDecompressionAsync),
        ("testSimpleFileCompressionConvenience", testSimpleFileCompressionConvenience),
        ("testSimpleFileDecompressionConvenience", testSimpleFileDecompressionConvenience),
    ]

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
        // Disable verbose logging to prevent debug output interference in tests
        ZLibVerboseConfig.disableAll()
    }

    override func tearDown() {
        // Re-enable verbose logging after tests if needed
        ZLibVerboseConfig.disableAll()
        super.tearDown()
    }

    // MARK: Functions

    func testSimpleFileCompression() throws {
        let testData = "Hello, World! This is a test for simple file compression using GzipFile.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_compression_source.txt")
        let destPath = tempFilePath("test_simple_compression_dest.gz")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file using SimpleFileCompressor
        let compressor = SimpleFileCompressor(bufferSize: 1024, compressionLevel: .defaultCompression)
        try compressor.compressFile(from: sourcePath, to: destPath)

        // Verify compressed file exists and is non-empty
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty, "Compressed data should not be empty")

        // Decompress and verify round-trip
        let decompressor = SimpleFileDecompressor(bufferSize: 1024)
        let decompressedPath = tempFilePath("test_simple_compression_decompressed.txt")
        defer { try? FileManager.default.removeItem(atPath: decompressedPath) }
        try decompressor.decompressFile(from: destPath, to: decompressedPath)

        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")
    }

    func testSimpleFileDecompression() throws {
        let testData = "Hello, World! This is a test for simple file decompression using GzipFile.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_decompression_source.txt")
        let compressedPath = tempFilePath("test_simple_decompression_compressed.gz")
        let decompressedPath = tempFilePath("test_simple_decompression_decompressed.txt")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file first
        let compressor = SimpleFileCompressor(bufferSize: 1024)
        try compressor.compressFile(from: sourcePath, to: compressedPath)

        // Decompress file using SimpleFileDecompressor
        let decompressor = SimpleFileDecompressor(bufferSize: 1024)
        try decompressor.decompressFile(from: compressedPath, to: decompressedPath)

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")
    }

    func testSimpleFileCompressionWithProgress() throws {
        let testData = "Hello, World! This is a test for simple file compression with progress.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_compression_progress_source.txt")
        let destPath = tempFilePath("test_simple_compression_progress_dest.gz")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        var progressUpdates: [(Int, Int)] = []
        let compressor = SimpleFileCompressor(bufferSize: 1024)
        try compressor.compressFile(
            from: sourcePath,
            to: destPath,
            progress: { processed, total in
                progressUpdates.append((processed, total))
            }
        )

        // Verify progress was reported
        XCTAssertFalse(progressUpdates.isEmpty, "Progress should be reported")
        XCTAssertTrue(progressUpdates.last?.0 == progressUpdates.last?.1, "Final progress should be 100%")

        // Verify compressed file exists
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty, "Compressed data should not be empty")
    }

    func testSimpleFileDecompressionWithProgress() throws {
        let testData = "Hello, World! This is a test for simple file decompression with progress.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_decompression_progress_source.txt")
        let compressedPath = tempFilePath("test_simple_decompression_progress_compressed.gz")
        let decompressedPath = tempFilePath("test_simple_decompression_progress_decompressed.txt")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file first
        let compressor = SimpleFileCompressor(bufferSize: 1024)
        try compressor.compressFile(from: sourcePath, to: compressedPath)

        var progressUpdates: [(Int, Int)] = []
        let decompressor = SimpleFileDecompressor(bufferSize: 1024)
        try decompressor.decompressFile(
            from: compressedPath,
            to: decompressedPath,
            progress: { processed, total in
                progressUpdates.append((processed, total))
            }
        )

        // Verify progress was reported
        XCTAssertFalse(progressUpdates.isEmpty, "Progress should be reported")

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")
    }

    func testSimpleFileCompressionAsync() async throws {
        let testData = "Hello, World! This is a test for async simple file compression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_compression_async_source.txt")
        let destPath = tempFilePath("test_simple_compression_async_dest.gz")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file using async SimpleFileCompressor
        let compressor = SimpleFileCompressor(bufferSize: 1024)
        try await compressor.compressFile(from: sourcePath, to: destPath)

        // Verify compressed file exists and is non-empty
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty, "Compressed data should not be empty")
    }

    func testSimpleFileDecompressionAsync() async throws {
        let testData = "Hello, World! This is a test for async simple file decompression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_decompression_async_source.txt")
        let compressedPath = tempFilePath("test_simple_decompression_async_compressed.gz")
        let decompressedPath = tempFilePath("test_simple_decompression_async_decompressed.txt")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file first
        let compressor = SimpleFileCompressor(bufferSize: 1024)
        try await compressor.compressFile(from: sourcePath, to: compressedPath)

        // Decompress file using async SimpleFileDecompressor
        let decompressor = SimpleFileDecompressor(bufferSize: 1024)
        try await decompressor.decompressFile(from: compressedPath, to: decompressedPath)

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")
    }

    func testSimpleFileCompressionConvenience() throws {
        let testData = "Hello, World! This is a test for simple file compression convenience methods.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_compression_convenience_source.txt")
        let destPath = tempFilePath("test_simple_compression_convenience_dest.gz")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file using convenience method
        try ZLib.compressFileSimple(from: sourcePath, to: destPath)

        // Verify compressed file exists and is non-empty
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty, "Compressed data should not be empty")
    }

    func testSimpleFileDecompressionConvenience() throws {
        let testData = "Hello, World! This is a test for simple file decompression convenience methods.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_simple_decompression_convenience_source.txt")
        let compressedPath = tempFilePath("test_simple_decompression_convenience_compressed.gz")
        let decompressedPath = tempFilePath("test_simple_decompression_convenience_decompressed.txt")

        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file first
        try ZLib.compressFileSimple(from: sourcePath, to: compressedPath)

        // Decompress file using convenience method
        try ZLib.decompressFileSimple(from: compressedPath, to: decompressedPath)

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")
    }

    private func tempFilePath(_ filename: String) -> String {
        NSTemporaryDirectory() + filename
    }
}
