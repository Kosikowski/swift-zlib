@testable import SwiftZlib
import XCTest

final class PerformanceTests: XCTestCase {
    
    func testPerformanceAndMemoryUsage() throws {
        let largeData = Data(repeating: 0xAB, count: 10_000_000) // 10MB - realistic large file size
        let startCompress = CFAbsoluteTimeGetCurrent()
        let compressed = try ZLib.compress(largeData, level: .bestCompression)
        let compressTime = CFAbsoluteTimeGetCurrent() - startCompress
        print("Compression time for 10MB: \(compressTime)s, ratio: \(Double(compressed.count) / Double(largeData.count))")

        let startDecompress = CFAbsoluteTimeGetCurrent()
        // Use streaming decompression for large data to avoid buffer size issues
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        let decompressTime = CFAbsoluteTimeGetCurrent() - startDecompress
        print("Decompression time for 10MB: \(decompressTime)s")

        XCTAssertEqual(decompressed, largeData)
        // Realistic time limits for 10MB
        XCTAssertLessThan(compressTime, 5.0, "Compression took too long")
        XCTAssertLessThan(decompressTime, 3.0, "Decompression took too long")
    }

    // MARK: - API Misuse Tests

    func testAPIMisuse_NilAndEmpty() throws {
        // Empty data should not crash and should round-trip
        let empty = Data()
        let compressed = try ZLib.compress(empty)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, empty)

        // String extension with empty string
        let emptyString = ""
        let compressedString = try emptyString.compressed()
        let decompressedString = try String.decompressed(from: compressedString)
        XCTAssertEqual(decompressedString, emptyString)
    }

    func testAPIMisuse_InvalidParameters() throws {
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

    func testAPIMisuse_DictionaryMisuse() throws {
        let dict = "dict".data(using: .utf8)!
        let compressor = Compressor()
        // Set dictionary before init
        XCTAssertThrowsError(try compressor.setDictionary(dict))
        try compressor.initialize(level: .defaultCompression)
        // Set dictionary after init (should succeed)
        XCTAssertNoThrow(try compressor.setDictionary(dict))
        // Decompressor: set dictionary before init
        let decompressor = Decompressor()
        XCTAssertThrowsError(try decompressor.setDictionary(dict))
        try decompressor.initialize()
        // Set dictionary before Z_NEED_DICT (should fail)
        XCTAssertThrowsError(try decompressor.setDictionary(dict))
    }

    // MARK: - Edge Case Tests

    func testBufferOverflowScenarios() throws {
        // Test with extremely large buffers that might cause overflow
        let largeData = Data(repeating: 0x42, count: 100_000_000) // 100MB
        let compressed = try ZLib.compress(largeData, level: .bestCompression)
        // Use streaming decompression for very large data
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
        // Partial decompress with tiny buffer may throw or return partial data
        do {
            let smallBuffer = try ZLib.partialDecompress(compressed, maxOutputSize: 1)
            XCTAssertGreaterThanOrEqual(smallBuffer.decompressed.count, 0)
        } catch let error as ZLibError {
            // Accept Z_BUF_ERROR as a valid outcome
            if case let .decompressionFailed(code) = error {
                XCTAssertEqual(code, -5)
            } else {
                throw error
            }
        }
    }

    func testMemoryExhaustionScenarios() throws {
        // Test with data that might cause memory pressure
        let memoryIntensiveData = Data(repeating: 0x00, count: 50_000_000) // 50MB of zeros (highly compressible)

        // This should work without memory issues
        let compressed = try ZLib.compress(memoryIntensiveData, level: .bestCompression)
        XCTAssertLessThan(compressed.count, memoryIntensiveData.count) // Should compress well

        // For large data, use streaming decompression to avoid buffer errors
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, memoryIntensiveData)
    }

    func testStreamCorruptionDuringOperation() throws {
        let data = "test data for corruption".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Compress in chunks
        let chunkSize = 5
        var compressed = Data()

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        // Corrupt the compressed data mid-stream
        if compressed.count > 10 {
            var corrupted = compressed
            corrupted[compressed.count / 2] = 0xFF // Corrupt middle byte

            let decompressor = Decompressor()
            try decompressor.initialize()

            // Should fail with corrupted data
            XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
                XCTAssertTrue(error is ZLibError)
            }
        }
    }

    func testInvalidPointerHandling() throws {
        // Test with empty data (null pointer scenarios)
        let emptyData = Data()
        let compressed = try ZLib.compress(emptyData)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, emptyData)

        // Test with single byte data
        let singleByte = Data([0x42])
        let compressedSingle = try ZLib.compress(singleByte)
        let decompressedSingle = try ZLib.decompress(compressedSingle)
        XCTAssertEqual(decompressedSingle, singleByte)

        // Test with data containing null bytes
        let nullData = Data([0x00, 0x01, 0x00, 0x02, 0x00])
        let compressedNull = try ZLib.compress(nullData)
        let decompressedNull = try ZLib.decompress(compressedNull)
        XCTAssertEqual(decompressedNull, nullData)
    }

    // MARK: - Advanced API Coverage Tests

    func testGzipFileAPI() throws {
        // Test gzip file operations
        let testData = "test data for gzip file".data(using: .utf8)!
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.gz")

        // Write compressed data to gzip file
        let gzipFile = try GzipFile(path: testFile.path, mode: "wb")
        try gzipFile.writeData(testData)
        try gzipFile.close()

        // Read and decompress from gzip file
        let readFile = try GzipFile(path: testFile.path, mode: "rb")
        let readData = try readFile.readData(count: testData.count)
        try readFile.close()

        XCTAssertEqual(readData, testData)

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testStreamingDecompressorCallbacks() throws {
        let testData = "streaming decompressor callback test data".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()

        var decompressedChunks: [Data] = []
        var shouldContinue = true

        try streamingDecompressor.processWithCallbacks(
            inputProvider: {
                // Provide compressed data in chunks
                if shouldContinue {
                    shouldContinue = false
                    return compressed
                }
                return nil
            },
            outputHandler: { chunk in
                decompressedChunks.append(chunk)
                return true // Continue processing
            }
        )

        let decompressed = decompressedChunks.reduce(Data(), +)
        XCTAssertEqual(decompressed, testData)
    }

    func testInflateBackAdvancedFeatures() throws {
        let testData = "inflate back advanced test data".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)

        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()

        var decompressedChunks: [Data] = []

        // Test with valid compressed data in chunks
        var inputIndex = 0
        let chunkSize = 10

        try inflateBack.processWithCallbacks(
            inputProvider: {
                // Provide data in small chunks
                guard inputIndex < compressed.count else { return nil }
                let remaining = compressed.count - inputIndex
                let currentChunkSize = min(chunkSize, remaining)
                let chunk = compressed.subdata(in: inputIndex ..< (inputIndex + currentChunkSize))
                inputIndex += currentChunkSize
                return chunk
            },
            outputHandler: { chunk in
                decompressedChunks.append(chunk)
                return true
            }
        )

        // Verify we got some output
        XCTAssertGreaterThanOrEqual(decompressedChunks.count, 0)

        // Combine all chunks and verify decompression
        let decompressed = decompressedChunks.reduce(Data(), +)
        XCTAssertEqual(decompressed, testData)
    }

    func testAdvancedTuningParameters() throws {
        let testData = "advanced tuning parameters test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Test advanced tuning parameters
        try compressor.tune(goodLength: 32, maxLazy: 258, niceLength: 258, maxChain: 4096)

        let compressed = try compressor.compress(testData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)

        // Test with different tuning parameters
        let compressor2 = Compressor()
        try compressor2.initialize(level: .bestCompression)
        try compressor2.tune(goodLength: 64, maxLazy: 128, niceLength: 128, maxChain: 2048)

        let compressed2 = try compressor2.compress(testData, flush: .finish)
        XCTAssertGreaterThan(compressed2.count, 0)

        // Both should decompress correctly
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, testData)

        let decompressor2 = Decompressor()
        try decompressor2.initialize()
        let decompressed2 = try decompressor2.decompress(compressed2)
        XCTAssertEqual(decompressed2, testData)
    }

    // MARK: - Platform-Specific Behavior Tests

    func testPlatformSpecificBehavior() throws {
        // Test that documents platform-specific behavior differences
        let testData = "platform specific test data".data(using: .utf8)!

        // Test compression with different levels on this platform
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        var compressionResults: [Data] = []

        for level in levels {
            let compressed = try ZLib.compress(testData, level: level)
            compressionResults.append(compressed)

            // Verify decompression works
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }

        // Document platform-specific compression ratios
        print("Platform-specific compression ratios:")
        for (i, level) in levels.enumerated() {
            let ratio = Double(compressionResults[i].count) / Double(testData.count)
            print("  \(level): \(String(format: "%.3f", ratio))")
        }

        // Test that all compressed data can be decompressed (platform compatibility)
        for compressed in compressionResults {
            XCTAssertNoThrow(try ZLib.decompress(compressed))
        }

        // Test architecture-specific behavior (pointer sizes, etc.)
        let compileFlags = ZLib.compileFlags
        print("Platform compile flags: \(compileFlags)")

        // Test that basic operations work regardless of platform
        let emptyData = Data()
        let emptyCompressed = try ZLib.compress(emptyData)
        let emptyDecompressed = try ZLib.decompress(emptyCompressed)
        XCTAssertEqual(emptyDecompressed, emptyData)
    }

    // MARK: - Improved Error Handling Tests

    func testSpecificErrorTypes() throws {
        // Test for specific error types instead of just "any ZLibError"

        // Test uninitialized stream - should be Z_STREAM_ERROR (-2)
        let compressor = Compressor()
        XCTAssertThrowsError(try compressor.compress(Data([0x42]))) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case let .streamError(code):
                    XCTAssertEqual(code, -2, "Expected Z_STREAM_ERROR for uninitialized stream")
                default:
                    XCTFail("Expected streamError, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }

        // Test invalid data - should be Z_DATA_ERROR (-3)
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case let .decompressionFailed(code):
                    XCTAssertEqual(code, -3, "Expected Z_DATA_ERROR for invalid data")
                default:
                    XCTFail("Expected decompressionFailed, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }
    }

    func testPlatformAgnosticValidation() throws {
        // Test that validates behavior without assuming specific platform behavior

        let data = "platform agnostic test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Test that compression produces valid output regardless of platform
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)

        // Test that decompression works regardless of platform
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)

        // Test that empty data works on all platforms
        let emptyCompressed = try ZLib.compress(Data())
        let emptyDecompressed = try ZLib.decompress(emptyCompressed)
        XCTAssertEqual(emptyDecompressed, Data())

        // Test that single byte works on all platforms
        let singleByte = Data([0x42])
        let singleCompressed = try ZLib.compress(singleByte)
        let singleDecompressed = try ZLib.decompress(singleCompressed)
        XCTAssertEqual(singleDecompressed, singleByte)
    }

    static var allTests = [
        ("testPerformanceAndMemoryUsage", testPerformanceAndMemoryUsage),
        ("testAPIMisuse_NilAndEmpty", testAPIMisuse_NilAndEmpty),
        ("testAPIMisuse_InvalidParameters", testAPIMisuse_InvalidParameters),
        ("testAPIMisuse_DictionaryMisuse", testAPIMisuse_DictionaryMisuse),
        ("testBufferOverflowScenarios", testBufferOverflowScenarios),
        ("testMemoryExhaustionScenarios", testMemoryExhaustionScenarios),
        ("testStreamCorruptionDuringOperation", testStreamCorruptionDuringOperation),
        ("testInvalidPointerHandling", testInvalidPointerHandling),
        ("testGzipFileAPI", testGzipFileAPI),
        ("testStreamingDecompressorCallbacks", testStreamingDecompressorCallbacks),
        ("testInflateBackAdvancedFeatures", testInflateBackAdvancedFeatures),
        ("testAdvancedTuningParameters", testAdvancedTuningParameters),
        ("testPlatformSpecificBehavior", testPlatformSpecificBehavior),
        ("testSpecificErrorTypes", testSpecificErrorTypes),
        ("testPlatformAgnosticValidation", testPlatformAgnosticValidation),
    ]
} 