import XCTest
@testable import SwiftZlib

// MARK: - MemoryLeakTests

final class MemoryLeakTests: XCTestCase {
    /// Test basic compressor lifecycle - create, use, destroy
    func testCompressorLifecycle() throws {
        // Create compressor
        let compressor = Compressor()

        // Initialize
        try compressor.initialize(level: .defaultCompression)

        // Use it
        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try compressor.compress(testData, flush: .finish)

        // Verify compression worked
        XCTAssertGreaterThan(compressed.count, 0)

        // Compressor will be deallocated here, triggering deinit
    }

    /// Test basic decompressor lifecycle - create, use, destroy
    func testDecompressorLifecycle() throws {
        // Create decompressor
        let decompressor = Decompressor()

        // Initialize
        try decompressor.initialize()

        // Create some compressed data to decompress
        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        // Use decompressor
        let decompressed = try decompressor.decompress(compressed)

        // Verify decompression worked
        XCTAssertEqual(decompressed, testData)

        // Decompressor will be deallocated here, triggering deinit
    }

    /// Test compressor with gzip header lifecycle
    func testCompressorWithGzipHeaderLifecycle() throws {
        // Create compressor
        let compressor = Compressor()

        // Initialize with gzip format
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)

        // Set gzip header
        var header = GzipHeader()
        header.name = "test.txt"
        header.comment = "Test file"
        try compressor.setGzipHeader(header)

        // Use it
        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try compressor.compress(testData, flush: .finish)

        // Verify compression worked
        XCTAssertGreaterThan(compressed.count, 0)

        // Compressor will be deallocated here, triggering deinit
    }

    /// Test multiple compressors in sequence
    func testMultipleCompressors() throws {
        for i in 0 ..< 10 {
            let compressor = Compressor()
            try compressor.initialize(level: .defaultCompression)

            let testData = "Test data \(i)".data(using: .utf8)!
            let compressed = try compressor.compress(testData, flush: .finish)

            XCTAssertGreaterThan(compressed.count, 0)
            // Compressor deallocated here
        }
    }

    /// Test multiple decompressors in sequence
    func testMultipleDecompressors() throws {
        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        for _ in 0 ..< 10 {
            let decompressor = Decompressor()
            try decompressor.initialize()

            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, testData)

            // Decompressor deallocated here
        }
    }

    /// Test error handling during initialization
    func testCompressorInitializationError() throws {
        let compressor = Compressor()

        // This should not leak memory even if initialization fails
        do {
            // Try to use without initialization
            let testData = "Hello".data(using: .utf8)!
            _ = try compressor.compress(testData)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertTrue(error is ZLibError)
        }

        // Compressor should still be deallocated properly
    }

    /// Test error handling during decompression
    func testDecompressorErrorHandling() throws {
        let decompressor = Decompressor()
        try decompressor.initialize()

        // Try to decompress invalid data
        let invalidData = Data([0x1, 0x2, 0x3, 0x4, 0x5])

        do {
            _ = try decompressor.decompress(invalidData)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertTrue(error is ZLibError)
        }

        // Decompressor should still be deallocated properly
    }

    /// Test InflateBackDecompressor lifecycle
    func testInflateBackDecompressorLifecycle() throws {
        let decompressor = BaseInflateBackDecompressor()
        try decompressor.initialize()

        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        let decompressed = try decompressor.processData(compressed)
        XCTAssertEqual(decompressed, testData)

        // Decompressor will be deallocated here
    }

    /// Test InflateBackDecompressorCBridged lifecycle
    func testInflateBackDecompressorCBridgedLifecycle() throws {
        let decompressor = InflateBackDecompressorCBridged()
        try decompressor.initialize()

        let testData = "Hello, World!".data(using: .utf8)!

        // Use raw deflate compression for InflateBack compatibility
        let compressor = Compressor()
        try compressor.initializeAdvanced(windowBits: .raw)
        let compressed = try compressor.compress(testData, flush: .finish)

        let decompressed = try decompressor.processData(compressed)
        XCTAssertEqual(decompressed, testData)

        // Decompressor will be deallocated here
    }

    /// Test streaming operations lifecycle
    func testStreamingLifecycle() throws {
        let stream = ZLibStream(mode: .compress)
        try stream.initialize()

        let testData = "Hello, World!".data(using: .utf8)!
        let output = try stream.process(testData)
        let finalOutput = try stream.finalize()

        XCTAssertGreaterThan(output.count + finalOutput.count, 0)

        // Stream will be deallocated here
    }

    /// Test async stream lifecycle
    func testAsyncStreamLifecycle() async throws {
        let stream = AsyncZLibStream(mode: .compress)
        try await stream.initialize()

        let testData = "Hello, World!".data(using: .utf8)!
        let compressed = try await stream.process(testData)
        let finalCompressed = try await stream.finalize()

        XCTAssertGreaterThan(compressed.count + finalCompressed.count, 0)

        // Stream will be deallocated here
    }

    /// Test memory pressure scenarios
    func testMemoryPressure() throws {
        // Create many objects to stress memory management
        var compressors: [Compressor] = []
        var decompressors: [Decompressor] = []

        for _ in 0 ..< 50 {
            let compressor = Compressor()
            try compressor.initialize(level: .defaultCompression)
            compressors.append(compressor)

            let decompressor = Decompressor()
            try decompressor.initialize()
            decompressors.append(decompressor)
        }

        // Use them
        let testData = "Test data".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        for compressor in compressors {
            let _ = try compressor.compress(testData, flush: .finish)
        }

        for decompressor in decompressors {
            let _ = try decompressor.decompress(compressed)
        }

        // All objects will be deallocated here
    }

    /// Test rapid create/destroy cycles
    func testRapidCreateDestroy() throws {
        for _ in 0 ..< 100 {
            let compressor = Compressor()
            try compressor.initialize(level: .defaultCompression)

            let testData = "Quick test".data(using: .utf8)!
            let _ = try compressor.compress(testData, flush: .finish)

            // Compressor deallocated immediately
        }
    }

    /// Test with different compression levels
    func testDifferentCompressionLevels() throws {
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]

        for level in levels {
            let compressor = Compressor()
            try compressor.initialize(level: level)

            let testData = "Test data for level \(level)".data(using: .utf8)!
            let compressed = try compressor.compress(testData, flush: .finish)

            XCTAssertGreaterThan(compressed.count, 0)

            // Compressor deallocated here
        }
    }

    /// Test with different window bits
    func testDifferentWindowBits() throws {
        let windowBits: [WindowBits] = [.deflate, .gzip, .raw]

        for windowBit in windowBits {
            let compressor = Compressor()
            try compressor.initializeAdvanced(windowBits: windowBit)

            let testData = "Test data for window bits \(windowBit)".data(using: .utf8)!
            let compressed = try compressor.compress(testData, flush: .finish)

            XCTAssertGreaterThan(compressed.count, 0)

            // Compressor deallocated here
        }
    }

    /// Minimal test to isolate allocation/deallocation for AddressSanitizer
    func testIsolatedAllocationDeallocation() throws {
        // Allocate and deallocate Compressor
        do {
            let compressor = Compressor()
            try compressor.initialize(level: .defaultCompression)
            let testData = "leak test".data(using: .utf8)!
            let _ = try compressor.compress(testData, flush: .finish)
            // Compressor deallocated at end of scope
        }
        // Allocate and deallocate Decompressor
        do {
            let decompressor = Decompressor()
            try decompressor.initialize()
            let testData = "leak test".data(using: .utf8)!
            let compressed = try ZLib.compress(testData)
            let _ = try decompressor.decompress(compressed)
            // Decompressor deallocated at end of scope
        }
    }
}

#if !os(macOS)
    extension MemoryLeakTests {
        static var allTests = [
            ("testCompressorLifecycle", testCompressorLifecycle),
            ("testDecompressorLifecycle", testDecompressorLifecycle),
            ("testCompressorWithGzipHeaderLifecycle", testCompressorWithGzipHeaderLifecycle),
            ("testMultipleCompressors", testMultipleCompressors),
            ("testMultipleDecompressors", testMultipleDecompressors),
            ("testCompressorInitializationError", testCompressorInitializationError),
            ("testDecompressorErrorHandling", testDecompressorErrorHandling),
            ("testInflateBackDecompressorLifecycle", testInflateBackDecompressorLifecycle),
            ("testInflateBackDecompressorCBridgedLifecycle", testInflateBackDecompressorCBridgedLifecycle),
            ("testStreamingLifecycle", testStreamingLifecycle),
            // async test omitted for Linux unless using --enable-test-discovery
            ("testMemoryPressure", testMemoryPressure),
            ("testRapidCreateDestroy", testRapidCreateDestroy),
            ("testDifferentCompressionLevels", testDifferentCompressionLevels),
            ("testDifferentWindowBits", testDifferentWindowBits),
            ("testIsolatedAllocationDeallocation", testIsolatedAllocationDeallocation),
        ]
    }
#endif
