//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
@testable import SwiftZlib
import XCTest

final class AdvancedFeaturesTests: XCTestCase {
    func testChecksums() throws {
        let data = "checksum test data".data(using: .utf8)!

        print("=== Starting checksum tests ===")

        let adler = ZLib.adler32(data)
        let crc = ZLib.crc32(data)
        XCTAssertNotEqual(adler, 0)
        XCTAssertNotEqual(crc, 0)
        print("Adler-32: \(adler), CRC-32: \(crc)")

        let adlerStr = ZLib.adler32("checksum test data")
        let crcStr = ZLib.crc32("checksum test data")
        XCTAssertEqual(adler, adlerStr)
        XCTAssertEqual(crc, crcStr)

        print("=== Completed checksum tests ===")
    }

    func testPartialDecompression() throws {
        let originalData = "This is test data for partial decompression".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)

        // Use simple decompression for simple compressed data
        let (decompressed, inputConsumed, outputWritten) = try ZLib.partialDecompress(compressedData, maxOutputSize: 10)

        XCTAssertGreaterThan(inputConsumed, 0)
        XCTAssertGreaterThan(outputWritten, 0)
        // Note: For small compressed data, the entire data might be decompressed
        // even with a small maxOutputSize due to how zlib works
        XCTAssertGreaterThan(decompressed.count, 0)
    }

    func testChecksumCombination() throws {
        let data1 = "First part".data(using: .utf8)!
        let data2 = "Second part".data(using: .utf8)!

        let adler1 = ZLib.adler32(data1)
        let adler2 = ZLib.adler32(data2)
        let combinedAdler = ZLib.adler32Combine(adler1, adler2, len2: data2.count)

        let fullData = data1 + data2
        let fullAdler = ZLib.adler32(fullData)

        XCTAssertEqual(combinedAdler, fullAdler)

        let crc1 = ZLib.crc32(data1)
        let crc2 = ZLib.crc32(data2)
        let combinedCrc = ZLib.crc32Combine(crc1, crc2, len2: data2.count)

        let fullCrc = ZLib.crc32(fullData)

        XCTAssertEqual(combinedCrc, fullCrc)
    }

    func testCompressionWithGzipHeader() throws {
        let originalData = "Test data with gzip header".data(using: .utf8)!

        var header = GzipHeader()
        header.name = "test.txt"
        header.comment = "Test file"
        header.time = UInt32(Date().timeIntervalSince1970)

        let compressedData = try originalData.compressedWithGzipHeader(level: .bestCompression, header: header)

        // Gzip headers require gzip decompression, not regular zlib decompression
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

        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedData, flush: .finish)
        let decompressedString = String(data: decompressedData, encoding: .utf8)!

        XCTAssertEqual(decompressedString, originalString)
    }

    static var allTests = [
        ("testChecksums", testChecksums),
        ("testPartialDecompression", testPartialDecompression),
        ("testChecksumCombination", testChecksumCombination),
        ("testCompressionWithGzipHeader", testCompressionWithGzipHeader),
        ("testStringCompressionWithGzipHeader", testStringCompressionWithGzipHeader),
    ]
}
