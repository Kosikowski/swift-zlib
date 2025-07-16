//
//  DecompressorType.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 16/07/2025.
//

import CZLib
import Foundation

// MARK: - DecompressorType

/// Common protocol for inflate back decompressors
/// This protocol defines the standard interface that all inflate back decompressor
/// implementations should follow, allowing for polymorphic usage and testing.
public protocol DecompressorType {
    /// Initialize the decompressor
    /// - Throws: ZLibError if initialization fails
    func initialize() throws

    /// Process data using callbacks
    /// - Parameters:
    ///   - inputProvider: Function that provides input data chunks
    ///   - outputHandler: Function that receives output data chunks
    /// - Throws: ZLibError if processing fails
    func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws

    /// Process data from a Data source
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - maxOutputSize: Maximum output buffer size (optional)
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    func processData(_ input: Data, maxOutputSize: Int) throws -> Data

    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool)
}

// MARK: - Default Implementation

public extension DecompressorType {
    /// Process data with default max output size
    /// - Parameter input: Input compressed data
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    func processData(_ input: Data) throws -> Data {
        try processData(input, maxOutputSize: 4096)
    }
}
