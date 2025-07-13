//
//  String+Extansions.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public extension String {
    /// Compress this string's UTF-8 data
    /// - Parameter level: Compression level
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    func compressed(level: CompressionLevel = .defaultCompression) throws -> Data {
        guard let data = data(using: .utf8) else {
            throw ZLibError.invalidData
        }
        return try data.compressed(level: level)
    }

    /// Decompress data and convert to string
    /// - Parameter data: Compressed data
    /// - Returns: Decompressed string
    /// - Throws: ZLibError if decompression fails
    static func decompressed(from data: Data) throws -> String {
        let decompressedData = try data.decompressed()
        guard let string = String(data: decompressedData, encoding: .utf8) else {
            throw ZLibError.invalidData
        }
        return string
    }

    /// Compress this string with gzip header
    /// - Parameters:
    ///   - level: Compression level
    ///   - header: Gzip header information
    /// - Returns: Compressed data with gzip header
    /// - Throws: ZLibError if compression fails
    func compressedWithGzipHeader(level: CompressionLevel = .defaultCompression, header: GzipHeader) throws -> Data {
        guard let data = data(using: .utf8) else {
            throw ZLibError.invalidData
        }
        return try data.compressedWithGzipHeader(level: level, header: header)
    }

    /// Calculate Adler-32 checksum
    /// - Parameter initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    func adler32(initialValue: uLong = 1) -> uLong? {
        return ZLib.adler32(self, initialValue: initialValue)
    }

    /// Calculate CRC-32 checksum
    /// - Parameter initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    func crc32(initialValue: uLong = 0) -> uLong? {
        return ZLib.crc32(self, initialValue: initialValue)
    }
}
