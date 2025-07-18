//
//  ZLib+File.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public extension ZLib {
    /// Memory-efficient file compression (synchronous)
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - config: Streaming configuration
    /// - Throws: ZLibError if compression fails
    /// - SeeAlso: compressFileAsync, compressFilePublisher
    static func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let compressor = FileCompressor(config: config)
        try compressor.compressFile(from: sourcePath, to: destinationPath)
    }

    /// Memory-efficient file decompression (synchronous)
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - config: Streaming configuration
    /// - Throws: ZLibError if decompression fails
    /// - SeeAlso: decompressFileAsync, decompressFilePublisher
    static func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let decompressor = FileDecompressor(config: config)
        try decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }

    /// Memory-efficient file processing (auto-detect)
    static func processFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let processor = FileProcessor(config: config)
        try processor.processFile(from: sourcePath, to: destinationPath)
    }

    // MARK: - Simple File Operations (GzipFile-based, non-cancellable)

    /// Simple file compression using GzipFile for optimal performance
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    ///   - compressionLevel: Compression level (default: .defaultCompression)
    /// - Throws: ZLibError if compression fails
    static func compressFileSimple(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression
    ) throws {
        let compressor = SimpleFileCompressor(bufferSize: bufferSize, compressionLevel: compressionLevel)
        try compressor.compressFile(from: sourcePath, to: destinationPath)
    }

    /// Simple file decompression using GzipFile for optimal performance
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    /// - Throws: ZLibError if decompression fails
    static func decompressFileSimple(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024
    ) throws {
        let decompressor = SimpleFileDecompressor(bufferSize: bufferSize)
        try decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }

    /// Simple file compression with progress tracking using GzipFile
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - progress: Progress callback
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    ///   - compressionLevel: Compression level (default: .defaultCompression)
    /// - Throws: ZLibError if compression fails
    static func compressFileSimple(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression
    ) throws {
        let compressor = SimpleFileCompressor(bufferSize: bufferSize, compressionLevel: compressionLevel)
        try compressor.compressFile(from: sourcePath, to: destinationPath, progress: progress)
    }

    /// Simple file decompression with progress tracking using GzipFile
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - progress: Progress callback
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    /// - Throws: ZLibError if decompression fails
    static func decompressFileSimple(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void,
        bufferSize: Int = 64 * 1024
    ) throws {
        let decompressor = SimpleFileDecompressor(bufferSize: bufferSize)
        try decompressor.decompressFile(from: sourcePath, to: destinationPath, progress: progress)
    }

    /// Async simple file compression using GzipFile
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    ///   - compressionLevel: Compression level (default: .defaultCompression)
    /// - Throws: ZLibError if compression fails
    static func compressFileSimpleAsync(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression
    ) async throws {
        let compressor = SimpleFileCompressor(bufferSize: bufferSize, compressionLevel: compressionLevel)
        try await compressor.compressFile(from: sourcePath, to: destinationPath)
    }

    /// Async simple file decompression using GzipFile
    /// - Note: This operation cannot be cancelled
    /// - Parameters:
    ///   - sourcePath: Path to input file
    ///   - destinationPath: Path to output file
    ///   - bufferSize: Buffer size for processing (default: 64KB)
    /// - Throws: ZLibError if decompression fails
    static func decompressFileSimpleAsync(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024
    ) async throws {
        let decompressor = SimpleFileDecompressor(bufferSize: bufferSize)
        try await decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }
}
