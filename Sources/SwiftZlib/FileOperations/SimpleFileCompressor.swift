//
//  SimpleFileCompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Simple file compressor using GzipFile for optimal performance (non-cancellable)
public final class SimpleFileCompressor {
    // MARK: Properties

    public let bufferSize: Int
    public let compressionLevel: CompressionLevel

    // MARK: Lifecycle

    public init(bufferSize: Int = 64 * 1024, compressionLevel: CompressionLevel = .defaultCompression) {
        self.bufferSize = bufferSize
        self.compressionLevel = compressionLevel
    }

    // MARK: Functions

    /// Compress a file to another file using GzipFile for optimal performance
    /// - Note: This operation cannot be cancelled
    public func compressFile(from sourcePath: String, to destinationPath: String) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }

        let gzipFile = try GzipFile(path: destinationPath, mode: "wb\(compressionLevel.zlibLevel)")
        defer { try? gzipFile.close() }

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            try gzipFile.writeData(chunk)
            if isLast { isFinished = true }
        }
    }

    /// Compress a file to another file using GzipFile with progress tracking
    /// - Note: This operation cannot be cancelled
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }

        let gzipFile = try GzipFile(path: destinationPath, mode: "wb\(compressionLevel.zlibLevel)")
        defer { try? gzipFile.close() }

        let totalBytes = try Int(input.seekToEnd())
        try input.seek(toOffset: 0)
        var processedBytes = 0

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            try gzipFile.writeData(chunk)

            processedBytes += chunk.count
            progress(processedBytes, totalBytes)

            if isLast { isFinished = true }
        }
    }

    /// Async version: Compress a file to another file using GzipFile
    /// - Note: This operation cannot be cancelled
    public func compressFile(from sourcePath: String, to destinationPath: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try compressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Async version: Compress a file to another file using GzipFile with progress tracking
    /// - Note: This operation cannot be cancelled
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try compressFile(from: sourcePath, to: destinationPath, progress: progress)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    @discardableResult
    private func wrapFileError<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            throw ZLibError.fileError(error)
        }
    }
}
