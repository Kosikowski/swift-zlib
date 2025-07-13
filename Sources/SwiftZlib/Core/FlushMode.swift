//
//  FlushMode.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Flush modes for ZLib stream operations
public enum FlushMode: Int32, Sendable {
    /// No flush (normal operation)
    case noFlush = 0
    /// Partial flush (flush pending output)
    case partialFlush = 1
    /// Sync flush (flush and align to byte boundary)
    case syncFlush = 2
    /// Full flush (flush and reset compression state)
    case fullFlush = 3
    /// Finish compression (finalize and flush)
    case finish = 4
    /// Block flush (flush current block)
    case block = 5
    /// Trees flush (flush Huffman trees)
    case trees = 6

    // MARK: Computed Properties

    /// The corresponding zlib flush mode
    public var zlibFlush: Int32 { rawValue }
}
