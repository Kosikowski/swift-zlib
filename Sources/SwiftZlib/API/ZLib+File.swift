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
}
