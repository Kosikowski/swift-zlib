//
//  SimpleFileDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Simple file decompressor using GzipFile for optimal performance (non-cancellable)
public final class SimpleFileDecompressor {
    // MARK: Properties

    public let bufferSize: Int

    // MARK: Lifecycle

    public init(bufferSize: Int = 64 * 1024) {
        self.bufferSize = bufferSize
    }

    // MARK: Functions

    /// Decompress a file to another file using GzipFile for optimal performance
    /// - Note: This operation cannot be cancelled
    public func decompressFile(from sourcePath: String, to destinationPath: String) throws {
        let gzipFile = try GzipFile(path: sourcePath, mode: "rb")
        defer { try? gzipFile.close() }

        // Create destination file first
        guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
            ])
        }

        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        var isFinished = false
        while !isFinished {
            let chunk = try gzipFile.readData(count: bufferSize)
            let isLast = chunk.count < bufferSize
            if !chunk.isEmpty {
                try wrapFileError { try output.write(contentsOf: chunk) }
            }
            if isLast { isFinished = true }
        }
    }

    /// Decompress a file to another file using GzipFile with progress tracking
    /// - Note: This operation cannot be cancelled
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let gzipFile = try GzipFile(path: sourcePath, mode: "rb")
        defer { try? gzipFile.close() }

        // Create destination file first
        guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
            ])
        }

        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        var processedBytes = 0
        var totalBytes = 0

        // Estimate total bytes by reading the entire file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: sourcePath)
        if let fileSize = fileAttributes[.size] as? Int {
            totalBytes = fileSize
        }

        var isFinished = false
        while !isFinished {
            let chunk = try gzipFile.readData(count: bufferSize)
            let isLast = chunk.count < bufferSize
            if !chunk.isEmpty {
                try wrapFileError { try output.write(contentsOf: chunk) }
            }

            processedBytes += chunk.count
            progress(processedBytes, totalBytes)

            if isLast { isFinished = true }
        }
    }

    /// Async version: Decompress a file to another file using GzipFile
    /// - Note: This operation cannot be cancelled
    public func decompressFile(from sourcePath: String, to destinationPath: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try decompressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Async version: Decompress a file to another file using GzipFile with progress tracking
    /// - Note: This operation cannot be cancelled
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try decompressFile(from: sourcePath, to: destinationPath, progress: progress)
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
