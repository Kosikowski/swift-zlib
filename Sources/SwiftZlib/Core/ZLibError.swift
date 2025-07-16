//
//  ZLibError.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
#if canImport(zlib)
    import zlib
#else
    import SwiftZlibCShims
#endif

// MARK: - ZLibError

/// Errors that can occur during ZLib operations
public enum ZLibError: Error, LocalizedError {
    /// Compression operation failed with the given zlib error code
    case compressionFailed(Int32)
    /// Decompression operation failed with the given zlib error code
    case decompressionFailed(Int32)
    /// Invalid data was provided for the operation
    case invalidData
    /// Memory allocation failed during the operation
    case memoryError
    /// Stream operation failed with the given zlib error code
    case streamError(Int32)
    /// ZLib version mismatch between library and application
    case versionMismatch
    /// Dictionary is required for decompression but not provided
    case needDictionary
    /// Data format error during operation
    case dataError
    /// Buffer error during operation
    case bufferError
    /// File operation failed with the underlying error
    case fileError(Error)

    // MARK: Computed Properties

    /// Human-readable description of the error
    public var errorDescription: String? {
        switch self {
            case let .compressionFailed(code):
                "Compression failed with code: \(code) - \(String(cString: zError(code)))"
            case let .decompressionFailed(code):
                "Decompression failed with code: \(code) - \(String(cString: zError(code)))"
            case .invalidData:
                "Invalid data provided"
            case .memoryError:
                "Memory allocation error"
            case let .streamError(code):
                "Stream operation failed with code: \(code) - \(String(cString: zError(code)))"
            case .versionMismatch:
                "ZLib version mismatch"
            case .needDictionary:
                "Dictionary needed for decompression"
            case .dataError:
                "Data error during operation"
            case .bufferError:
                "Buffer error during operation"
            case let .fileError(underlyingError):
                "File operation failed: \(underlyingError.localizedDescription)"
        }
    }
}
