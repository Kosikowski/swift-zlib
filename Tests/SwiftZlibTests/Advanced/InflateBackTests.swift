//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
@testable import SwiftZlib
import XCTest

final class InflateBackTests: XCTestCase {
    func testInflateBackDecompressor() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()

        let originalData = "Test data for InflateBack".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        var output = Data()

        try inflateBack.processWithCallbacks(
            inputProvider: {
                compressedData
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )

        XCTAssertEqual(output, originalData)
    }

    func testInflateBackWithChunks() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()

        let originalData = "Test data for InflateBack with chunks".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        var output = Data()
        var inputIndex = 0
        let chunkSize = 10

        try inflateBack.processWithCallbacks(
            inputProvider: {
                guard inputIndex < compressedData.count else { return nil }
                let endIndex = min(inputIndex + chunkSize, compressedData.count)
                let chunk = compressedData[inputIndex ..< endIndex]
                inputIndex = endIndex
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )

        // Compare the actual data content, not the Data objects
        let outputString = String(data: output, encoding: .utf8)
        let originalString = String(data: originalData, encoding: .utf8)
        XCTAssertNotNil(outputString)
        XCTAssertNotNil(originalString)
        XCTAssertEqual(outputString, originalString)
    }

    func testInflateBackStreamInfo() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()

        let info = try inflateBack.getStreamInfo()
        XCTAssertGreaterThanOrEqual(info.totalIn, 0)
        XCTAssertGreaterThanOrEqual(info.totalOut, 0)
        XCTAssertTrue(info.isActive)
    }

    func testStreamingDecompressor() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()

        let originalData = "Test data for streaming decompressor".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        let result = try streamingDecompressor.processData(compressedData)
        XCTAssertEqual(result, originalData)
    }

    func testStreamingDecompressorWithCallbacks() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()

        let originalData = "Test data for streaming decompressor with callbacks".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        var output = Data()
        var inputIndex = 0
        let chunkSize = 10

        try streamingDecompressor.processWithCallbacks(
            inputProvider: {
                guard inputIndex < compressedData.count else { return nil }
                let endIndex = min(inputIndex + chunkSize, compressedData.count)
                let chunk = compressedData[inputIndex ..< endIndex]
                inputIndex = endIndex
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )

        // Compare the actual data content, not the Data objects
        let outputString = String(data: output, encoding: .utf8)
        let originalString = String(data: originalData, encoding: .utf8)

        XCTAssertNotNil(outputString)
        XCTAssertNotNil(originalString)
        XCTAssertEqual(outputString, originalString)
    }

    func testStreamingDecompressorChunkHandling() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()

        let originalData = "Test data for chunk handling".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        var chunks: [Data] = []

        try streamingDecompressor.processDataInChunks(compressedData) { chunk in
            chunks.append(chunk)
            return true
        }

        let combined = chunks.reduce(Data(), +)
        XCTAssertEqual(combined, originalData)
    }

    static var allTests = [
        ("testInflateBackDecompressor", testInflateBackDecompressor),
        ("testInflateBackWithChunks", testInflateBackWithChunks),
        ("testInflateBackStreamInfo", testInflateBackStreamInfo),
        ("testStreamingDecompressor", testStreamingDecompressor),
        ("testStreamingDecompressorWithCallbacks", testStreamingDecompressorWithCallbacks),
        ("testStreamingDecompressorChunkHandling", testStreamingDecompressorChunkHandling),
    ]
}
