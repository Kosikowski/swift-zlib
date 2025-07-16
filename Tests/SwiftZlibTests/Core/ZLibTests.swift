//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class ZLibTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testZLibVersion", testZLibVersion),
        ("testBasicCompressionAndDecompression", testBasicCompressionAndDecompression),
        ("testCompressionLevels", testCompressionLevels),
        ("testCorruptedData", testCorruptedData),
        ("testMemoryPressure", testMemoryPressure),
        ("testConcurrentAccess", testConcurrentAccess),
        ("testMinimalSmallStringCompression", testMinimalSmallStringCompression),
        ("testMinimalSmallStringStreamingCompression", testMinimalSmallStringStreamingCompression),
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

    // MARK: - Basic Tests

    func testZLibVersion() throws {
        let version = ZLib.version
        XCTAssertFalse(version.isEmpty, "Version should not be empty")

        let compileFlags = ZLib.compileFlags
        XCTAssertGreaterThan(compileFlags, 0, "Compile flags should be greater than 0")
    }

    func testBasicCompressionAndDecompression() throws {
        let originalData = "Hello, World! This is a test string for compression.".data(using: .utf8)!

        print("=== Starting basic compression/decompression test ===")

        // Test compression with verbose logging
        let compressedData = try ZLib.compress(originalData)
        // Do not assert compressedData.count < originalData.count (may not be true for small data)

        // Test decompression with verbose logging
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)

        print("=== Completed basic compression/decompression test ===")
    }

    func testCompressionLevels() throws {
        let originalString = "This is a longer test string that should demonstrate different compression levels. " +
            "We'll repeat this several times to make it longer and more compressible. " +
            "This is a longer test string that should demonstrate different compression levels. " +
            "We'll repeat this several times to make it longer and more compressible."
        let originalData = originalString.data(using: .utf8)!

        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        var compressedSizes: [Int] = []

        for level in levels {
            let compressedData = try ZLib.compress(originalData, level: level)
            compressedSizes.append(compressedData.count)

            // Verify we can decompress it
            let decompressedData = try ZLib.decompress(compressedData)
            XCTAssertEqual(decompressedData, originalData)
        }

        // Verify compression levels work (best compression should be smallest)
        XCTAssertGreaterThanOrEqual(compressedSizes[0], compressedSizes[1]) // noCompression >= bestSpeed
        XCTAssertGreaterThanOrEqual(compressedSizes[1], compressedSizes[2]) // bestSpeed >= default
        XCTAssertGreaterThanOrEqual(compressedSizes[2], compressedSizes[3]) // default >= bestCompression
    }

    func testCorruptedData() throws {
        let originalData = "Test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        // Corrupt the data
        var corruptedData = compressedData
        if corruptedData.count > 10 {
            corruptedData[5] = 0xFF
        }

        XCTAssertThrowsError(try ZLib.decompress(corruptedData)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testMemoryPressure() throws {
        // Test with very large, highly compressible data
        let original = Data(repeating: 0x41, count: 100_000)
        let compressed = try ZLib.compress(original, level: .bestCompression)

        // Use streaming decompression for large data
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, original)
    }

    func testConcurrentAccess() throws {
        // Test that multiple compressors/decompressors can be used concurrently
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!

        let compressor1 = Compressor()
        let compressor2 = Compressor()

        try compressor1.initialize(level: .bestCompression)
        try compressor2.initialize(level: .bestSpeed)

        let compressed1 = try compressor1.compress(data1, flush: .finish)
        let compressed2 = try compressor2.compress(data2, flush: .finish)

        let decompressor1 = Decompressor()
        let decompressor2 = Decompressor()

        try decompressor1.initialize()
        try decompressor2.initialize()

        do {
            let decompressed1 = try decompressor1.decompress(compressed1, flush: .finish)
            let decompressed1String = String(data: decompressed1, encoding: .utf8)
            let data1String = String(data: data1, encoding: .utf8)
            XCTAssertNotNil(decompressed1String)
            XCTAssertEqual(decompressed1String, data1String)
        } catch {
            XCTFail("decompressor1 error: \(error)")
        }

        do {
            let decompressed2 = try decompressor2.decompress(compressed2, flush: .finish)
            let decompressed2String = String(data: decompressed2, encoding: .utf8)
            let data2String = String(data: data2, encoding: .utf8)
            XCTAssertNotNil(decompressed2String)
            XCTAssertEqual(decompressed2String, data2String)
        } catch {
            XCTFail("decompressor2 error: \(error)")
        }
    }

    func testMinimalSmallStringCompression() throws {
        let original = "Hello!"
        let data = original.data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressed = try ZLib.decompress(compressed)
        let decompressedString = String(data: decompressed, encoding: .utf8)
        XCTAssertNotNil(decompressedString)
        XCTAssertEqual(decompressedString, original)
    }

    func testMinimalSmallStringStreamingCompression() throws {
        let original = "Hello!"
        let data = original.data(using: .utf8)!

        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        let compressed = try compressor.compress(data, flush: .finish)

        // Force reset after compression
        try compressor.reset()

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, flush: .finish)

        // Force reset after decompression
        try decompressor.reset()

        let decompressedString = String(data: decompressed, encoding: .utf8)
        XCTAssertNotNil(decompressedString)
        XCTAssertEqual(decompressedString, original)
    }
}
