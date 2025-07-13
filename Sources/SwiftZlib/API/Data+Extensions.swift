//
//  Data+Extension.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import CZLib
import Foundation

public extension Data {
    /// Compress this data
    /// - Parameter level: Compression level
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    func compressed(level: CompressionLevel = .defaultCompression) throws -> Data {
        return try ZLib.compress(self, level: level)
    }

    /// Decompress this data
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    func decompressed() throws -> Data {
        return try ZLib.decompress(self)
    }

    /// Partially decompress this data
    /// - Parameter maxOutputSize: Maximum output buffer size
    /// - Returns: Tuple of (decompressed data, input consumed, output written)
    /// - Throws: ZLibError if decompression fails
    func partialDecompressed(maxOutputSize: Int = 4096) throws -> (decompressed: Data, inputConsumed: Int, outputWritten: Int) {
        return try ZLib.partialDecompress(self, maxOutputSize: maxOutputSize)
    }

    /// Compress this data with gzip header
    /// - Parameters:
    ///   - level: Compression level
    ///   - header: Gzip header information
    /// - Returns: Compressed data with gzip header
    /// - Throws: ZLibError if compression fails
    func compressedWithGzipHeader(level: CompressionLevel = .defaultCompression, header: GzipHeader) throws -> Data {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: level, windowBits: .gzip)
        try compressor.setGzipHeader(header)
        return try compressor.compress(self) + compressor.finish()
    }

    /// Calculate Adler-32 checksum
    /// - Parameter initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    func adler32(initialValue: uLong = 1) -> uLong {
        return ZLib.adler32(self, initialValue: initialValue)
    }

    /// Calculate CRC-32 checksum
    /// - Parameter initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    func crc32(initialValue: uLong = 0) -> uLong {
        return ZLib.crc32(self, initialValue: initialValue)
    }

    /// Estimate the compressed size for this data
    /// - Parameter level: Compression level
    /// - Returns: Estimated compressed size
    func estimateCompressedSize(level: CompressionLevel = .defaultCompression) -> Int {
        return ZLib.estimateCompressedSize(count, level: level)
    }

    /// Get recommended buffer sizes for streaming compression/decompression
    /// - Parameter windowBits: Window bits for the operation
    /// - Returns: Tuple of (input buffer size, output buffer size)
    static func getRecommendedBufferSizes(windowBits: WindowBits = .deflate) -> (input: Int, output: Int) {
        return ZLib.getRecommendedBufferSizes(windowBits: windowBits)
    }

    /// Estimate memory usage for compression
    /// - Parameters:
    ///   - windowBits: Window bits
    ///   - memoryLevel: Memory level
    /// - Returns: Estimated memory usage in bytes
    static func estimateMemoryUsage(windowBits: WindowBits = .deflate, memoryLevel: MemoryLevel = .maximum) -> Int {
        return ZLib.estimateMemoryUsage(windowBits: windowBits, memoryLevel: memoryLevel)
    }
}
