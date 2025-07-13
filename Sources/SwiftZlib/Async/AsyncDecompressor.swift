//
//  AsyncDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Async streaming decompressor for non-blocking decompression
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AsyncDecompressor: @unchecked Sendable {
    // MARK: Properties

    private let decompressor: Decompressor
    private let queue: DispatchQueue
    private let bufferSize: Int
    private let options: DecompressionOptions

    // MARK: Lifecycle

    /// Initialize async decompressor
    /// - Parameters:
    ///   - options: Decompression options
    ///   - bufferSize: Buffer size for processing
    ///   - queue: Dispatch queue for background processing
    public init(options: DecompressionOptions = DecompressionOptions(), bufferSize: Int = 4096, queue: DispatchQueue = .global(qos: .userInitiated)) {
        decompressor = Decompressor()
        self.bufferSize = bufferSize
        self.queue = queue
        self.options = options
    }

    // MARK: Functions

    /// Initialize the async decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let options = self.options
            queue.async {
                do {
                    try self.decompressor.initializeAdvanced(windowBits: options.format.windowBits)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Decompress data asynchronously
    /// - Parameter data: Compressed data chunk
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ data: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.decompressor.decompress(data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Reset the decompressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.decompressor.reset()
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
                    let result = try self.decompressor.getStreamInfo()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
