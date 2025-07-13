//
//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

// MARK: - CompressionOptions

/// Compression configuration options
public struct CompressionOptions: Sendable {
    // MARK: Properties

    /// Compression format (zlib, gzip, or raw deflate)
    public var format: CompressionFormat
    /// Compression level
    public var level: CompressionLevel
    /// Compression strategy
    public var strategy: CompressionStrategy
    /// Memory level for compression
    public var memoryLevel: MemoryLevel
    /// Dictionary for compression (optional)
    public var dictionary: Data?
    /// Gzip header information (optional, only used with gzip format)
    public var gzipHeader: GzipHeader?

    // MARK: Lifecycle

    /// Initialize compression options
    /// - Parameters:
    ///   - format: Compression format
    ///   - level: Compression level
    ///   - strategy: Compression strategy
    ///   - memoryLevel: Memory level
    ///   - dictionary: Dictionary for compression
    ///   - gzipHeader: Gzip header information
    public init(
        format: CompressionFormat = .zlib,
        level: CompressionLevel = .defaultCompression,
        strategy: CompressionStrategy = .defaultStrategy,
        memoryLevel: MemoryLevel = .maximum,
        dictionary: Data? = nil,
        gzipHeader: GzipHeader? = nil
    ) {
        self.format = format
        self.level = level
        self.strategy = strategy
        self.memoryLevel = memoryLevel
        self.dictionary = dictionary
        self.gzipHeader = gzipHeader
    }
}

// MARK: - DecompressionOptions

/// Decompression configuration options
public struct DecompressionOptions: Sendable {
    // MARK: Properties

    /// Decompression format (zlib, gzip, raw deflate, or auto-detect)
    public var format: CompressionFormat
    /// Dictionary for decompression (optional)
    public var dictionary: Data?
    /// Whether to auto-detect format (only used when format is .auto)
    public var autoDetect: Bool

    // MARK: Lifecycle

    /// Initialize decompression options
    /// - Parameters:
    ///   - format: Decompression format
    ///   - dictionary: Dictionary for decompression
    ///   - autoDetect: Whether to auto-detect format
    public init(
        format: CompressionFormat = .auto,
        dictionary: Data? = nil,
        autoDetect: Bool = true
    ) {
        self.format = format
        self.dictionary = dictionary
        self.autoDetect = autoDetect
    }
}

// MARK: - CompressionFormat

/// Compression format enum for better API
public enum CompressionFormat: Sendable {
    /// ZLib format (default)
    case zlib
    /// Gzip format
    case gzip
    /// Raw deflate format (no header/trailer)
    case raw
    /// Auto-detect format
    case auto

    // MARK: Computed Properties

    /// The corresponding window bits for this format
    var windowBits: WindowBits {
        switch self {
            case .zlib: .deflate
            case .gzip: .gzip
            case .raw: .raw
            case .auto: .auto
        }
    }
}
