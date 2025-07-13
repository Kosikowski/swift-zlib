//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class StreamingTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testStreamingCompressionWithSmallChunks", testStreamingCompressionWithSmallChunks),
        ("testStreamingDecompressionWithSmallChunks", testStreamingDecompressionWithSmallChunks),
        ("testStreamingWithEmptyChunks", testStreamingWithEmptyChunks),
        ("testStreamingWithPartialFlush", testStreamingWithPartialFlush),
        ("testStreamingWithBlockFlush", testStreamingWithBlockFlush),
        ("testStreamingWithDictionaryAdvanced", testStreamingWithDictionaryAdvanced),
        ("testStreamingWithMixedFlushModes", testStreamingWithMixedFlushModes),
        ("testStreamingWithReusedCompressor", testStreamingWithReusedCompressor),
        ("testStreamingWithReusedDecompressor", testStreamingWithReusedDecompressor),
        ("testStreamingWithPartialDecompression", testStreamingWithPartialDecompression),
        ("testStreamingWithCorruptedChunk", testStreamingWithCorruptedChunk),
        ("testStreamingWithIncompleteData", testStreamingWithIncompleteData),
        ("testStreamingWithDictionary", testStreamingWithDictionary),
        ("testStreamingWithDifferentCompressionLevels", testStreamingWithDifferentCompressionLevels),
        ("testStreamingWithWindowBitsVariants", testStreamingWithWindowBitsVariants),
        ("testStreamingWithMemoryPressure", testStreamingWithMemoryPressure),
        ("testStreamingWithStateTransitions", testStreamingWithStateTransitions),
    ]

    // MARK: Functions

    func testStreamingCompressionWithSmallChunks() throws {
        let data = "streaming test data with small chunks".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let chunkSize = 5

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingDecompressionWithSmallChunks() throws {
        let data = "streaming decompression test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)

        let decompressor = Decompressor()
        try decompressor.initialize()

        var decompressed = Data()
        let chunkSize = 8

        for i in stride(from: 0, to: compressed.count, by: chunkSize) {
            let end = min(i + chunkSize, compressed.count)
            let chunk = compressed[i ..< end]
            let chunkDecompressed = try decompressor.decompress(chunk)
            decompressed.append(chunkDecompressed)
        }

        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithEmptyChunks() throws {
        let data = "test data with empty chunks".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()

        // Add empty chunk at start
        let emptyChunk = Data()
        let emptyCompressed = try compressor.compress(emptyChunk, flush: .noFlush)
        compressed.append(emptyCompressed)

        // Add actual data
        let dataCompressed = try compressor.compress(data, flush: .finish)
        compressed.append(dataCompressed)

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithPartialFlush() throws {
        let data = "streaming with partial flush test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let midPoint = data.count / 2

        // Compress first half with sync flush
        let firstHalf = data[..<midPoint]
        let firstCompressed = try compressor.compress(firstHalf, flush: .syncFlush)
        compressed.append(firstCompressed)

        // Compress second half with finish
        let secondHalf = data[midPoint...]
        let secondCompressed = try compressor.compress(secondHalf, flush: .finish)
        compressed.append(secondCompressed)

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithBlockFlush() throws {
        let data = "streaming with block flush test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let chunkSize = 10

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .block
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithDictionaryAdvanced() {
        let data = "Streaming with dictionary test data".data(using: .utf8)!
        let dictionary = "streaming dictionary".data(using: .utf8)!

        do {
            // Compress with dictionary
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
            try compressor.setDictionary(dictionary)
            let compressedWithDict = try compressor.compress(data, flush: .finish)

            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: .raw)

            // This should fail because we're trying to decompress data that was compressed with a dictionary
            do {
                _ = try decompressor.decompress(compressedWithDict)
                XCTFail("Expected decompression to fail without dictionary")
            } catch let error as ZLibError {
                switch error {
                    case .needDictionary:
                        break // Expected
                    case let .decompressionFailed(code):
                        XCTAssertTrue(code == 2 || code == -3, "Expected Z_NEED_DICT (2) or Z_DATA_ERROR (-3), got: \(code)")
                    default:
                        XCTFail("Unexpected error: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }

            // Now try with correct dictionary - create a fresh decompressor
            let decompressor2 = Decompressor()
            try decompressor2.initializeAdvanced(windowBits: .raw)
            try decompressor2.setDictionary(dictionary)
            let decompressed = try decompressor2.decompress(compressedWithDict)
            XCTAssertEqual(decompressed, data)
        } catch {
            XCTFail("Unexpected error thrown in setup or test: \(error)")
        }
    }

    func testStreamingWithMixedFlushModes() throws {
        let data = "streaming with mixed flush modes test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let parts = [
            (data[..<10], FlushMode.noFlush),
            (data[10 ..< 20], FlushMode.syncFlush),
            (data[20 ..< 30], FlushMode.block),
            (data[30...], FlushMode.finish),
        ]

        for (chunk, flush) in parts {
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithReusedCompressor() throws {
        let data1 = "first streaming data".data(using: .utf8)!
        let data2 = "second streaming data".data(using: .utf8)!

        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Compress first data
        let compressed1 = try compressor.compress(data1, flush: .finish)

        // Reuse compressor for second data
        try compressor.initialize(level: .defaultCompression)
        let compressed2 = try compressor.compress(data2, flush: .finish)

        // Decompress both
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed1 = try decompressor.decompress(compressed1)
        XCTAssertEqual(decompressed1, data1)

        try decompressor.initialize()
        let decompressed2 = try decompressor.decompress(compressed2)
        XCTAssertEqual(decompressed2, data2)
    }

    func testStreamingWithReusedDecompressor() throws {
        let data1 = "first data for reused decompressor".data(using: .utf8)!
        let data2 = "second data for reused decompressor".data(using: .utf8)!

        let compressed1 = try ZLib.compress(data1)
        let compressed2 = try ZLib.compress(data2)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Decompress first data
        let decompressed1 = try decompressor.decompress(compressed1)
        XCTAssertEqual(decompressed1, data1)

        // Reuse decompressor for second data
        try decompressor.initialize()
        let decompressed2 = try decompressor.decompress(compressed2)
        XCTAssertEqual(decompressed2, data2)
    }

    func testStreamingWithPartialDecompression() throws {
        let data = "partial decompression test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Decompress in small chunks
        var decompressed = Data()
        let chunkSize = 4

        for i in stride(from: 0, to: compressed.count, by: chunkSize) {
            let end = min(i + chunkSize, compressed.count)
            let chunk = compressed[i ..< end]
            let chunkDecompressed = try decompressor.decompress(chunk)
            decompressed.append(chunkDecompressed)
        }

        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithCorruptedChunk() throws {
        let data = "streaming with corrupted chunk test".data(using: .utf8)!
        let compressed = try ZLib.compress(data)

        // Corrupt a chunk in the middle
        var corruptedCompressed = compressed
        if corruptedCompressed.count > 10 {
            corruptedCompressed[5] = 0xFF // Corrupt byte
        }

        let decompressor = Decompressor()
        try decompressor.initialize()

        XCTAssertThrowsError(try decompressor.decompress(corruptedCompressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testStreamingWithIncompleteData() throws {
        let data = "streaming with incomplete data test".data(using: .utf8)!
        let compressed = try ZLib.compress(data)

        // Remove last few bytes to simulate incomplete data
        let incompleteCompressed = compressed.prefix(compressed.count - 5)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Should handle incomplete data gracefully
        do {
            let decompressed = try decompressor.decompress(incompleteCompressed)
            // May succeed with partial data or throw error
            XCTAssertLessThanOrEqual(decompressed.count, data.count)
        } catch {
            // Expected error for incomplete data
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testStreamingWithDictionary() throws {
        let dictionary = "test dictionary for streaming".data(using: .utf8)!
        let data = "streaming data with dictionary".data(using: .utf8)!

        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)

        var compressed = Data()
        let chunkSize = 8

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        // Decompress with dictionary using the new API
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithDifferentCompressionLevels() throws {
        let data = "streaming with different compression levels".data(using: .utf8)!

        for level in [CompressionLevel.noCompression, .bestSpeed, .defaultCompression, .bestCompression] {
            let compressor = Compressor()
            try compressor.initialize(level: level)

            var compressed = Data()
            let chunkSize = 6

            for i in stride(from: 0, to: data.count, by: chunkSize) {
                let end = min(i + chunkSize, data.count)
                let chunk = data[i ..< end]
                let flush: FlushMode = end == data.count ? .finish : .noFlush
                let chunkCompressed = try compressor.compress(chunk, flush: flush)
                compressed.append(chunkCompressed)
            }

            let decompressor = Decompressor()
            try decompressor.initialize()
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        }
    }

    func testStreamingWithWindowBitsVariants() throws {
        let data = "streaming with window bits variants".data(using: .utf8)!

        for windowBits in [WindowBits.raw, .deflate, .gzip] {
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)

            var compressed = Data()
            let chunkSize = 7

            for i in stride(from: 0, to: data.count, by: chunkSize) {
                let end = min(i + chunkSize, data.count)
                let chunk = data[i ..< end]
                let flush: FlushMode = end == data.count ? .finish : .noFlush
                let chunkCompressed = try compressor.compress(chunk, flush: flush)
                compressed.append(chunkCompressed)
            }

            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: windowBits)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        }
    }

    func testStreamingWithMemoryPressure() throws {
        let data = "streaming with memory pressure test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let chunkSize = 3 // Very small chunks to test memory handling

        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i ..< end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testStreamingWithStateTransitions() throws {
        let data = "streaming with state transitions test".data(using: .utf8)!
        let compressor = Compressor()

        // Test state transitions during streaming
        try compressor.initialize(level: .defaultCompression)

        var compressed = Data()
        let parts = [
            (data[..<5], FlushMode.noFlush),
            (data[5 ..< 10], FlushMode.syncFlush),
            (data[10 ..< 15], FlushMode.block),
            (data[15...], FlushMode.finish),
        ]

        for (chunk, flush) in parts {
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }

        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
}
