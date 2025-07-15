//
//  AsyncCompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

/// Async streaming compressor for non-blocking compression
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncCompressor: @unchecked Sendable {
    // MARK: Properties

    private let compressor: Compressor
    private let queue: DispatchQueue
    private let bufferSize: Int
    private let options: CompressionOptions

    // MARK: Lifecycle

    /// Initialize async compressor
    /// - Parameters:
    ///   - options: Compression options
    ///   - bufferSize: Buffer size for processing
    ///   - queue: Dispatch queue for background processing
    public init(options: CompressionOptions = CompressionOptions(), bufferSize: Int = 4096, queue: DispatchQueue = .global(qos: .userInitiated)) {
        compressor = Compressor()
        self.bufferSize = bufferSize
        self.queue = queue
        self.options = options
    }

    // MARK: Functions

    /// Initialize the async compressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let options = self.options
            queue.async {
                do {
                    try self.compressor.initializeAdvanced(
                        level: options.level,
                        method: .deflate,
                        windowBits: options.format.windowBits,
                        memoryLevel: options.memoryLevel,
                        strategy: options.strategy
                    )
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Compress data asynchronously
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode
    /// - Returns: Compressed data chunk
    /// - Throws: ZLibError if compression fails
    public func compress(_ data: Data, flush: FlushMode = .noFlush) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let flushMode = flush
            queue.async {
                do {
                    let result = try self.compressor.compress(data, flush: flushMode)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Finish compression asynchronously
    /// - Returns: Final compressed data
    /// - Throws: ZLibError if compression fails
    public func finish() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.compressor.finish()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Reset the compressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.compressor.reset()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get stream information asynchronously
    /// - Returns: Stream information
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() async throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.compressor.getStreamInfo()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
