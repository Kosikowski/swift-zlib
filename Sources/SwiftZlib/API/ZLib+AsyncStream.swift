//
//  ZLib+AsyncStream.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public extension ZLib {
    /// Create an async stream builder for fluent configuration
    /// - Returns: Async stream builder
    static func asyncStream() -> AsyncZLibStreamBuilder {
        AsyncZLibStreamBuilder()
    }

    /// Create an async compression stream with default options
    /// - Returns: Configured async compression stream
    static func asyncCompressionStream() -> AsyncZLibStream {
        AsyncZLibStream(mode: .compress)
    }

    /// Create an async decompression stream with default options
    /// - Returns: Configured async decompression stream
    static func asyncDecompressionStream() -> AsyncZLibStream {
        AsyncZLibStream(mode: .decompress)
    }
}
