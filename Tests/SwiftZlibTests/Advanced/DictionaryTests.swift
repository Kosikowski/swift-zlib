//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class DictionaryTests: XCTestCase {
    // MARK: Static Properties

    // MARK: - Test Discovery

    static var allTests = [
        ("testDictionaryCompressionDecompression_Success", testDictionaryCompressionDecompression_Success),
        ("testDictionaryCompressionDecompression_WrongDictionary", testDictionaryCompressionDecompression_WrongDictionary),
        ("testDictionaryCompressionDecompression_MissingDictionary", testDictionaryCompressionDecompression_MissingDictionary),
        ("testDictionaryCompressionDecompression_RoundTripRetrieval", testDictionaryCompressionDecompression_RoundTripRetrieval),
        ("testDictionaryCompressionDecompression_EmptyDictionary", testDictionaryCompressionDecompression_EmptyDictionary),
        ("testDictionaryCompressionDecompression_LargeDictionary", testDictionaryCompressionDecompression_LargeDictionary),
        ("testDictionarySetAtWrongTime", testDictionarySetAtWrongTime),
    ]

    // MARK: Functions

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

    // MARK: - Dictionary Tests

    func testDictionaryCompressionDecompression_Success() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!

        // First, test basic compression without dictionary
        let compressor1 = Compressor()
        try compressor1.initialize(level: .defaultCompression)
        let compressed1 = try compressor1.compress(originalData, flush: .finish)

        // Decompress basic compression
        let decompressor1 = Decompressor()
        try decompressor1.initialize()
        let decompressed1 = try decompressor1.decompress(compressed1)
        XCTAssertEqual(decompressed1, originalData)

        // Now test compression with dictionary
        let compressor2 = Compressor()
        try compressor2.initialize(level: .defaultCompression)
        try compressor2.setDictionary(dictionary)
        let compressed2 = try compressor2.compress(originalData, flush: .finish)

        // Decompress with dictionary using new API
        let decompressor2 = Decompressor()
        try decompressor2.initialize()
        let decompressed2 = try decompressor2.decompress(compressed2, dictionary: dictionary)
        XCTAssertEqual(decompressed2, originalData)

        // Verify that dictionary compression produces different output
        XCTAssertNotEqual(compressed1, compressed2)
    }

    func testDictionaryCompressionDecompression_WrongDictionary() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let wrongDictionary = String(repeating: "zyxwvutsrqponmlk", count: 2).data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!

        // Compress with correct dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompress with wrong dictionary (should fail with Z_DATA_ERROR or Z_NEED_DICT)
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(compressed, dictionary: wrongDictionary))
    }

    func testDictionaryCompressionDecompression_MissingDictionary() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!

        // Compress with dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompress without dictionary (should fail with Z_NEED_DICT)
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(compressed))
    }

    func testDictionaryCompressionDecompression_RoundTripRetrieval() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!

        // Compress with dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)

        // Decompress and verify data integrity
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
        XCTAssertEqual(decompressed, originalData)
        // Optionally, check getDictionary (may be empty or not match original)
        let _ = try decompressor.getDictionary()
    }

    func testDictionaryCompressionDecompression_EmptyDictionary() throws {
        let dictionary = Data()
        let originalData = Data()
        // Compress with empty dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        // Decompress with empty dictionary
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
        XCTAssertEqual(decompressed, originalData)
    }

    func testDictionaryCompressionDecompression_LargeDictionary() throws {
        // Create a large dictionary with a specific pattern
        let dictPattern = "abcdefghijklmnopqrstuvwxyz0123456789"
        let dictString = String(repeating: dictPattern, count: 32768 / dictPattern.count + 1)
        let largeDictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression with large dictionary".data(using: .utf8)!
        // Compress with large dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(largeDictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        // Decompress with large dictionary
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: largeDictionary)
        XCTAssertEqual(decompressed, originalData)
    }

    func testDictionarySetAtWrongTime() throws {
        let dictionary = "test dictionary".data(using: .utf8)!
        // Try to set dictionary before initialization
        let compressor = Compressor()
        XCTAssertThrowsError(try compressor.setDictionary(dictionary)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
        // Try to set dictionary after compression
        try compressor.initialize(level: .noCompression)
        let data = "test data".data(using: .utf8)!
        _ = try compressor.compress(data, flush: .finish)
        // Dictionary should still be set after compression
        XCTAssertNoThrow(try compressor.setDictionary(dictionary))
    }
}
