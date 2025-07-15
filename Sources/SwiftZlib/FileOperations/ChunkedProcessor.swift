//
//  ChunkedProcessor.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

/// Chunked data processor for memory-efficient operations
final class ChunkedProcessor {
    // MARK: Properties

    private let config: StreamingConfig

    // MARK: Lifecycle

    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }

    // MARK: Functions

    /// Process data in chunks with callback
    public func processChunks<T>(
        data: Data,
        processor: @escaping (Data) throws -> T
    ) throws
        -> [T]
    {
        var results: [T] = []
        var offset = 0

        while offset < data.count {
            let chunkSize = min(config.bufferSize, data.count - offset)
            let chunk = data.subdata(in: offset ..< (offset + chunkSize))
            let result = try processor(chunk)
            results.append(result)
            offset += chunkSize
        }

        return results
    }

    /// Process large data with streaming
    public func processStreaming<T>(
        data: Data,
        processor: @escaping (Data, Bool) throws -> T
    ) throws
        -> [T]
    {
        var results: [T] = []
        var offset = 0

        while offset < data.count {
            let chunkSize = min(config.bufferSize, data.count - offset)
            let chunk = data.subdata(in: offset ..< (offset + chunkSize))
            let isLast = (offset + chunkSize) >= data.count
            let result = try processor(chunk, isLast)
            results.append(result)
            offset += chunkSize
        }

        return results
    }
}
