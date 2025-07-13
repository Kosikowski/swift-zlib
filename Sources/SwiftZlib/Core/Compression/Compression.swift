//
//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Compression configuration options
public struct CompressionOptions: Sendable {
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

/// Decompression configuration options
public struct DecompressionOptions: Sendable {
    /// Decompression format (zlib, gzip, raw deflate, or auto-detect)
    public var format: CompressionFormat
    /// Dictionary for decompression (optional)
    public var dictionary: Data?
    /// Whether to auto-detect format (only used when format is .auto)
    public var autoDetect: Bool

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

/// Compression format enum for better API
public enum CompressionFormat: Sendable {
    case zlib
    case gzip
    case raw
    case auto

    var windowBits: WindowBits {
        switch self {
        case .zlib: return .deflate
        case .gzip: return .gzip
        case .raw: return .raw
        case .auto: return .auto
        }
    }
}
