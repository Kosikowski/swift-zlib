//
//  CompressionLevel.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Compression levels for ZLib operations
public enum CompressionLevel: Int32, Sendable {
    /// No compression (fastest, no size reduction)
    case noCompression = 0
    /// Best speed compression (fast, minimal size reduction)
    case bestSpeed = 1
    /// Best compression (slowest, maximum size reduction)
    case bestCompression = 9
    /// Default compression (balanced speed and size)
    case defaultCompression = -1

    // MARK: Computed Properties

    /// The corresponding zlib compression level
    public var zlibLevel: Int32 { rawValue }
}
