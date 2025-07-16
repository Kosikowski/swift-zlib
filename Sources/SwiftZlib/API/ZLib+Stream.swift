//
//  ZLib+Stream.swift
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

extension ZLib {
    /// Create a stream builder for fluent configuration
    /// - Returns: Stream builder
    static func stream() -> ZLibStreamBuilder {
        ZLibStreamBuilder()
    }

    /// Create a compression stream with default options
    /// - Returns: Configured compression stream
    static func compressionStream() -> ZLibStream {
        ZLibStream(mode: .compress)
    }

    /// Create a decompression stream with default options
    /// - Returns: Configured decompression stream
    static func decompressionStream() -> ZLibStream {
        ZLibStream(mode: .decompress)
    }
}
