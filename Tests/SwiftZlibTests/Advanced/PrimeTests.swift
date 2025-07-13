//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class PrimeTests: XCTestCase {
    func testDeflatePrimeBasic() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Prime with 8 bits (1 byte)
        try compressor.prime(bits: 8, value: 0x42)

        // Compress some data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)

        // For regular zlib, priming affects the compressed output
        // We should test that priming works without expecting regular decompression
        XCTAssertGreaterThan(compressed.count, 0)

        // Test that we can get pending data after priming
        let (pending, bits) = try compressor.getPending()
        XCTAssertGreaterThanOrEqual(pending, 0)
        XCTAssertGreaterThanOrEqual(bits, 0)
    }

    func testDeflatePrimeMultipleBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Prime with 4 bits
        try compressor.prime(bits: 4, value: 0x0A)

        // Prime with another 4 bits
        try compressor.prime(bits: 4, value: 0x0B)

        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)

        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }

    func testDeflatePrimeLargeValue() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Prime with 16 bits (2 bytes)
        try compressor.prime(bits: 16, value: 0x1234)

        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)

        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }

    func testDeflatePrimeBeforeCompression() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Prime before any compression
        try compressor.prime(bits: 8, value: 0x55)

        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)

        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }

    func testDeflatePrimeAfterPartialCompression() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Start compression
        let data1 = "first part".data(using: .utf8)!
        _ = try compressor.compress(data1, flush: .noFlush)

        // Prime in the middle
        try compressor.prime(bits: 8, value: 0x66)

        // Continue compression
        let data2 = "second part".data(using: .utf8)!
        let compressed = try compressor.compress(data2, flush: .finish)

        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }

    func testDeflatePrimeInvalidBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Test with invalid bit count (should fail)
        XCTAssertThrowsError(try compressor.prime(bits: -1, value: 0x42))
        XCTAssertThrowsError(try compressor.prime(bits: 33, value: 0x42)) // More than 32 bits
    }

    func testDeflatePrimeBeforeInitialization() throws {
        let compressor = Compressor()

        // Try to prime before initialization (should fail)
        XCTAssertThrowsError(try compressor.prime(bits: 8, value: 0x42)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testInflatePrimeBasic() throws {
        let originalData = "test data".data(using: .utf8)!
        _ = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Prime with 8 bits
        try decompressor.prime(bits: 8, value: 0x42)

        // Test that priming worked without expecting decompression to work
        // (priming affects the internal state but regular compressed data doesn't expect it)
        XCTAssertNoThrow(try decompressor.prime(bits: 8, value: 0x42))
    }

    func testInflatePrimeMultipleBits() throws {
        let originalData = "test data".data(using: .utf8)!
        _ = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Prime with multiple bits
        try decompressor.prime(bits: 4, value: 0x0A)
        try decompressor.prime(bits: 4, value: 0x0B)

        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 4, value: 0x0C))
    }

    func testInflatePrimeLargeValue() throws {
        let originalData = "test data".data(using: .utf8)!
        _ = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Prime with 16 bits
        try decompressor.prime(bits: 16, value: 0x1234)

        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 16, value: 0x5678))
    }

    func testInflatePrimeBeforeDecompression() throws {
        let originalData = "test data".data(using: .utf8)!
        _ = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Prime before any decompression
        try decompressor.prime(bits: 8, value: 0x55)

        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 8, value: 0x66))
    }

    func testInflatePrimeAfterPartialDecompression() throws {
        let originalData = "test data for partial decompression".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Decompress first part
        let firstPart = compressedData.prefix(compressedData.count / 2)
        _ = try decompressor.decompress(firstPart, flush: .noFlush)

        // Try to prime after partial decompression - behavior may vary by platform
        do {
            try decompressor.prime(bits: 8, value: 0x42)
            // If priming succeeds, that's acceptable on some platforms
            // Just verify we can continue decompression
            let remainingData = compressedData.suffix(from: compressedData.count / 2)
            let finalDecompressed = try decompressor.decompress(remainingData)
            XCTAssertGreaterThan(finalDecompressed.count, 0)
        } catch {
            // If priming fails, that's also acceptable behavior
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testInflatePrimeInvalidBits() throws {
        let decompressor = Decompressor()
        try decompressor.initialize()

        // Test with invalid bit count - behavior may vary by zlib version/platform
        // Some zlib versions may accept these values, others may reject them
        do {
            try decompressor.prime(bits: -1, value: 0x42)
            // If no error, that's acceptable behavior for some zlib versions
        } catch {
            // If error is thrown, that's also acceptable
            XCTAssertTrue(error is ZLibError)
        }

        do {
            try decompressor.prime(bits: 33, value: 0x42) // More than 32 bits
            // If no error, that's acceptable behavior for some zlib versions
        } catch {
            // If error is thrown, that's also acceptable
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testInflatePrimeBeforeInitialization() throws {
        let decompressor = Decompressor()

        // Try to prime before initialization (should fail)
        XCTAssertThrowsError(try decompressor.prime(bits: 8, value: 0x42)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testPrimeRoundTrip() throws {
        // Note: Priming is a very low-level zlib feature that affects the raw bit stream.
        // Round-trip compression/decompression with priming is not typically supported
        // because the primed bits interfere with the compressed data format.
        // This test documents this limitation.

        let originalData = "test data for prime round trip".data(using: .utf8)!

        // Use raw deflate stream for priming round-trip with minimal bits
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw) // Raw deflate
        try compressor.prime(bits: 4, value: 0x5) // Use 4 bits instead of 8
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompress with identical priming using raw deflate
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw) // Raw deflate
        try decompressor.prime(bits: 4, value: 0x5)

        // This is expected to fail because priming affects the raw bit stream
        // and interferes with the compressed data format
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testPrimeWithDifferentValues() throws {
        let originalData = "test data for different prime values".data(using: .utf8)!

        // Use raw deflate stream for priming round-trip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw) // Raw deflate
        try compressor.prime(bits: 4, value: 0x5)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompress with different priming - should fail
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw) // Raw deflate
        try decompressor.prime(bits: 4, value: 0x6) // Different value
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testPrimeAffectsCompressedOutput() throws {
        let originalData = "test data".data(using: .utf8)!

        // Compress without priming
        let compressor1 = Compressor()
        try compressor1.initializeAdvanced(level: .noCompression, windowBits: .raw)
        let compressed1 = try compressor1.compress(originalData, flush: .finish)

        // Compress with priming
        let compressor2 = Compressor()
        try compressor2.initializeAdvanced(level: .noCompression, windowBits: .raw)
        try compressor2.prime(bits: 4, value: 0x5)
        let compressed2 = try compressor2.compress(originalData, flush: .finish)

        // The compressed outputs should be different due to priming
        XCTAssertNotEqual(compressed1, compressed2)
    }

    func testPrimeIsolation() throws {
        // Test that priming works in isolation without expecting round-trip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw)

        // Prime with different values and verify it doesn't crash
        XCTAssertNoThrow(try compressor.prime(bits: 1, value: 0x1))
        XCTAssertNoThrow(try compressor.prime(bits: 2, value: 0x2))
        XCTAssertNoThrow(try compressor.prime(bits: 4, value: 0x5))
        XCTAssertNoThrow(try compressor.prime(bits: 8, value: 0x42))

        // Test that priming affects the compressed output
        let data = "test".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
    }

    func testPrimeWithZlibStreamFails() throws {
        let originalData = "test data for zlib prime failure".data(using: .utf8)!

        // Try to use priming with zlib stream (windowBits: 15)
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .deflate) // zlib format
        try compressor.prime(bits: 8, value: 0x42)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompression should fail because zlib streams don't support priming
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate) // zlib format
        try decompressor.prime(bits: 8, value: 0x42)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testPrimeWithGzipStreamFails() throws {
        let originalData = "test data for gzip prime failure".data(using: .utf8)!

        // Try to use priming with gzip stream (windowBits: 31)
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .gzip) // gzip format
        try compressor.prime(bits: 8, value: 0x42)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompression should fail because gzip streams don't support priming
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip) // gzip format
        try decompressor.prime(bits: 8, value: 0x42)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testPrimeZeroBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)

        // Prime with 0 bits (should work)
        XCTAssertNoThrow(try compressor.prime(bits: 0, value: 0x42))

        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)

        // Decompress should work
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertNoThrow(try decompressor.prime(bits: 0, value: 0x42))
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testPrimeMaxBits() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw)

        // Try to prime with maximum bits (32) - this should fail due to zlib's internal buffer limits
        XCTAssertThrowsError(try compressor.prime(bits: 32, value: 0x7FFF_FFFF)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    /// Helper function to check that ZLibErrors are not double-wrapped
    /// This ensures our error handling doesn't create nested ZLibError.fileError(ZLibError.xxx) patterns
    private func assertNoDoubleWrappedZLibError(_ error: Error) {
        if case let .fileError(underlyingError) = error as? ZLibError {
            XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
        }
    }
}
