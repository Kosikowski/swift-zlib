//
//  FileDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

/// Memory-efficient file decompressor
final class FileDecompressor {
    // MARK: Properties

    private let config: StreamingConfig

    // MARK: Lifecycle

    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }

    // MARK: Functions

    /// Decompress a file to another file
    public func decompressFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        let decompressedData = try ZLib.decompress(sourceData)
        try decompressedData.write(to: URL(fileURLWithPath: destinationPath))
    }

    /// Decompress a file to memory (for small files)
    public func decompressFileToMemory(from sourcePath: String) throws -> Data {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        return try ZLib.decompress(fileData)
    }

    /// Decompress a file with progress callback
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        progress(sourceData.count, sourceData.count)

        let decompressedData = try ZLib.decompress(sourceData)
        try decompressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
}
