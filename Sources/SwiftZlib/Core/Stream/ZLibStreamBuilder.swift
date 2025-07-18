//
//  ZLibStreamBuilder.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

// MARK: - Stream Builder Pattern

/// Builder for creating ZLib streams with fluent API
public final class ZLibStreamBuilder {
    // MARK: Properties

    private var mode: ZLibStream.StreamMode = .compress
    private var options = ZLibStream.StreamOptions()

    // MARK: Functions

    /// Set stream mode to compression
    /// - Returns: Self for chaining
    public func compress() -> ZLibStreamBuilder {
        mode = .compress
        return self
    }

    /// Set stream mode to decompression
    /// - Returns: Self for chaining
    public func decompress() -> ZLibStreamBuilder {
        mode = .decompress
        return self
    }

    /// Set compression format
    /// - Parameter format: Compression format
    /// - Returns: Self for chaining
    public func format(_ format: CompressionFormat) -> ZLibStreamBuilder {
        options.compression.format = format
        options.decompression.format = format
        return self
    }

    /// Set compression level
    /// - Parameter level: Compression level
    /// - Returns: Self for chaining
    public func level(_ level: CompressionLevel) -> ZLibStreamBuilder {
        options.compression.level = level
        return self
    }

    /// Set buffer size
    /// - Parameter size: Buffer size in bytes
    /// - Returns: Self for chaining
    public func bufferSize(_ size: Int) -> ZLibStreamBuilder {
        options.bufferSize = size
        return self
    }

    /// Set dictionary for compression/decompression
    /// - Parameter dictionary: Dictionary data
    /// - Returns: Self for chaining
    public func dictionary(_ dictionary: Data) -> ZLibStreamBuilder {
        options.compression.dictionary = dictionary
        options.decompression.dictionary = dictionary
        return self
    }

    /// Build the stream
    /// - Returns: Configured ZLibStream
    public func build() -> ZLibStream {
        ZLibStream(mode: mode, options: options)
    }
}
