//
//  AsyncZLibStreamBuilder.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Builder for creating async ZLib streams with fluent API
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncZLibStreamBuilder: @unchecked Sendable {
    // MARK: Properties

    private var mode: ZLibStream.StreamMode = .compress
    private var options = ZLibStream.StreamOptions()

    // MARK: Functions

    /// Set stream mode to compression
    /// - Returns: Self for chaining
    public func compress() -> AsyncZLibStreamBuilder {
        mode = .compress
        return self
    }

    /// Set stream mode to decompression
    /// - Returns: Self for chaining
    public func decompress() -> AsyncZLibStreamBuilder {
        mode = .decompress
        return self
    }

    /// Set compression format
    /// - Parameter format: Compression format
    /// - Returns: Self for chaining
    public func format(_ format: CompressionFormat) -> AsyncZLibStreamBuilder {
        options.compression.format = format
        options.decompression.format = format
        return self
    }

    /// Set compression level
    /// - Parameter level: Compression level
    /// - Returns: Self for chaining
    public func level(_ level: CompressionLevel) -> AsyncZLibStreamBuilder {
        options.compression.level = level
        return self
    }

    /// Set buffer size
    /// - Parameter size: Buffer size in bytes
    /// - Returns: Self for chaining
    public func bufferSize(_ size: Int) -> AsyncZLibStreamBuilder {
        options.bufferSize = size
        return self
    }

    /// Set dictionary for compression/decompression
    /// - Parameter dictionary: Dictionary data
    /// - Returns: Self for chaining
    public func dictionary(_ dictionary: Data) -> AsyncZLibStreamBuilder {
        options.compression.dictionary = dictionary
        options.decompression.dictionary = dictionary
        return self
    }

    /// Build the async stream
    /// - Returns: Configured AsyncZLibStream
    public func build() -> AsyncZLibStream {
        AsyncZLibStream(mode: mode, options: options)
    }
}
