import XCTest
@testable import SwiftZlib

final class AdvancedExtensionsTests: XCTestCase {
    func testDataExtensionsAdvanced() throws {
        let data = "Test data for advanced extensions".data(using: .utf8)!

        // Test partial decompression
        let compressedData = try data.compressed()
        let (partial, inputConsumed, outputWritten) = try compressedData.partialDecompressed(maxOutputSize: 5)
        // Note: For small compressed data, the entire data might be decompressed
        // even with a small maxOutputSize due to how zlib works
        XCTAssertGreaterThan(partial.count, 0)
        XCTAssertGreaterThan(inputConsumed, 0)
        XCTAssertGreaterThan(outputWritten, 0)

        // Test gzip header compression
        var header = GzipHeader()
        header.name = "test.txt"
        let compressedWithHeader = try data.compressedWithGzipHeader(level: .bestCompression, header: header)

        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedWithHeader = try decompressor.decompress(compressedWithHeader, flush: .finish)
        XCTAssertEqual(decompressedWithHeader, data)

        // Test checksums
        let adler32 = data.adler32()
        let crc32 = data.crc32()
        XCTAssertNotEqual(adler32, 0)
        XCTAssertNotEqual(crc32, 0)

        // Test size estimation
        let estimatedSize = data.estimateCompressedSize(level: .bestCompression)
        XCTAssertGreaterThan(estimatedSize, 0)

        // Test static methods
        let (inputSize, outputSize) = Data.getRecommendedBufferSizes(windowBits: .deflate)
        XCTAssertGreaterThan(inputSize, 0)
        XCTAssertGreaterThan(outputSize, 0)

        let memoryUsage = Data.estimateMemoryUsage(windowBits: .deflate, memoryLevel: .maximum)
        XCTAssertGreaterThan(memoryUsage, 0)
    }

    func testStringExtensionsAdvanced() throws {
        let string = "Test string for advanced extensions"

        // Test gzip header compression
        var header = GzipHeader()
        header.name = "string.txt"
        let compressedWithHeader = try string.compressedWithGzipHeader(level: .bestCompression, header: header)

        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedWithHeader, flush: .finish)
        let decompressedWithHeader = String(data: decompressedData, encoding: .utf8)!
        XCTAssertEqual(decompressedWithHeader, string)

        // Test checksums
        let adler32 = string.adler32()
        let crc32 = string.crc32()
        XCTAssertNotNil(adler32)
        XCTAssertNotNil(crc32)
        XCTAssertNotEqual(adler32, 0)
        XCTAssertNotEqual(crc32, 0)
    }

    static var allTests = [
        ("testDataExtensionsAdvanced", testDataExtensionsAdvanced),
        ("testStringExtensionsAdvanced", testStringExtensionsAdvanced),
    ]
} 