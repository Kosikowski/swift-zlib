//
//  InflateBackDecompressorCBridged.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// True InflateBack decompressor using C callback bridging
public final class InflateBackDecompressorCBridged {
    // MARK: Properties

    private var stream = z_stream()
    private var isInitialized = false
    private var window: [UInt8]
    private let windowSize: Int

    // MARK: Lifecycle

    public init(windowBits: WindowBits = .deflate) {
        windowSize = 1 << windowBits.zlibWindowBits
        window = [UInt8](repeating: 0, count: windowSize)
    }

    deinit {
        if isInitialized {
            swift_inflateBackEnd(&stream)
        }
    }

    // MARK: Functions

    /// Initialize the InflateBack decompressor
    public func initialize() throws {
        let result = swift_inflateBackInit(&stream, WindowBits.deflate.zlibWindowBits, &window)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }

    /// Process data using true C-callback InflateBack
    /// - Parameters:
    ///   - inputProvider: Closure providing input Data chunks
    ///   - outputHandler: Closure receiving output Data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }

        // Context for bridging
        class CallbackContext {
            let inputProvider: () -> Data?
            let outputHandler: (Data) -> Bool
            var inputBuffer: Data?
            init(inputProvider: @escaping () -> Data?, outputHandler: @escaping (Data) -> Bool) {
                self.inputProvider = inputProvider
                self.outputHandler = outputHandler
            }
        }
        let context = CallbackContext(inputProvider: inputProvider, outputHandler: outputHandler)
        let contextPtr = Unmanaged.passRetained(context).toOpaque()
        defer { Unmanaged<CallbackContext>.fromOpaque(contextPtr).release() }

        // C input callback
        let cInput: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?, UnsafeMutablePointer<Int32>?) -> Int32 = {
            ctxPtr, bufPtr, availPtr in
            guard let ctxPtr else { return 0 }
            let ctx = Unmanaged<CallbackContext>.fromOpaque(ctxPtr).takeUnretainedValue()
            guard let data = ctx.inputProvider() else {
                availPtr?.pointee = 0
                return 0
            }
            ctx.inputBuffer = data // Hold reference so pointer stays valid
            availPtr?.pointee = Int32(data.count)
            if let bufPtr {
                bufPtr.pointee = UnsafeMutablePointer<UInt8>(mutating: data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! })
            }
            return Int32(data.count)
        }
        // C output callback
        let cOutput: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UInt8>?, Int32) -> Int32 = {
            ctxPtr, buf, len in
            guard let ctxPtr, let buf else { return Z_STREAM_ERROR }
            let ctx = Unmanaged<CallbackContext>.fromOpaque(ctxPtr).takeUnretainedValue()
            let data = Data(bytes: buf, count: Int(len))
            return ctx.outputHandler(data) ? Z_OK : Z_STREAM_ERROR
        }
        // Call C shim
        let result = swift_inflateBackWithCallbacks(&stream, cInput, contextPtr, cOutput, contextPtr)
        guard result == Z_STREAM_END || result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }

    /// Process all data from a Data source
    public func processData(_ input: Data, chunkSize: Int = 1024) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        var output = Data()
        var inputIndex = 0
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let size = min(remaining, chunkSize)
                let chunk = input.subdata(in: inputIndex ..< (inputIndex + size))
                inputIndex += size
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )
        return output
    }
}
