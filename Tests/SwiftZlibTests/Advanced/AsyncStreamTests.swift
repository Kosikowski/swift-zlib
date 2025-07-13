//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class AsyncStreamTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testAsyncAwaitSupport", testAsyncAwaitSupport),
    ]

    // MARK: Functions

    // MARK: - Async/Await and AsyncStream Tests (verbatim from monolithic file)

    func testAsyncAwaitSupport() async throws {
        let original = "Async/await compression test data".data(using: .utf8)!

        // Test 1: Simple async compression/decompression
        let compressed = try await ZLib.compressAsync(original)
        let decompressed = try await ZLib.decompressAsync(compressed)

        XCTAssertNotEqual(compressed.count, 0)
        XCTAssertEqual(decompressed, original)

        // Test 2: Async compression with options
        let compressionOptions = CompressionOptions(
            format: .gzip,
            level: .bestCompression
        )
        let compressedWithOptions = try await ZLib.compressAsync(original, options: compressionOptions)
        XCTAssertNotEqual(compressedWithOptions.count, 0)

        // Test 3: Async decompression with options
        let decompressionOptions = DecompressionOptions(format: .gzip)
        let decompressedWithOptions = try await ZLib.decompressAsync(compressedWithOptions, options: decompressionOptions)
        XCTAssertEqual(decompressedWithOptions, original)

        // Test 4: Async streaming compression
        let asyncCompressor = AsyncCompressor(options: compressionOptions)
        try await asyncCompressor.initialize()

        let streamCompressed = try await asyncCompressor.compress(original, flush: FlushMode.finish)
        XCTAssertNotEqual(streamCompressed.count, 0)

        // Test 5: Async streaming decompression
        let asyncDecompressor = AsyncDecompressor(options: decompressionOptions)
        try await asyncDecompressor.initialize()

        let streamDecompressed = try await asyncDecompressor.decompress(streamCompressed)
        XCTAssertEqual(streamDecompressed, original)

        // Test 6: Async unified streaming API
        let asyncStream = ZLib.asyncStream()
            .compress()
            .format(.zlib)
            .level(.bestSpeed)
            .bufferSize(1024)
            .build()

        try await asyncStream.initialize()
        let unifiedCompressed = try await asyncStream.process(original, flush: FlushMode.finish)
        XCTAssertNotEqual(unifiedCompressed.count, 0)

        // Test 7: Async unified streaming decompression
        let asyncDecompressStream = ZLib.asyncStream()
            .decompress()
            .format(.zlib)
            .bufferSize(1024)
            .build()

        try await asyncDecompressStream.initialize()
        let unifiedDecompressed = try await asyncDecompressStream.process(unifiedCompressed)
        XCTAssertEqual(unifiedDecompressed, original)

        // Test 8: Async streaming with chunks
        let chunkStream = ZLib.asyncStream().compress().format(.gzip).build()
        try await chunkStream.initialize()

        var chunkedCompressed = Data()
        let chunkSize = 5

        for i in stride(from: 0, to: original.count, by: chunkSize) {
            let end = min(i + chunkSize, original.count)
            let chunk = original.subdata(in: i ..< end)
            let flush: FlushMode = (end == original.count) ? .finish : .noFlush
            let compressedChunk = try await chunkStream.process(chunk, flush: flush)
            chunkedCompressed.append(compressedChunk)
        }

        XCTAssertNotEqual(chunkedCompressed.count, 0)

        // Decompress the chunked result
        let chunkDecompressStream = ZLib.asyncStream()
            .decompress()
            .format(.gzip)
            .build()

        try await chunkDecompressStream.initialize()
        let chunkDecompressed = try await chunkDecompressStream.process(chunkedCompressed)
        XCTAssertEqual(chunkDecompressed, original)

        // Test 9: Stream info
        let info = try await asyncStream.getStreamInfo()
        XCTAssertGreaterThan(info.totalIn, 0)
        XCTAssertGreaterThan(info.totalOut, 0)
        XCTAssertTrue(info.isActive)

        // Test 10: Reset functionality
        try await asyncStream.reset()
        try await asyncStream.initialize()
        let resetCompressed = try await asyncStream.process(original, flush: FlushMode.finish)
        XCTAssertNotEqual(resetCompressed.count, 0)
    }
}
