//
//  ZLibStream.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

/// Unified streaming interface for compression and decompression
final class ZLibStream {
    // MARK: Nested Types

    /// Stream operation mode
    public enum StreamMode: Sendable {
        case compress
        case decompress
    }

    /// Stream configuration options
    public struct StreamOptions: Sendable {
        // MARK: Properties

        /// Compression options (used for compress mode)
        public var compression: CompressionOptions
        /// Decompression options (used for decompress mode)
        public var decompression: DecompressionOptions
        /// Buffer size for processing chunks
        public var bufferSize: Int

        // MARK: Lifecycle

        public init(
            compression: CompressionOptions = CompressionOptions(),
            decompression: DecompressionOptions = DecompressionOptions(),
            bufferSize: Int = 4096
        ) {
            self.compression = compression
            self.decompression = decompression
            self.bufferSize = bufferSize
        }
    }

    // MARK: Properties

    private var compressor: Compressor?
    private var decompressor: Decompressor?
    private let mode: StreamMode
    private let options: StreamOptions
    private var isInitialized = false
    private var isFinished = false

    // MARK: Lifecycle

    /// Initialize a new stream
    /// - Parameters:
    ///   - mode: Stream operation mode (compress or decompress)
    ///   - options: Stream configuration options
    public init(mode: StreamMode, options: StreamOptions = StreamOptions()) {
        self.mode = mode
        self.options = options
    }

    deinit {
        // Cleanup is handled by Compressor/Decompressor deinit
    }

    // MARK: Functions

    /// Initialize the stream for processing
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        guard !isInitialized else { return }

        switch mode {
            case .compress:
                compressor = Compressor()
                try compressor?.initializeAdvanced(
                    level: options.compression.level,
                    method: .deflate,
                    windowBits: options.compression.format.windowBits,
                    memoryLevel: options.compression.memoryLevel,
                    strategy: options.compression.strategy
                )

                if let dictionary = options.compression.dictionary {
                    try compressor?.setDictionary(dictionary)
                }

            case .decompress:
                decompressor = Decompressor()
                try decompressor?.initializeAdvanced(windowBits: options.decompression.format.windowBits)

                if let dictionary = options.decompression.dictionary {
                    try decompressor?.setDictionary(dictionary)
                }
        }

        isInitialized = true
    }

    /// Process a chunk of data
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode for compression (default: .noFlush)
    /// - Returns: Processed output data
    /// - Throws: ZLibError if processing fails
    public func process(_ data: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let compressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try compressor.compress(data, flush: flush)

            case .decompress:
                guard let decompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try decompressor.decompress(data)
        }
    }

    /// Finish processing and get final output
    /// - Returns: Final processed data
    /// - Throws: ZLibError if processing fails
    public func finalize() throws -> Data {
        guard isInitialized, !isFinished else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let compressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                let result = try compressor.compress(Data(), flush: .finish)
                isFinished = true
                return result

            case .decompress:
                guard let decompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                // For decompression, we need to process any remaining data
                let result = try decompressor.decompress(Data(), flush: .finish)
                isFinished = true
                return result
        }
    }

    /// Reset the stream for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() throws {
        switch mode {
            case .compress:
                try compressor?.reset()
            case .decompress:
                try decompressor?.reset()
        }
        isFinished = false
    }

    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let compressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try compressor.getStreamInfo()

            case .decompress:
                guard let decompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try decompressor.getStreamInfo()
        }
    }
}
