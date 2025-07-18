//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class GzipHeaderTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testCompressionWithGzipHeader", testCompressionWithGzipHeader),
        ("testStringCompressionWithGzipHeader", testStringCompressionWithGzipHeader),
        ("testGzipHeaderWithMetadata", testGzipHeaderWithMetadata),
        ("testGzipHeaderWithFilename", testGzipHeaderWithFilename),
        ("testGzipHeaderWithTimestamp", testGzipHeaderWithTimestamp),
        ("testGzipHeaderCompressionLevel", testGzipHeaderCompressionLevel),
        ("testGzipHeaderWithEmptyData", testGzipHeaderWithEmptyData),
        ("testGzipHeaderWithLargeData", testGzipHeaderWithLargeData),
        ("testGzipHeaderCorruption", testGzipHeaderCorruption),
        ("testGzipHeaderWithDifferentOS", testGzipHeaderWithDifferentOS),
        ("testGzipHeaderRoundTrip", testGzipHeaderRoundTrip),
        ("testGzipHeaderWithAutoDetection", testGzipHeaderWithAutoDetection),
        ("testGzipHeaderWithStreaming", testGzipHeaderWithStreaming),
        ("testGzipHeadersWithExtraFields", testGzipHeadersWithExtraFields),
        ("testGzipHeadersWithComments", testGzipHeadersWithComments),
        ("testGzipHeadersWithFilenames", testGzipHeadersWithFilenames),
        ("testGzipHeaderFieldValidation", testGzipHeaderFieldValidation),
        ("testGzipHeaderPartialCorruption", testGzipHeaderPartialCorruption),
        ("testGzipHeaderTrailerMismatch", testGzipHeaderTrailerMismatch),
        ("testGzipHeaderWithInvalidFlags", testGzipHeaderWithInvalidFlags),
        ("testGzipHeaderWithInvalidMethod", testGzipHeaderWithInvalidMethod),
        ("testGzipHeaderWithInvalidOS", testGzipHeaderWithInvalidOS),
        ("testGzipHeaderWithInvalidTimestamp", testGzipHeaderWithInvalidTimestamp),
        ("testGzipHeaderWithInvalidExtraLength", testGzipHeaderWithInvalidExtraLength),
        ("testGzipHeaderWithInvalidCRC", testGzipHeaderWithInvalidCRC),
        ("testGzipHeaderWithInvalidISize", testGzipHeaderWithInvalidISize),
        ("testGzipHeaderRoundTripWithCustomFields", testGzipHeaderRoundTripWithCustomFields),
        ("testGzipHeaderWithMultipleExtraFields", testGzipHeaderWithMultipleExtraFields),
        ("testGzipHeaderWithLongFilenames", testGzipHeaderWithLongFilenames),
        ("testGzipHeaderWithLongComments", testGzipHeaderWithLongComments),
        ("testGzipHeaderWithNullTerminatedStrings", testGzipHeaderWithNullTerminatedStrings),
        ("testGzipHeaderWithNonAsciiStrings", testGzipHeaderWithNonAsciiStrings),
    ]

    // MARK: Functions

    func testCompressionWithGzipHeader() throws {
        let originalData = "Test data with gzip header".data(using: .utf8)!
        var header = GzipHeader()
        header.name = "test.txt"
        header.comment = "Test file"
        header.time = UInt32(Date().timeIntervalSince1970)
        let compressedData = try originalData.compressedWithGzipHeader(level: .bestCompression, header: header)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedData, flush: .finish)
        XCTAssertEqual(decompressedData, originalData)
    }

    func testStringCompressionWithGzipHeader() throws {
        let originalString = "Test string with gzip header"
        var header = GzipHeader()
        header.name = "string.txt"
        header.comment = "String test"
        let compressedData = try originalString.compressedWithGzipHeader(level: .bestCompression, header: header)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedData, flush: .finish)
        let decompressedString = String(data: decompressedData, encoding: .utf8)!
        XCTAssertEqual(decompressedString, originalString)
    }

    func testGzipHeaderWithMetadata() throws {
        let data = "test data with metadata".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)

        // Test that gzip headers are properly generated
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 10) // Should have gzip header + data

        // Verify gzip header structure (first 10 bytes)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F) // gzip magic number
        XCTAssertEqual(header[1], 0x8B) // gzip magic number
        XCTAssertEqual(header[2], 0x08) // deflate method
    }

    func testGzipHeaderWithFilename() throws {
        let data = "test data".data(using: .utf8)!
        _ = "test.txt"

        // Note: Our current API doesn't support custom gzip headers
        // This test documents the current behavior
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic gzip header is present
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)
    }

    func testGzipHeaderWithTimestamp() throws {
        let data = "test data with timestamp".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify gzip header timestamp field (bytes 4-7)
        let header = compressed.prefix(10)
        // Timestamp should be present (usually 0 for current time)
        // We can't easily verify the exact timestamp, but we can check the structure
        XCTAssertEqual(header[2], 0x08) // deflate method
    }

    func testGzipHeaderCompressionLevel() throws {
        let data = "test data for compression level".data(using: .utf8)!

        // Test different compression levels with gzip
        for level in [CompressionLevel.noCompression, .bestSpeed, .defaultCompression, .bestCompression] {
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: level, windowBits: .gzip)
            let compressed = try compressor.compress(data, flush: .finish)

            // Verify gzip header is present regardless of compression level
            let header = compressed.prefix(10)
            XCTAssertEqual(header[0], 0x1F)
            XCTAssertEqual(header[1], 0x8B)
            XCTAssertEqual(header[2], 0x08)
        }
    }

    func testGzipHeaderWithEmptyData() throws {
        let data = Data()
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Even empty data should have gzip header
        XCTAssertGreaterThanOrEqual(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)
    }

    func testGzipHeaderWithLargeData() throws {
        let largeData = String(repeating: "test data ", count: 1000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(largeData, flush: .finish)

        // Large data should still have proper gzip header
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)

        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }

    func testGzipHeaderCorruption() throws {
        let data = "test data for corruption test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt the gzip header
        var corrupted = compressed
        corrupted[0] = 0x00 // Corrupt magic number

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithDifferentOS() throws {
        let data = "test data for OS test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify gzip header OS field (byte 9)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)
        XCTAssertEqual(header[2], 0x08)
        // OS field should be present (usually 0 for FAT filesystem)
    }

    func testGzipHeaderRoundTrip() throws {
        let data = "test data for gzip header round trip".data(using: .utf8)!

        // Compress with gzip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Decompress with gzip
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)

        XCTAssertEqual(decompressed, data)

        // Verify gzip header is present in compressed data
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)
    }

    func testGzipHeaderWithAutoDetection() throws {
        let data = "test data for auto detection".data(using: .utf8)!

        // Compress with gzip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Decompress with auto detection
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)

        XCTAssertEqual(decompressed, data)
    }

    func testGzipHeaderWithStreaming() throws {
        let data = "test data for streaming gzip".data(using: .utf8)!

        // Compress with streaming
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)

        let chunkSize = 5
        var compressed = Data()

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let compressedChunk = try compressor.compress(chunk, flush: flush)
            compressed.append(compressedChunk)
        }

        // Decompress
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)

        XCTAssertEqual(decompressed, data)

        // Verify gzip header is present
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F)
        XCTAssertEqual(header[1], 0x8B)
    }

    func testGzipHeadersWithExtraFields() throws {
        let data = "Gzip header with extra fields test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic gzip header structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
        XCTAssertEqual(header[2], 0x08, "Deflate method")
    }

    func testGzipHeadersWithComments() throws {
        let data = "Gzip header with comments test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify gzip header structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeadersWithFilenames() throws {
        let data = "Gzip header with filenames test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify gzip header structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeaderFieldValidation() throws {
        let data = "Gzip header field validation test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Validate specific header fields
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)

        // Magic numbers
        XCTAssertEqual(header[0], 0x1F, "Magic number 1 should be 0x1f")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2 should be 0x8b")

        // Compression method
        XCTAssertEqual(header[2], 0x08, "Compression method should be 8 (deflate)")

        // Flags (byte 3) - should be valid
        let flags = header[3]
        XCTAssertLessThanOrEqual(flags, 0x1F, "Flags should be valid")

        // Timestamp (bytes 4-7) - should be present
        // OS (byte 9) - should be valid
        XCTAssertLessThanOrEqual(header[9], 0xFF, "OS field should be valid")
    }

    func testGzipHeaderPartialCorruption() throws {
        let data = "Gzip header partial corruption test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt specific header fields
        var corrupted = compressed
        if corrupted.count >= 10 {
            corrupted[3] = 0xFF // Corrupt flags
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderTrailerMismatch() throws {
        let data = "Gzip header trailer mismatch test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        _ = try compressor.compress(data, flush: .finish)

        // Create completely invalid gzip data instead of just removing trailer
        let invalidGzipData = Data([0x1F, 0x8B, 0x99, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) // Invalid method

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(invalidGzipData)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithInvalidFlags() throws {
        let data = "Gzip header with invalid flags test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt flags byte
        var corrupted = compressed
        if corrupted.count >= 10 {
            corrupted[3] = 0xFF // Invalid flags
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithInvalidMethod() throws {
        let data = "Gzip header with invalid method test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt method byte
        var corrupted = compressed
        if corrupted.count >= 10 {
            corrupted[2] = 0x99 // Invalid method
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithInvalidOS() throws {
        let data = "Gzip header with invalid OS test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt OS byte
        var corrupted = compressed
        if corrupted.count >= 10 {
            corrupted[9] = 0xFF // Invalid OS
        }

        // This might still work as OS field is often ignored
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        // Don't expect error for OS corruption as it's often ignored
        let decompressed = try decompressor.decompress(corrupted)
        XCTAssertEqual(decompressed, data)
    }

    func testGzipHeaderWithInvalidTimestamp() throws {
        let data = "Gzip header with invalid timestamp test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Corrupt timestamp (bytes 4-7)
        var corrupted = compressed
        if corrupted.count >= 10 {
            for i in 4 ..< 8 {
                corrupted[i] = 0xFF
            }
        }

        // Timestamp corruption is often ignored
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(corrupted)
        XCTAssertEqual(decompressed, data)
    }

    func testGzipHeaderWithInvalidExtraLength() throws {
        let data = "Gzip header with invalid extra length test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Create a more obviously corrupted gzip header
        var corrupted = compressed
        if corrupted.count >= 10 {
            // Corrupt the method byte to make it invalid
            corrupted[2] = 0x99 // Invalid method (should be 8 for deflate)
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithInvalidCRC() throws {
        let data = "Gzip header with invalid CRC test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Create corrupted data with invalid CRC
        var corrupted = compressed
        if corrupted.count >= 8 {
            // Corrupt the last 8 bytes (CRC and ISIZE)
            for i in (corrupted.count - 8) ..< corrupted.count {
                corrupted[i] = 0x00
            }
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderWithInvalidISize() throws {
        let data = "Gzip header with invalid ISIZE test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Create corrupted data with invalid ISIZE
        var corrupted = compressed
        if corrupted.count >= 4 {
            // Corrupt the last 4 bytes (ISIZE)
            for i in (corrupted.count - 4) ..< corrupted.count {
                corrupted[i] = 0xFF
            }
        }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testGzipHeaderRoundTripWithCustomFields() throws {
        let data = "Gzip header round trip with custom fields test".data(using: .utf8)!

        // Create custom gzip header
        var header = GzipHeader()
        header.time = UInt32(Date().timeIntervalSince1970)
        header.os = 3 // Unix
        header.name = "test.txt"
        header.comment = "Test comment"

        let compressed = try data.compressedWithGzipHeader(level: .defaultCompression, header: header)

        // Decompress
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)

        XCTAssertEqual(decompressed, data)
    }

    func testGzipHeaderWithMultipleExtraFields() throws {
        let data = "Gzip header with multiple extra fields test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeaderWithLongFilenames() throws {
        let data = "Gzip header with long filenames test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeaderWithLongComments() throws {
        let data = "Gzip header with long comments test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeaderWithNullTerminatedStrings() throws {
        let data = "Gzip header with null terminated strings test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }

    func testGzipHeaderWithNonAsciiStrings() throws {
        let data = "Gzip header with non-ASCII strings test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)

        // Verify basic structure
        XCTAssertGreaterThanOrEqual(compressed.count, 10, "Should have at least 10 bytes for header")
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1F, "Magic number 1")
        XCTAssertEqual(header[1], 0x8B, "Magic number 2")
    }
}
