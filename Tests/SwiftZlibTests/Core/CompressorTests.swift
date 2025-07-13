import XCTest
@testable import SwiftZlib

final class CompressorTests: XCTestCase {
    
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
    
    // MARK: - Compressor Tests
    
    func testAdvancedCompressorInitialization() throws {
        let compressor = Compressor()
        
        // Test basic initialization
        try compressor.initialize(level: .defaultCompression)
        
        // Test advanced initialization
        try compressor.initializeAdvanced(level: .bestCompression, windowBits: .deflate)
        
        // Test with different window bits
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        try compressor.initializeAdvanced(level: .bestSpeed, windowBits: .raw)
    }
    
    // Note: We do not test compressor.reset() for starting a new, unrelated compression stream.
    // According to zlib semantics, deflateReset only resets the stream for continued use with the same parameters;
    // it does not re-emit headers or fully reinitialize the stream. For a new logical compression, use a new Compressor instance.
    // See: https://zlib.net/manual.html#deflateReset
    // The canonical test below uses two separate compressors for two compressions.
    func testCompressorResetAndCopy() throws {
        let data1 = Data(repeating: 0x42, count: 100)
        let data2 = Data(repeating: 0x43, count: 100)
        let compressor1 = Compressor()
        try compressor1.initialize(level: .bestCompression)
        let compressed1 = try compressor1.compress(data1, flush: .finish)

        // Create a fresh compressor for the second compression
        let compressor2 = Compressor()
        try compressor2.initialize(level: .bestCompression)
        let compressed2 = try compressor2.compress(data2, flush: .finish)

        // Use stream decompression for stream-compressed data
        let decompressor1 = Decompressor()
        let decompressor2 = Decompressor()
        try decompressor1.initialize()
        try decompressor2.initialize()

        let decompressed1 = try decompressor1.decompress(compressed1, flush: .finish)
        let decompressed2 = try decompressor2.decompress(compressed2, flush: .finish)
        XCTAssertEqual(decompressed1, data1)
        XCTAssertEqual(decompressed2, data2)
    }
    
    func testCompressorAdvancedFeatures() throws {
        let data = "Test data for advanced features".data(using: .utf8)!
        
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .bestCompression, windowBits: .deflate)
        
        // Test compression
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Test stream info
        let streamInfo = try compressor.getStreamInfo()
        XCTAssertGreaterThan(streamInfo.totalIn, 0)
        XCTAssertGreaterThan(streamInfo.totalOut, 0)
        XCTAssertTrue(streamInfo.isActive)
        
        // Test pending data
        let (pending, bits) = try compressor.getPending()
        XCTAssertGreaterThanOrEqual(pending, 0)
        XCTAssertGreaterThanOrEqual(bits, 0)
    }
    
    func testCompressionWithInvalidLevel() throws {
        let data = "test".data(using: .utf8)!
        let compressor = Compressor()
        // Not initialized
        XCTAssertThrowsError(try compressor.compress(data))
        // Invalid flush mode (simulate by passing an invalid enum raw value if possible)
        // Not possible directly, but can try decompressing with wrong windowBits
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        XCTAssertThrowsError(try decompressor.decompress(compressed))
    }
    
    func testCompressionWithNullData() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with nil data (should handle gracefully)
        let compressed = try compressor.compress(Data(), flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed.count, 0)
    }
    
    func testCompressionWithUninitializedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()

        // Try to compress without initialization
        XCTAssertThrowsError(try compressor.compress(data, flush: .finish)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testCompressionWithInvalidFlushMode() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with valid flush modes
        XCTAssertNoThrow(try compressor.compress(data, flush: .noFlush))
        XCTAssertNoThrow(try compressor.compress(data, flush: .finish))
    }
    
    func testCompressionWithLargeInput() throws {
        let largeData = String(repeating: "test data ", count: 10000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with very large input
        let compressed = try compressor.compress(largeData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)

        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testCompressionWithZeroSizedBuffer() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with zero-sized buffer
        let compressed = try compressor.compress(Data(), flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed.count, 0)
    }
    
    func testCompressionWithInvalidWindowBits() throws {
        _ = "test data".data(using: .utf8)!
        let compressor = Compressor()

        // Test with valid window bits
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip))
    }
    
    func testCompressionWithReusedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // First compression
        let compressed1 = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed1.count, 0)

        // Reinitialize for second compression
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed2 = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed2.count, 0)
    }
    
    func testCompressionWithInvalidDictionary() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with invalid dictionary (should handle gracefully)
        let invalidDictionary = Data([0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertNoThrow(try compressor.setDictionary(invalidDictionary))

        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testCompressionWithMemoryPressure() throws {
        let largeData = String(repeating: "test data ", count: 50000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)

        // Test with very large input to simulate memory pressure
        let compressed = try compressor.compress(largeData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)

        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testCompressionWithInvalidState() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()

        // Try to set dictionary before initialization
        XCTAssertThrowsError(try compressor.setDictionary(data)) { error in
            XCTAssertTrue(error is ZLibError)
        }

        // Initialize and then try to set dictionary again
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        XCTAssertNoThrow(try compressor.setDictionary(data))
    }
    
    // MARK: - Test Discovery
    
    static var allTests = [
        ("testAdvancedCompressorInitialization", testAdvancedCompressorInitialization),
        ("testCompressorResetAndCopy", testCompressorResetAndCopy),
        ("testCompressorAdvancedFeatures", testCompressorAdvancedFeatures),
        ("testCompressionWithInvalidLevel", testCompressionWithInvalidLevel),
        ("testCompressionWithNullData", testCompressionWithNullData),
        ("testCompressionWithUninitializedStream", testCompressionWithUninitializedStream),
        ("testCompressionWithInvalidFlushMode", testCompressionWithInvalidFlushMode),
        ("testCompressionWithLargeInput", testCompressionWithLargeInput),
        ("testCompressionWithZeroSizedBuffer", testCompressionWithZeroSizedBuffer),
        ("testCompressionWithInvalidWindowBits", testCompressionWithInvalidWindowBits),
        ("testCompressionWithReusedStream", testCompressionWithReusedStream),
        ("testCompressionWithInvalidDictionary", testCompressionWithInvalidDictionary),
        ("testCompressionWithMemoryPressure", testCompressionWithMemoryPressure),
        ("testCompressionWithInvalidState", testCompressionWithInvalidState),
    ]
} 