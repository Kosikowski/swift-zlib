//
//  ZLib+Combine.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Combine
import Foundation

public extension ZLib {
    /// Combine publisher for async compression
    /// - Parameters:
    ///   - data: Input data to compress
    ///   - options: Compression options
    /// - Returns: A publisher that emits compressed data or an error
    static func compressPublisher(_ data: Data, options: CompressionOptions = CompressionOptions()) -> AnyPublisher<Data, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await compressAsync(data, options: options)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Combine publisher for async decompression
    /// - Parameters:
    ///   - data: Compressed data to decompress
    ///   - options: Decompression options
    /// - Returns: A publisher that emits decompressed data or an error
    static func decompressPublisher(_ data: Data, options: DecompressionOptions = DecompressionOptions()) -> AnyPublisher<Data, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await decompressAsync(data, options: options)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Combine publisher for file compression (completes when done)
    /// - SeeAlso: compressFile, compressFileAsync, compressFileProgressPublisher
    static func compressFilePublisher(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    )
        -> AnyPublisher<Void, Error>
    {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let compressor = FileChunkedCompressor(
                        bufferSize: bufferSize,
                        compressionLevel: compressionLevel,
                        windowBits: windowBits
                    )
                    try compressor.compressFile(from: sourcePath, to: destinationPath)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Combine publisher for file decompression (completes when done)
    /// - SeeAlso: decompressFile, decompressFileAsync, decompressFileProgressPublisher
    static func decompressFilePublisher(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    )
        -> AnyPublisher<Void, Error>
    {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let decompressor = FileChunkedDecompressor(
                        bufferSize: bufferSize,
                        windowBits: windowBits
                    )
                    try decompressor.decompressFile(from: sourcePath, to: destinationPath)
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Combine publisher for file compression with progress updates
    /// - SeeAlso: compressFile, compressFileAsync, compressFilePublisher
    static func compressFileProgressPublisher(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    )
        -> AnyPublisher<(processed: Int, total: Int, percent: Double), Error>
    {
        let subject = PassthroughSubject<(processed: Int, total: Int, percent: Double), Error>()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let compressor = FileChunkedCompressor(
                    bufferSize: bufferSize,
                    compressionLevel: compressionLevel,
                    windowBits: windowBits
                )
                try compressor.compressFile(from: sourcePath, to: destinationPath) { processed, total in
                    let percent = total > 0 ? Double(processed) / Double(total) * 100.0 : 0.0
                    subject.send((processed, total, percent))
                }
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }

    /// Combine publisher for file decompression with progress updates
    /// - SeeAlso: decompressFile, decompressFileAsync, decompressFilePublisher
    static func decompressFileProgressPublisher(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    )
        -> AnyPublisher<(processed: Int, total: Int, percent: Double), Error>
    {
        let subject = PassthroughSubject<(processed: Int, total: Int, percent: Double), Error>()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decompressor = FileChunkedDecompressor(
                    bufferSize: bufferSize,
                    windowBits: windowBits
                )
                try decompressor.decompressFile(from: sourcePath, to: destinationPath) { processed, total in
                    let percent = total > 0 ? Double(processed) / Double(total) * 100.0 : 0.0
                    subject.send((processed, total, percent))
                }
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }
}
