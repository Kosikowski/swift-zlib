//
//  WindowBits.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Window bits for ZLib format specification
public enum WindowBits: Int32, Sendable {
    /// ZLib format (default)
    case deflate = 15
    /// Gzip format
    case gzip = 31
    /// Raw deflate format (no header/trailer)
    case raw = -15
    /// Auto-detect format
    case auto = 47

    // MARK: Computed Properties

    /// The corresponding zlib window bits
    public var zlibWindowBits: Int32 { rawValue }
}
