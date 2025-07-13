//
//  GzipFileError.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Errors that can occur during gzip file operations
public enum GzipFileError: Error, LocalizedError {
    /// Failed to open a gzip file
    case openFailed(String)
    /// Failed to read from a gzip file
    case readFailed(String)
    /// Failed to write to a gzip file
    case writeFailed(String)
    /// Failed to seek within a gzip file
    case seekFailed(String)
    /// Failed to flush a gzip file
    case flushFailed(String)
    /// Failed to close a gzip file
    case closeFailed(String)
    /// Unknown gzip file error
    case unknown(String)

    // MARK: Computed Properties

    /// Human-readable description of the error
    public var errorDescription: String? {
        switch self {
            case let .openFailed(msg): return "Failed to open gzip file: \(msg)"
            case let .readFailed(msg): return "Failed to read gzip file: \(msg)"
            case let .writeFailed(msg): return "Failed to write gzip file: \(msg)"
            case let .seekFailed(msg): return "Failed to seek gzip file: \(msg)"
            case let .flushFailed(msg): return "Failed to flush gzip file: \(msg)"
            case let .closeFailed(msg): return "Failed to close gzip file: \(msg)"
            case let .unknown(msg): return "Gzip file error: \(msg)"
        }
    }
}
