//
//  ZLibError.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

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
                return "Compression failed with code: \(code) - \(String(cString: swift_zError(code)))"
            case let .decompressionFailed(code):
                return "Decompression failed with code: \(code) - \(String(cString: swift_zError(code)))"
            case .invalidData:
                return "Invalid data provided"
            case .memoryError:
                return "Memory allocation error"
            case let .streamError(code):
                return "Stream operation failed with code: \(code) - \(String(cString: swift_zError(code)))"
            case .versionMismatch:
                return "ZLib version mismatch"
            case .needDictionary:
                return "Dictionary needed for decompression"
            case .dataError:
                return "Data error during operation"
            case .bufferError:
                return "Buffer error during operation"
            case let .fileError(underlyingError):
                return "File operation failed: \(underlyingError.localizedDescription)"
        }
    }
}
