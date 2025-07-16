//
//  AsyncZLibStream.swift
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

// MARK: - AsyncZLibStream

/// Async unified streaming interface
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncZLibStream: @unchecked Sendable {
    // MARK: Properties

    private var asyncCompressor: AsyncCompressor?
    private var asyncDecompressor: AsyncDecompressor?
    private let mode: ZLibStream.StreamMode
    private let options: ZLibStream.StreamOptions
    private var isInitialized = false
    private var isFinished = false

    // MARK: Lifecycle

    /// Initialize async stream
    /// - Parameters:
    ///   - mode: Stream operation mode
    ///   - options: Stream configuration options
    public init(mode: ZLibStream.StreamMode, options: ZLibStream.StreamOptions = ZLibStream.StreamOptions()) {
        self.mode = mode
        self.options = options
    }

    // MARK: Functions

    /// Initialize the async stream
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        guard !isInitialized else { return }

        switch mode {
            case .compress:
                asyncCompressor = AsyncCompressor(options: options.compression, bufferSize: options.bufferSize)
                try await asyncCompressor?.initialize()

            case .decompress:
                asyncDecompressor = AsyncDecompressor(options: options.decompression, bufferSize: options.bufferSize)
                try await asyncDecompressor?.initialize()
        }

        isInitialized = true
    }

    /// Process data asynchronously
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode for compression
    /// - Returns: Processed output data
    /// - Throws: ZLibError if processing fails
    public func process(_ data: Data, flush: FlushMode = .noFlush) async throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let asyncCompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try await asyncCompressor.compress(data, flush: flush)

            case .decompress:
                guard let asyncDecompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try await asyncDecompressor.decompress(data)
        }
    }

    /// Finish processing asynchronously
    /// - Returns: Final processed data
    /// - Throws: ZLibError if processing fails
    public func finalize() async throws -> Data {
        guard isInitialized, !isFinished else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let asyncCompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                let result = try await asyncCompressor.finish()
                isFinished = true
                return result

            case .decompress:
                // For decompression, we just return empty data as finish
                isFinished = true
                return Data()
        }
    }

    /// Reset the async stream for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        switch mode {
            case .compress:
                try await asyncCompressor?.reset()
            case .decompress:
                try await asyncDecompressor?.reset()
        }
        isFinished = false
    }

    /// Get stream information asynchronously
    /// - Returns: Stream information
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() async throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        switch mode {
            case .compress:
                guard let asyncCompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try await asyncCompressor.getStreamInfo()

            case .decompress:
                guard let asyncDecompressor else {
                    throw ZLibError.streamError(Z_STREAM_ERROR)
                }
                return try await asyncDecompressor.getStreamInfo()
        }
    }
}
