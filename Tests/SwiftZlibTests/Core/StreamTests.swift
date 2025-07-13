import XCTest
@testable import SwiftZlib

final class StreamTests: XCTestCase {
    func testStreamCompression() throws {
        let originalString = "Stream compression test with multiple chunks. " +
            "This should be processed in chunks to test the streaming functionality. " +
            "Stream compression test with multiple chunks. " +
            "This should be processed in chunks to test the streaming functionality."
        let originalData = originalString.data(using: .utf8)!

        print("=== Starting stream compression test ===")

        let compressor = Compressor()
        try compressor.initialize(level: .bestCompression)

        // Split data into chunks
        let chunkSize = 50
        var compressedData = Data()

        for i in stride(from: 0, to: originalData.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, originalData.count)
            let chunk = originalData[i ..< endIndex]
            print("Processing chunk \(i / chunkSize + 1): \(chunk.count) bytes")
            let compressedChunk = try compressor.compress(chunk)
            compressedData.append(compressedChunk)
        }

        // Finish compression
        let finalChunk = try compressor.finish()
        compressedData.append(finalChunk)

        // Decompress
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)

        print("=== Completed stream compression test ===")
    }

    func testStreamDecompression() throws {
        let originalString = "Stream decompression test with multiple chunks. " +
            "This should be processed in chunks to test the streaming functionality. " +
            "Stream decompression test with multiple chunks. " +
            "This should be processed in chunks to test the streaming functionality."
        let originalData = originalString.data(using: .utf8)!

        // First compress the data
        let compressedData = try ZLib.compress(originalData)

        let decompressor = Decompressor()
        try decompressor.initialize()

        // Split compressed data into chunks
        let chunkSize = 20
        var decompressedData = Data()

        for i in stride(from: 0, to: compressedData.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, compressedData.count)
            let chunk = compressedData[i ..< endIndex]
            let decompressedChunk = try decompressor.decompress(chunk)
            decompressedData.append(decompressedChunk)
        }

        // Finish decompression
        let finalChunk = try decompressor.finish()
        decompressedData.append(finalChunk)

        XCTAssertEqual(decompressedData, originalData)
    }

    func testLargeDataCompression() throws {
        // Create a larger dataset
        var largeString = ""
        for i in 1 ... 1000 {
            largeString += "This is line \(i) of a large dataset for compression testing. "
        }
        let originalData = largeString.data(using: .utf8)!

        let compressedData = try ZLib.compress(originalData, level: .bestCompression)
        let decompressedData = try ZLib.decompress(compressedData)

        XCTAssertEqual(decompressedData, originalData)
        XCTAssertLessThan(compressedData.count, originalData.count)
    }

    static var allTests = [
        ("testStreamCompression", testStreamCompression),
        ("testStreamDecompression", testStreamDecompression),
        ("testLargeDataCompression", testLargeDataCompression),
    ]
} 