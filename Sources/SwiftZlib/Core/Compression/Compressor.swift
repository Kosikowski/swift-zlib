//
//  Compressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Stream-based compression for large data or streaming scenarios
public final class Compressor {
    // MARK: Properties

    private var stream = z_stream()
    private var isInitialized = false
    private var isFinished = false

    /// Gzip header memory management
    private var gzipHeaderStorage: GzipHeaderStorage?

    // MARK: Lifecycle

    public init() {
        // Zero the z_stream struct
        memset(&stream, 0, MemoryLayout<z_stream>.size)
    }

    deinit {
        // gzipHeaderStorage will be deallocated automatically
        if isInitialized {
            // Validate stream state before cleanup
            guard stream.state != nil else {
                zlibError("Invalid stream state during cleanup")
                return
            }
            swift_deflateEnd(&stream)
        }
    }

    // MARK: Functions

    /// Initialize the compressor with basic settings
    /// - Parameter level: Compression level
    /// - Throws: ZLibError if initialization fails
    public func initialize(level: CompressionLevel = .defaultCompression) throws {
        zlibInfo("Initializing compressor with level: \(level)")

        // Use the exact same parameters as compress2: level, Z_DEFLATED, 15 (zlib format), 8 (default memory), Z_DEFAULT_STRATEGY
        // compress2 uses zlib format by default, which means windowBits = 15
        let result = swift_deflateInit2(&stream, level.zlibLevel, Z_DEFLATED, 15, 8, Z_DEFAULT_STRATEGY)
        if result != Z_OK {
            zlibError("Compressor initialization failed with code: \(result) - \(String(cString: swift_zError(result)))")
            throw ZLibError.compressionFailed(result)
        }
        isInitialized = true
        zlibInfo("Compressor initialized successfully")
    }

    /// Initialize the compressor with advanced settings
    /// - Parameters:
    ///   - level: Compression level
    ///   - method: Compression method (default: .deflate)
    ///   - windowBits: Window bits for format (default: .deflate)
    ///   - memoryLevel: Memory level (default: .maximum)
    ///   - strategy: Compression strategy (default: .defaultStrategy)
    /// - Throws: ZLibError if initialization fails
    public func initializeAdvanced(
        level: CompressionLevel = .defaultCompression,
        method: CompressionMethod = .deflate,
        windowBits: WindowBits = .deflate,
        memoryLevel: MemoryLevel = .maximum,
        strategy: CompressionStrategy = .defaultStrategy
    ) throws {
        let result = swift_deflateInit2(
            &stream,
            level.zlibLevel,
            method.zlibMethod,
            windowBits.zlibWindowBits,
            memoryLevel.zlibMemoryLevel,
            strategy.zlibStrategy
        )
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        isInitialized = true
    }

    /// Change compression parameters mid-stream
    /// - Parameters:
    ///   - level: New compression level
    ///   - strategy: New compression strategy
    /// - Throws: ZLibError if parameter change fails
    public func setParameters(level: CompressionLevel, strategy: CompressionStrategy) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflateParams(&stream, level.zlibLevel, strategy.zlibStrategy)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Set compression dictionary
    /// - Parameter dictionary: Dictionary data
    /// - Throws: ZLibError if dictionary setting fails
    public func setDictionary(_ dictionary: Data) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = dictionary.withUnsafeBytes { dictPtr in
            swift_deflateSetDictionary(
                &stream,
                dictPtr.bindMemory(to: Bytef.self).baseAddress!,
                uInt(dictionary.count)
            )
        }
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Reset the compressor for reuse
    /// - Throws: ZLibError if reset fails, CancellationError if cancelled
    public func reset() throws {
        // Check for cancellation before starting work
        try Task.checkCancellation()

        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflateReset(&stream)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Reset the compressor with different window bits
    /// - Parameter windowBits: New window bits
    /// - Throws: ZLibError if reset fails
    public func resetWithWindowBits(_ windowBits: WindowBits) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflateReset2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Copy the compressor state to another compressor
    /// - Parameter destination: The destination compressor
    /// - Throws: ZLibError if copy fails
    public func copy(to destination: Compressor) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflateCopy(&destination.stream, &stream)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        destination.isInitialized = true
    }

    /// Prime the compressor with bits
    /// - Parameters:
    ///   - bits: Number of bits to prime
    ///   - value: Value to prime with
    /// - Throws: ZLibError if priming fails
    public func prime(bits: Int32, value: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflatePrime(&stream, bits, value)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Get pending output from the compressor
    /// - Returns: Tuple of (pending bytes, pending bits)
    /// - Throws: ZLibError if operation fails
    public func getPending() throws -> (pending: UInt32, bits: Int32) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var pending: UInt32 = 0
        var bits: Int32 = 0

        let result = swift_deflatePending(&stream, &pending, &bits)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }

        return (pending, bits)
    }

    /// Get the upper bound on compressed size for given source length
    /// - Parameter sourceLen: Length of source data
    /// - Returns: Upper bound on compressed size
    /// - Throws: ZLibError if operation fails
    public func getBound(sourceLen: uLong) throws -> uLong {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let bound = swift_deflateBound(&stream, sourceLen)
        // deflateBound returns a uLong, so we just need to check if it's reasonable
        return bound
    }

    /// Fine-tune deflate parameters
    /// - Parameters:
    ///   - goodLength: Good match length
    ///   - maxLazy: Maximum lazy match length
    ///   - niceLength: Nice match length
    ///   - maxChain: Maximum chain length
    /// - Throws: ZLibError if tuning fails
    public func tune(goodLength: Int32, maxLazy: Int32, niceLength: Int32, maxChain: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_deflateTune(&stream, goodLength, maxLazy, niceLength, maxChain)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }

    /// Get the current dictionary
    /// - Returns: Dictionary data
    /// - Throws: ZLibError if operation fails
    public func getDictionary() throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var dictLength: uInt = 0
        let result = swift_deflateGetDictionary(&stream, nil, &dictLength)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }

        guard dictLength > 0 else {
            return Data()
        }

        var dictionary = Data(count: Int(dictLength))
        let getResult = dictionary.withUnsafeMutableBytes { dictPtr in
            swift_deflateGetDictionary(&stream, dictPtr.bindMemory(to: Bytef.self).baseAddress!, &dictLength)
        }

        guard getResult == Z_OK else {
            throw ZLibError.compressionFailed(getResult)
        }

        dictionary.count = Int(dictLength)
        return dictionary
    }

    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let totalIn = stream.total_in
        let totalOut = stream.total_out
        let isActive = isInitialized

        return (totalIn, totalOut, isActive)
    }

    /// Get compression ratio (if data has been processed)
    /// - Returns: Compression ratio (0.0 to 1.0, where 1.0 = no compression)
    /// - Throws: ZLibError if operation fails
    public func getCompressionRatio() throws -> Double {
        let info = try getStreamInfo()
        guard info.totalIn > 0 else { return 1.0 }
        return Double(info.totalOut) / Double(info.totalIn)
    }

    /// Get stream statistics
    /// - Returns: Stream statistics
    /// - Throws: ZLibError if operation fails
    public func getStreamStats() throws -> (bytesProcessed: Int, bytesProduced: Int, compressionRatio: Double, isActive: Bool) {
        let info = try getStreamInfo()
        let bytesProcessed = Int(info.totalIn)
        let bytesProduced = Int(info.totalOut)
        let compressionRatio = bytesProcessed > 0 ? Double(bytesProduced) / Double(bytesProcessed) : 1.0

        return (bytesProcessed, bytesProduced, compressionRatio, info.isActive)
    }

    /// Compress data in chunks
    /// - Parameters:
    ///   - input: Input data chunk
    ///   - flush: Flush mode
    /// - Returns: Compressed data chunk
    /// - Throws: ZLibError if compression fails, CancellationError if cancelled
    public func compress(_ input: Data, flush: FlushMode = .noFlush) throws -> Data {
        // Check for cancellation before starting work
        try Task.checkCancellation()

        guard isInitialized else {
            zlibError("Compressor not initialized")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        zlibDebug("Compressing \(input.count) bytes with flush mode: \(flush)")
        // Log input data (hex, truncated)
        let inputHex = input.prefix(32).map { String(format: "%02x", $0) }.joined()
        zlibDebug("Input (hex, first 32 bytes): \(inputHex)\(input.count > 32 ? "..." : "")")
        logStreamState(stream, operation: "Compression start")

        var output = Data()
        let outputBufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: outputBufferSize)

        // Copy input data to ensure it remains valid throughout compression
        let inputBuffer = [Bytef](input)

        // Keep inputBuffer alive for the entire compression loop
        try inputBuffer.withUnsafeBufferPointer { ptr in
            stream.next_in = ptr.baseAddress.map { UnsafeMutablePointer(mutating: $0) }
            stream.avail_in = uInt(input.count)

            // Process all input data
            var result: Int32 = Z_OK
            var iteration = 0
            var totalProduced = 0
            repeat {
                // Check for cancellation before each iteration
                try Task.checkCancellation()

                iteration += 1
                if ZLibVerboseConfig.logProgress {
                    zlibDebug("Compression iteration \(iteration): avail_in=\(stream.avail_in), avail_out=\(stream.avail_out)")
                }

                var bytesProcessed = 0
                try outputBuffer.withUnsafeMutableBufferPointer { buffer in
                    stream.next_out = buffer.baseAddress
                    stream.avail_out = uInt(outputBufferSize)

                    // Log input buffer state before calling swift_deflate
                    let inPtr = stream.next_in
                    let inAddr = UInt(bitPattern: inPtr)
                    let inAvail = stream.avail_in
                    let inPreview: String = {
                        guard let inPtr else { return "nil" }
                        let buf = UnsafeBufferPointer(start: inPtr, count: min(Int(inAvail), 8))
                        return buf.map { String(format: "%02x", $0) }.joined(separator: " ")
                    }()
                    zlibDebug("[Compressor] Before deflate: next_in=0x\(String(inAddr, radix: 16)), avail_in=\(inAvail), preview=\(inPreview)")

                    result = swift_deflate(&stream, flush.zlibFlush)
                    if result == Z_STREAM_ERROR {
                        zlibError("Compression failed with Z_STREAM_ERROR")
                        throw ZLibError.streamError(result)
                    }

                    bytesProcessed = outputBufferSize - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let chunk = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                        output.append(chunk)
                        totalProduced += bytesProcessed
                        let chunkHex = chunk.prefix(32).map { String(format: "%02x", $0) }.joined()
                        zlibDebug("Output chunk (hex, first 32 bytes): \(chunkHex)\(chunk.count > 32 ? "..." : "")")
                        zlibDebug("Produced \(bytesProcessed) bytes of compressed data (total: \(totalProduced))")
                    }
                }
                logStreamState(stream, operation: "Compression iteration \(iteration) end")
            } while flush == .finish ? result != Z_STREAM_END : (stream.avail_in > 0 || stream.avail_out == 0) // Continue until finish or while input/output remains
        }

        logStreamState(stream, operation: "Compression end")
        zlibInfo("Compression completed: \(input.count) -> \(output.count) bytes")
        // Log final output (hex, truncated)
        let outputHex = output.prefix(32).map { String(format: "%02x", $0) }.joined()
        zlibDebug("Final output (hex, first 32 bytes): \(outputHex)\(output.count > 32 ? "..." : "")")

        return output
    }

    /// Finish compression
    /// - Returns: Final compressed data
    /// - Throws: ZLibError if compression fails, CancellationError if cancelled
    public func finish() throws -> Data {
        // Check for cancellation before starting work
        try Task.checkCancellation()

        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var output = Data()
        let outputBufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: outputBufferSize)

        // Set empty input for finish
        stream.next_in = nil
        stream.avail_in = 0

        // Process until stream is finished
        var result: Int32 = Z_OK
        repeat {
            // Check for cancellation before each iteration
            try Task.checkCancellation()

            var bytesProcessed = 0
            try outputBuffer.withUnsafeMutableBufferPointer { buffer in
                stream.next_out = buffer.baseAddress
                stream.avail_out = uInt(outputBufferSize)

                result = swift_deflate(&stream, FlushMode.finish.zlibFlush)
                guard result != Z_STREAM_ERROR else {
                    throw ZLibError.streamError(result)
                }

                bytesProcessed = outputBufferSize - Int(stream.avail_out)
                if bytesProcessed > 0 {
                    // Fix: Copy the data within the closure scope where the pointer is valid
                    output.append(Data(bytes: buffer.baseAddress!, count: bytesProcessed))
                }
            }
        } while stream.avail_out == 0 && result != Z_STREAM_END // Continue until stream ends

        return output
    }

    /// Set the gzip header for the stream (must be called after initializeAdvanced)
    public func setGzipHeader(_ header: GzipHeader) throws {
        guard gzipHeaderStorage == nil else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        let storage = GzipHeaderStorage(swiftHeader: header)
        let result = swift_deflateSetHeader(&stream, &storage.cHeader)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        gzipHeaderStorage = storage
    }
}
