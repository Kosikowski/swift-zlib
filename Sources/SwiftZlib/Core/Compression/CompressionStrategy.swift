//
//  CompressionStrategy.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Compression strategies for ZLib operations
public enum CompressionStrategy: Int32, Sendable {
    /// Default compression strategy (balanced)
    case defaultStrategy = 0
    /// Filtered strategy (for data with small random variations)
    case filtered = 1
    /// Huffman-only strategy (no string matching)
    case huffmanOnly = 2
    /// Run-length encoding strategy (for data with many repeated bytes)
    case rle = 3
    /// Fixed strategy (predefined Huffman codes)
    case fixed = 4

    // MARK: Computed Properties

    /// The corresponding zlib compression strategy
    public var zlibStrategy: Int32 { rawValue }
}
