//
//  ZLib+Async.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Async compression and decompression support
public extension ZLib {
    /// Compress data asynchronously
    /// - Parameters:
    ///   - data: Input data to compress
    ///   - options: Compression options
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    static func compressAsync(_ data: Data, options: CompressionOptions = CompressionOptions()) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let result = try compress(data, options: options)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Decompress data asynchronously
    /// - Parameters:
    ///   - data: Compressed data to decompress
    ///   - options: Decompression options
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    static func decompressAsync(_ data: Data, options: DecompressionOptions = DecompressionOptions()) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let result = try decompress(data, options: options)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
