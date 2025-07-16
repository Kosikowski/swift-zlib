//
//  FileProcessor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
#if canImport(zlib)
    import zlib
#else
    import SwiftZlibCShims
#endif

// MARK: - FileProcessor

/// Memory-efficient unified file processor
final class FileProcessor {
    // MARK: Properties

    private let config: StreamingConfig

    // MARK: Lifecycle

    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }

    // MARK: Functions

    /// Process a file (compress or decompress based on file extension)
    public func processFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)

        // Auto-detect operation based on file extension
        if sourceURL.pathExtension.lowercased() == "gz" {
            // Decompress gzip file
            let decompressor = FileDecompressor(config: config)
            try decompressor.decompressFile(from: sourcePath, to: destinationPath)
        } else {
            // Compress to gzip file
            let compressor = FileCompressor(config: config)
            try compressor.compressFile(from: sourcePath, to: destinationPath)
        }
    }

    /// Process a file with progress callback
    public func processFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)

        // Auto-detect operation based on file extension
        if sourceURL.pathExtension.lowercased() == "gz" {
            // Decompress gzip file
            let decompressor = FileDecompressor(config: config)
            try decompressor.decompressFile(from: sourcePath, to: destinationPath, progress: progress)
        } else {
            // Compress to gzip file
            let compressor = FileCompressor(config: config)
            try compressor.compressFile(from: sourcePath, to: destinationPath, progress: progress)
        }
    }
}
