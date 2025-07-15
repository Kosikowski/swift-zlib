//
//  FileChunkedCompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// File-based chunked compressor for huge files (constant memory)
final class FileChunkedCompressor {
    // MARK: Properties

    public let bufferSize: Int
    public let compressionLevel: CompressionLevel
    public let windowBits: WindowBits

    // MARK: Lifecycle

    public init(bufferSize: Int = 64 * 1024, compressionLevel: CompressionLevel = .defaultCompression, windowBits: WindowBits = .deflate) {
        self.bufferSize = bufferSize
        self.compressionLevel = compressionLevel
        self.windowBits = windowBits
    }

    // MARK: Functions

    /// Compress a file to another file using true streaming (constant memory)
    public func compressFile(from sourcePath: String, to destinationPath: String) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }

        try wrapFileError {
            guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
                ])
            }
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            if !compressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: compressed) }
            }
            if isLast { isFinished = true }
        }
    }

    /// Compress a file to another file using true streaming with progress tracking
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }
        try wrapFileError {
            guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
                ])
            }
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        var processedBytes = 0
        let totalBytes = try input.seekToEnd()
        try input.seek(toOffset: 0)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            if !compressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: compressed) }
            }

            processedBytes += chunk.count
            progress(processedBytes, Int(totalBytes))

            if isLast { isFinished = true }
        }
    }

    /// Async version: Compress a file to another file using true streaming (constant memory)
    public func compressFile(from sourcePath: String, to destinationPath: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try compressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                // The synchronous method already wraps errors in ZLibError, so we can pass through
                continuation.resume(throwing: error)
            }
        }
    }

    /// Async version: Compress a file to another file using true streaming with progress tracking
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
                // The synchronous method already wraps errors in ZLibError, so we can pass through
                continuation.resume(throwing: error)
            }
        }
    }

    /// Advanced compressFile with progress, throttling, cancellation, Foundation.Progress, and queue
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progressCallback: AdvancedProgressCallback? = nil,
        progressObject: Progress? = nil,
        progressInterval: TimeInterval = 0.1, // seconds
        progressQueue: DispatchQueue = .main
    ) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }
        try wrapFileError {
            guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
                ])
            }
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        let totalBytes = try Int(input.seekToEnd())
        try input.seek(toOffset: 0)
        var processedBytes = 0
        var lastReport = Date()
        let startTime = Date()
        var shouldContinue = true
        var phase: CompressionPhase = .reading

        func reportProgress(phase: CompressionPhase) {
            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
            let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
            let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
            let info = ProgressInfo(
                processedBytes: processedBytes,
                totalBytes: totalBytes,
                percentage: percentage,
                speedBytesPerSec: speed,
                etaSeconds: eta,
                phase: phase,
                timestamp: now
            )
            if let progressObject {
                progressObject.completedUnitCount = Int64(processedBytes)
            }
            if let cb = progressCallback {
                progressQueue.sync {
                    shouldContinue = cb(info)
                }
            }
        }

        var isFinished = false
        var firstIteration = true
        while !isFinished, shouldContinue {
            phase = .reading
            let now = Date()
            if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                reportProgress(phase: phase)
                lastReport = now
                firstIteration = false
            }
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            phase = .compressing
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            phase = .writing
            if !compressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: compressed) }
            }
            processedBytes += chunk.count
            if isLast {
                reportProgress(phase: phase)
            }
            if isLast { isFinished = true }
        }
        phase = .flushing
        reportProgress(phase: .finished)
        if let progressObject {
            progressObject.completedUnitCount = Int64(totalBytes)
        }
        if !shouldContinue {
            throw ZLibError.streamError(-999) // Cancelled
        }
    }

    /// AsyncStream version: Compress a file to another file, yielding ProgressInfo updates
    public func compressFileProgressStream(
        from sourcePath: String,
        to destinationPath: String,
        progressInterval: TimeInterval = 0.1,
        progressQueue _: DispatchQueue = .main
    )
        -> AsyncThrowingStream<ProgressInfo, Error>
    {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
                    defer { try? input.close() }
                    try wrapFileError {
                        guard FileManager.default.createFile(atPath: destinationPath, contents: nil) else {
                            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                                NSLocalizedDescriptionKey: "Failed to create destination file at \(destinationPath)",
                            ])
                        }
                    }
                    let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
                    defer { try? output.close() }

                    let compressor = Compressor()
                    try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

                    let totalBytes = try Int(input.seekToEnd())
                    try input.seek(toOffset: 0)
                    var processedBytes = 0
                    var lastReport = Date()
                    let startTime = Date()
                    let shouldContinue = true
                    var phase: CompressionPhase = .reading
                    var isFinished = false
                    var firstIteration = true

                    func reportProgress(phase: CompressionPhase) {
                        let now = Date()
                        let elapsed = now.timeIntervalSince(startTime)
                        let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
                        let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
                        let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
                        let info = ProgressInfo(
                            processedBytes: processedBytes,
                            totalBytes: totalBytes,
                            percentage: percentage,
                            speedBytesPerSec: speed,
                            etaSeconds: eta,
                            phase: phase,
                            timestamp: now
                        )
                        continuation.yield(info)
                    }

                    while !isFinished, shouldContinue {
                        phase = .reading
                        let now = Date()
                        if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                            reportProgress(phase: phase)
                            lastReport = now
                            firstIteration = false
                        }
                        let chunk = input.readData(ofLength: bufferSize)
                        let isLast = chunk.count < bufferSize
                        phase = .compressing
                        let flush: FlushMode = isLast ? .finish : .noFlush
                        let compressed = try compressor.compress(chunk, flush: flush)
                        phase = .writing
                        if !compressed.isEmpty {
                            try output.write(contentsOf: compressed)
                        }
                        processedBytes += chunk.count
                        if isLast {
                            reportProgress(phase: phase)
                        }
                        if isLast { isFinished = true }
                    }
                    phase = .flushing
                    reportProgress(phase: .finished)
                    continuation.finish()
                } catch {
                    let zlibError = (error is ZLibError) ? error : ZLibError.fileError(error)
                    continuation.finish(throwing: zlibError)
                }
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
