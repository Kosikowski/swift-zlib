//
//  FileChunkedDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import CZLib
import Foundation

/// File-based chunked decompressor for huge files (constant memory)
final internal class FileChunkedDecompressor {
    // MARK: Properties

    public let bufferSize: Int
    public let windowBits: WindowBits

    // MARK: Lifecycle

    public init(bufferSize: Int = 64 * 1024, windowBits: WindowBits = .deflate) {
        self.bufferSize = bufferSize
        self.windowBits = windowBits
    }

    // MARK: Functions

    /// Decompress a file to another file using true streaming (constant memory)
    public func decompressFile(from sourcePath: String, to destinationPath: String) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }
        try wrapFileError {
            FileManager.default.createFile(atPath: destinationPath, contents: nil)
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            if !decompressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: decompressed) }
            }
            if isLast { isFinished = true }
        }
    }

    /// Decompress a file to another file using true streaming with progress tracking
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let input = try wrapFileError { try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath)) }
        defer { try? input.close() }
        try wrapFileError {
            FileManager.default.createFile(atPath: destinationPath, contents: nil)
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

        var processedBytes = 0
        let totalBytes = try input.seekToEnd()
        try input.seek(toOffset: 0)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            if !decompressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: decompressed) }
            }

            processedBytes += chunk.count
            progress(processedBytes, Int(totalBytes))

            if isLast { isFinished = true }
        }
    }

    /// Async version: Decompress a file to another file using true streaming (constant memory)
    public func decompressFile(from sourcePath: String, to destinationPath: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try decompressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                // The synchronous method already wraps errors in ZLibError, so we can pass through
                continuation.resume(throwing: error)
            }
        }
    }

    /// Async version: Decompress a file to another file using true streaming with progress tracking
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
                // The synchronous method already wraps errors in ZLibError, so we can pass through
                continuation.resume(throwing: error)
            }
        }
    }

    /// Advanced decompressFile with progress, throttling, cancellation, Foundation.Progress, and queue
    public func decompressFile(
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
            FileManager.default.createFile(atPath: destinationPath, contents: nil)
        }
        let output = try wrapFileError { try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath)) }
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

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
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            phase = .writing
            if !decompressed.isEmpty {
                try wrapFileError { try output.write(contentsOf: decompressed) }
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

    /// AsyncStream version: Decompress a file to another file, yielding ProgressInfo updates
    public func decompressFileProgressStream(
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
                    FileManager.default.createFile(atPath: destinationPath, contents: nil)
                    let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
                    defer { try? output.close() }

                    let decompressor = Decompressor()
                    try decompressor.initializeAdvanced(windowBits: windowBits)

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
                        let decompressed = try decompressor.decompress(chunk, flush: flush)
                        phase = .writing
                        if !decompressed.isEmpty {
                            try output.write(contentsOf: decompressed)
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
