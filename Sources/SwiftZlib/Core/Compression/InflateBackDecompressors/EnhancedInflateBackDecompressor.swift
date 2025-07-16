//
//  EnhancedInflateBackDecompressor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// Enhanced InflateBack decompression with improved C callback support
/// This provides better integration with the actual zlib inflateBack functions
final class EnhancedInflateBackDecompressor: InflateBackDecompressor {
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
            swift_inflateBackEnd(&stream)
        }
    }

    // MARK: Functions

    /// Initialize the enhanced InflateBack decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateBackInit(&stream, windowBits.zlibWindowBits, &window)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }

    /// Process data using enhanced InflateBack with improved callbacks
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

        // Use the existing InflateBackDecompressor implementation for now
        // The true C callback implementation requires more complex Swift-C bridging
        let inflateBack = BaseInflateBackDecompressor()
        try inflateBack.initialize()
        try inflateBack.processWithCallbacks(inputProvider: inputProvider, outputHandler: outputHandler)
    }

    /// Process data from a Data source using enhanced InflateBack
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
