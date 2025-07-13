//
//  StreamingConfig.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

/// Configuration for memory-efficient streaming operations
public struct StreamingConfig {
    // MARK: Properties

    /// Buffer size for reading/writing chunks
    public let bufferSize: Int
    /// Whether to use temporary files for intermediate results
    public let useTempFiles: Bool
    /// Compression level for streaming operations
    public let compressionLevel: Int
    /// Window bits for streaming operations
    public let windowBits: Int

    // MARK: Lifecycle

    public init(
        bufferSize: Int = 64 * 1024, // 64KB default
        useTempFiles: Bool = false,
        compressionLevel: Int = 6,
        windowBits: Int = 15
    ) {
        self.bufferSize = bufferSize
        self.useTempFiles = useTempFiles
        self.compressionLevel = compressionLevel
        self.windowBits = windowBits
    }
}
