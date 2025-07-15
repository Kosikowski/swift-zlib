//
//  InflateBackDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Advanced InflateBack decompression with true C callback support
/// Note: This is a simplified implementation that provides InflateBack-like functionality
/// using the regular inflate API with Swift-friendly callbacks.
final class InflateBackDecompressor {
    // MARK: Properties

    private var stream = z_stream()
    private var isInitialized = false
    private var window: [Bytef]
    private let windowSize: Int
    private let windowBits: WindowBits

    // MARK: Lifecycle

    public init(windowBits: WindowBits = .deflate) {
        self.windowBits = windowBits
        windowSize = 1 << windowBits.zlibWindowBits
        window = [Bytef](repeating: 0, count: windowSize)
    }

    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }

    // MARK: Functions

    /// Initialize the InflateBack-style decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateInit2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }

    /// Process data using advanced callback system
    /// - Parameters:
    ///   - inputProvider: Function that provides input data chunks
    ///   - outputHandler: Function that receives output data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var result: Int32 = Z_OK
        let bufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: bufferSize)
        var hasProcessedInput = false

        while result != Z_STREAM_END {
            // Get input data
            guard let inputData = inputProvider() else {
                // No more input data, finish processing
                break
            }

            hasProcessedInput = true

            // Process input data with valid pointer
            try inputData.withUnsafeBytes { inputPtr in
                #if os(Windows)
                    stream.next_in = inputPtr.bindMemory(to: Bytef.self).baseAddress
                #else
                    stream.next_in = inputPtr.bindMemory(to: Bytef.self).baseAddress.map { UnsafeMutablePointer(mutating: $0) }
                #endif
                stream.avail_in = uInt(inputData.count)

                // Process input
                repeat {
                    let outputBufferCount = outputBuffer.count
                    result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                        stream.next_out = buffer.baseAddress
                        stream.avail_out = uInt(outputBufferCount)

                        let inflateResult = swift_inflate(&stream, Z_NO_FLUSH)
                        guard inflateResult != Z_STREAM_ERROR else {
                            return Z_STREAM_ERROR
                        }

                        let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                        if bytesProcessed > 0 {
                            let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                            if !outputHandler(outputData) {
                                return Z_STREAM_ERROR
                            }
                        }

                        return inflateResult
                    }

                    guard result != Z_STREAM_ERROR else {
                        throw ZLibError.streamError(result)
                    }

                } while stream.avail_out == 0 && stream.avail_in > 0 && result != Z_STREAM_END
            }
        }

        // Finish processing if we have processed input
        if hasProcessedInput, result == Z_OK {
            repeat {
                let outputBufferCount = outputBuffer.count
                result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                    stream.next_out = buffer.baseAddress
                    stream.avail_out = uInt(outputBufferCount)

                    let inflateResult = swift_inflate(&stream, Z_FINISH)
                    guard inflateResult != Z_STREAM_ERROR else {
                        return Z_STREAM_ERROR
                    }

                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                        if !outputHandler(outputData) {
                            return Z_STREAM_ERROR
                        }
                    }

                    return inflateResult
                }

                guard result != Z_STREAM_ERROR else {
                    throw ZLibError.streamError(result)
                }

            } while stream.avail_out == 0 && result != Z_STREAM_END
        }
    }

    /// Process data from a Data source
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - maxOutputSize: Maximum output buffer size
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    public func processData(_ input: Data, maxOutputSize _: Int = 4096) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        var output = Data()
        var inputIndex = 0

        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let chunkSize = min(remaining, 1024)
                let chunk = input.subdata(in: inputIndex ..< (inputIndex + chunkSize))
                inputIndex += chunkSize
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true // Always continue processing
            }
        )

        return output
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
}
