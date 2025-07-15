//
//  ZLib+FileChunked.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

public extension ZLib {
    /// True chunked streaming file compression (synchronous)
    /// - SeeAlso: compressFileAsync, compressFilePublisher, compressFileProgressPublisher
    static func compressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    ) throws {
        let compressor = FileChunkedCompressor(
            bufferSize: bufferSize,
            compressionLevel: compressionLevel,
            windowBits: windowBits
        )
        try compressor.compressFile(from: sourcePath, to: destinationPath)
    }

    /// True chunked streaming file decompression (synchronous)
    /// - SeeAlso: decompressFileAsync, decompressFilePublisher, decompressFileProgressPublisher
    static func decompressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    ) throws {
        let decompressor = FileChunkedDecompressor(
            bufferSize: bufferSize,
            windowBits: windowBits
        )
        try decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }

    /// Async true chunked streaming file compression
    /// - SeeAlso: compressFileChunked, compressFilePublisher, compressFileProgressPublisher
    static func compressFileAsync(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    ) async throws {
        let compressor = FileChunkedCompressor(
            bufferSize: bufferSize,
            compressionLevel: compressionLevel,
            windowBits: windowBits
        )
        try await compressor.compressFile(from: sourcePath, to: destinationPath)
    }

    /// Async true chunked streaming file decompression
    /// - SeeAlso: decompressFileChunked, decompressFilePublisher, decompressFileProgressPublisher
    static func decompressFileAsync(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    ) async throws {
        let decompressor = FileChunkedDecompressor(
            bufferSize: bufferSize,
            windowBits: windowBits
        )
        try await decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }
}
