//
//  Decompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

// MARK: - Gzip File API

/// Stream-based decompression for large data or streaming scenarios
final class Decompressor {
    // MARK: Properties

    private var stream = z_stream()
    private var isInitialized = false

    // MARK: Lifecycle

    public init() {
        // Zero the z_stream struct
        memset(&stream, 0, MemoryLayout<z_stream>.size)
    }

    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }

    // MARK: Functions

    /// Initialize the decompressor with basic settings
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        zlibInfo("Initializing decompressor")

        let result = swift_inflateInit(&stream)
        if result != Z_OK {
            zlibError("Decompressor initialization failed with code: \(result) - \(String(cString: swift_zError(result)))")
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
        zlibInfo("Decompressor initialized successfully")
    }

    /// Initialize the decompressor with advanced settings
    /// - Parameter windowBits: Window bits for format (default: .deflate)
    /// - Throws: ZLibError if initialization fails
    public func initializeAdvanced(windowBits: WindowBits = .deflate) throws {
        let result = swift_inflateInit2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }

    /// Set decompression dictionary
    /// - Parameter dictionary: Dictionary data
    /// - Throws: ZLibError if dictionary setting fails
    public func setDictionary(_ dictionary: Data) throws {
        zlibDebug("[Decompressor.setDictionary] Called with dictionary of size: \(dictionary.count)")
        guard isInitialized else {
            zlibError("[Decompressor.setDictionary] Not initialized!")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = dictionary.withUnsafeBytes { dictPtr in
            swift_inflateSetDictionary(
                &stream,
                dictPtr.bindMemory(to: Bytef.self).baseAddress!,
                uInt(dictionary.count)
            )
        }
        zlibDebug("[Decompressor.setDictionary] swift_inflateSetDictionary returned: \(result)")
        guard result == Z_OK else {
            zlibError("[Decompressor.setDictionary] Throwing error: \(result)")
            throw ZLibError.decompressionFailed(result)
        }
    }

    /// Reset the decom
    /// pressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflateReset(&stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }

    /// Copy the decompressor state to another decompressor
    /// - Parameter destination: The destination decompressor
    /// - Throws: ZLibError if copy fails
    public func copy(to destination: Decompressor) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflateCopy(&destination.stream, &stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        destination.isInitialized = true
    }

    /// Prime the decompressor with bits
    /// - Parameters:
    ///   - bits: Number of bits to prime
    ///   - value: Value to prime with
    /// - Throws: ZLibError if priming fails
    public func prime(bits: Int32, value: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflatePrime(&stream, bits, value)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }

    /// Synchronize the inflate stream
    /// - Throws: ZLibError if synchronization fails
    public func sync() throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflateSync(&stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }

    /// Check if current position is a sync point
    /// - Returns: True if current position is a sync point
    /// - Throws: ZLibError if operation fails
    public func isSyncPoint() throws -> Bool {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflateSyncPoint(&stream)
        return result == Z_OK
    }

    /// Reset the decompressor with different window bits
    /// - Parameter windowBits: New window bits
    /// - Throws: ZLibError if reset fails
    public func resetWithWindowBits(_ windowBits: WindowBits) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let result = swift_inflateReset2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
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
        let result = swift_inflateGetDictionary(&stream, nil, &dictLength)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }

        guard dictLength > 0 else {
            return Data()
        }

        var dictionary = Data(count: Int(dictLength))
        let getResult = dictionary.withUnsafeMutableBytes { dictPtr in
            swift_inflateGetDictionary(&stream, dictPtr.bindMemory(to: Bytef.self).baseAddress!, &dictLength)
        }

        guard getResult == Z_OK else {
            throw ZLibError.decompressionFailed(getResult)
        }

        dictionary.count = Int(dictLength)
        return dictionary
    }

    /// Get the current stream mark position
    /// - Returns: Stream mark position
    /// - Throws: ZLibError if operation fails
    public func getMark() throws -> Int {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        let mark = swift_inflateMark(&stream)
        guard mark >= 0 else {
            throw ZLibError.decompressionFailed(Int32(mark))
        }

        return Int(mark)
    }

    /// Get the number of codes used by the inflate stream
    /// - Returns: Number of codes used
    /// - Throws: ZLibError if operation fails
    public func getCodesUsed() throws -> UInt {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        return swift_inflateCodesUsed(&stream)
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

    /// Get pending output from the decompressor
    /// - Returns: Tuple of (pending bytes, pending bits)
    /// - Throws: ZLibError if operation fails
    public func getPending() throws -> (pending: UInt32, bits: Int32) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var pending: UInt32 = 0
        var bits: Int32 = 0

        let result = swift_inflatePending(&stream, &pending, &bits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }

        return (pending, bits)
    }

    /// Decompress data in chunks
    /// - Parameters:
    ///   - input: Input compressed data chunk
    ///   - flush: Flush mode
    ///   - dictionary: Optional dictionary for decompression
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ input: Data, flush: FlushMode = .noFlush, dictionary: Data? = nil) throws -> Data {
        zlibDebug("[Decompressor.decompress] Called with input size: \(input.count), flush: \(flush), dictionary: \(dictionary?.count ?? 0)")
        guard isInitialized else {
            zlibError("[Decompressor.decompress] Not initialized!")
            zlibError("Decompressor not initialized")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        zlibDebug("Decompressing \(input.count) bytes with flush mode: \(flush)")
        logStreamState(stream, operation: "Decompression start")

        var output = Data()
        var outputBuffer = Data(count: 1024) // 1KB chunks
        var dictWasSet = false

        // Set input data
        try input.withUnsafeBytes { inputPtr in
            stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(input.count)

            // Process all input data
            var result: Int32 = Z_OK
            var iteration = 0
            repeat {
                iteration += 1
                if ZLibVerboseConfig.logProgress {
                    zlibDebug("[Decompressor.decompress] Iteration \(iteration): avail_in=\(stream.avail_in), avail_out=\(stream.avail_out)")
                }
                let outputBufferCount = outputBuffer.count
                result = try outputBuffer.withUnsafeMutableBytes { outputPtr -> Int32 in
                    stream.next_out = outputPtr.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    let inflateResult = swift_inflate(&stream, flush.zlibFlush)
                    zlibDebug("[Decompressor.decompress] swift_inflate returned: \(inflateResult)")
                    if inflateResult == Z_NEED_DICT {
                        if let dict = dictionary, !dictWasSet {
                            zlibInfo("[Decompressor.decompress] Z_NEED_DICT, setting dictionary...")
                            try setDictionary(dict)
                            dictWasSet = true
                            // Do not return here; let the loop continue and call inflate again
                            return Z_OK
                        } else {
                            zlibError("[Decompressor.decompress] Throwing Z_NEED_DICT error")
                            throw ZLibError.decompressionFailed(Z_NEED_DICT)
                        }
                    }
                    if inflateResult != Z_OK, inflateResult != Z_STREAM_END, inflateResult != Z_BUF_ERROR {
                        zlibError("[Decompressor.decompress] Decompression failed with error code: \(inflateResult)")
                        zlibError("Decompression failed with error code: \(inflateResult)")
                        throw ZLibError.decompressionFailed(inflateResult)
                    }
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let temp = Data(bytes: outputPtr.baseAddress!, count: bytesProcessed)
                        output.append(temp)
                        zlibDebug("[Decompressor.decompress] Produced \(bytesProcessed) bytes of decompressed data")
                        zlibDebug("Produced \(bytesProcessed) bytes of decompressed data")
                    }
                    return inflateResult
                }
                if dictWasSet {
                    dictWasSet = false // Only allow one extra pass after setting dictionary
                }
            } while result != Z_STREAM_END && (stream.avail_in > 0 || stream.avail_out == 0 || dictWasSet)
        }

        logStreamState(stream, operation: "Decompression end")
        zlibInfo("Decompression completed: \(input.count) -> \(output.count) bytes")

        return output
    }

    /// Finish decompression
    /// - Returns: Final decompressed data
    /// - Throws: ZLibError if decompression fails
    public func finish() throws -> Data {
        try decompress(Data(), flush: .finish)
    }

    /// Get the gzip header from the stream (must be called after initializeAdvanced)
    public func getGzipHeader() throws -> GzipHeader {
        var cHeader = gz_header()
        let result = swift_inflateGetHeader(&stream, &cHeader)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        return from_c_gz_header(&cHeader)
    }
}
