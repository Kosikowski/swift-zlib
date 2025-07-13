//
//  CompressionMethod.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Compression methods supported by ZLib
public enum CompressionMethod: Int32 {
    /// Deflate compression method (standard)
    case deflate = 8

    // MARK: Computed Properties

    /// The corresponding zlib compression method
    public var zlibMethod: Int32 { rawValue }
}
