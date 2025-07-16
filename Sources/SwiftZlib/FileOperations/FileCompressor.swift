//
//  FileCompressor.swift
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

// MARK: - FileCompressor

/// Memory-efficient file compressor
final class FileCompressor {
    // MARK: Properties

    private let config: StreamingConfig

    // MARK: Lifecycle

    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }

    // MARK: Functions

    /// Compress a file to another file
    public func compressFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        let compressedData = try ZLib.compress(sourceData)
        try compressedData.write(to: URL(fileURLWithPath: destinationPath))
    }

    /// Compress a file to memory (for small files)
    public func compressFileToMemory(from sourcePath: String) throws -> Data {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        return try ZLib.compress(fileData)
    }

    /// Compress a file with progress callback
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        progress(sourceData.count, sourceData.count)

        let compressedData = try ZLib.compress(sourceData)
        try compressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
}
