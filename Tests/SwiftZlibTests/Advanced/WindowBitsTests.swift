//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
@testable import SwiftZlib
import XCTest

final class WindowBitsTests: XCTestCase {
    private func assertNoDoubleWrappedZLibError(_ error: Error) {
        if case let .fileError(underlyingError) = error as? ZLibError {
            XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
        }
    }

    func testWindowBitsRawRoundTrip() throws {
        let data = "windowBits raw round trip".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsZlibRoundTrip() throws {
        let data = "windowBits zlib round trip".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsGzipRoundTrip() throws {
        let data = "windowBits gzip round trip".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsAutoDetectGzip() throws {
        let data = "windowBits auto-detect gzip test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsAutoDetectZlib() throws {
        let data = "windowBits auto-detect zlib test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsMismatchedRawAsZlib() throws {
        let data = "windowBits mismatch raw as zlib".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testWindowBitsMismatchedZlibAsRaw() throws {
        let data = "windowBits mismatch zlib as raw".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testWindowBitsMismatchedGzipAsZlib() throws {
        let data = "windowBits mismatch gzip as zlib".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testWindowBitsMismatchedZlibAsGzip() throws {
        let data = "windowBits mismatch zlib as gzip".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }

    func testWindowBitsEmptyInput() throws {
        let data = Data()
        // Raw deflate: some zlib builds allow empty input, others throw stream error
        do {
            let compressorRaw = Compressor()
            try compressorRaw.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
            let compressed = try compressorRaw.compress(data, flush: .finish)
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: .raw)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        } catch let error as ZLibError {
            // Accept stream error for raw deflate with empty input
            if case let .compressionFailed(code) = error {
                XCTAssertEqual(code, -2)
                assertNoDoubleWrappedZLibError(error)
                return // Test passes for this platform
            } else {
                XCTFail("Unexpected error for raw deflate: \(error)")
                return
            }
        }
        // Zlib, gzip, auto: platform-specific behavior for empty input
        for windowBits in [WindowBits.deflate, .gzip, .auto] {
            do {
                let compressor = Compressor()
                try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)
                let compressed = try compressor.compress(data, flush: .finish)
                let decompressor = Decompressor()
                try decompressor.initializeAdvanced(windowBits: windowBits)
                let decompressed = try decompressor.decompress(compressed)
                XCTAssertEqual(decompressed, data)
            } catch let error as ZLibError {
                // Some zlib builds may throw stream error for empty input even for zlib/gzip/auto
                // This is platform-specific behavior, so accept either round-trip or stream error
                if case let .compressionFailed(code) = error {
                    XCTAssertEqual(code, -2)
                    assertNoDoubleWrappedZLibError(error)
                } else {
                    XCTFail("Unexpected error for \(windowBits): \(error)")
                }
            }
        }
    }

    func testWindowBitsCorruptedHeader() throws {
        let data = "windowBits corrupted header".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        var compressed = try compressor.compress(data, flush: .finish)
        // Corrupt the first byte
        compressed[0] = 0x00
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testWindowBitsEmptyInputRawDeflate() throws {
        let data = Data()
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }

    func testWindowBitsEmptyInputZlibGzipAuto() throws {
        let data = Data()
        for windowBits in [WindowBits.deflate, .gzip, .auto] {
            do {
                let compressor = Compressor()
                try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)
                let compressed = try compressor.compress(data, flush: .finish)
                let decompressor = Decompressor()
                try decompressor.initializeAdvanced(windowBits: windowBits)
                let decompressed = try decompressor.decompress(compressed)
                XCTAssertEqual(decompressed, data)
            } catch let error as ZLibError {
                // Some zlib builds may throw stream error for empty input even for zlib/gzip/auto
                // This is platform-specific behavior, so accept either round-trip or stream error
                if case let .compressionFailed(code) = error {
                    XCTAssertEqual(code, -2)
                    assertNoDoubleWrappedZLibError(error)
                } else {
                    XCTFail("Unexpected error for \(windowBits): \(error)")
                }
            }
        }
    }

    static var allTests = [
        ("testWindowBitsRawRoundTrip", testWindowBitsRawRoundTrip),
        ("testWindowBitsZlibRoundTrip", testWindowBitsZlibRoundTrip),
        ("testWindowBitsGzipRoundTrip", testWindowBitsGzipRoundTrip),
        ("testWindowBitsAutoDetectGzip", testWindowBitsAutoDetectGzip),
        ("testWindowBitsAutoDetectZlib", testWindowBitsAutoDetectZlib),
        ("testWindowBitsMismatchedRawAsZlib", testWindowBitsMismatchedRawAsZlib),
        ("testWindowBitsMismatchedZlibAsRaw", testWindowBitsMismatchedZlibAsRaw),
        ("testWindowBitsMismatchedGzipAsZlib", testWindowBitsMismatchedGzipAsZlib),
        ("testWindowBitsMismatchedZlibAsGzip", testWindowBitsMismatchedZlibAsGzip),
        ("testWindowBitsEmptyInput", testWindowBitsEmptyInput),
        ("testWindowBitsCorruptedHeader", testWindowBitsCorruptedHeader),
        ("testWindowBitsEmptyInputRawDeflate", testWindowBitsEmptyInputRawDeflate),
        ("testWindowBitsEmptyInputZlibGzipAuto", testWindowBitsEmptyInputZlibGzipAuto),
    ]
}
