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
            case let .openFailed(msg): "Failed to open gzip file: \(msg)"
            case let .readFailed(msg): "Failed to read gzip file: \(msg)"
            case let .writeFailed(msg): "Failed to write gzip file: \(msg)"
            case let .seekFailed(msg): "Failed to seek gzip file: \(msg)"
            case let .flushFailed(msg): "Failed to flush gzip file: \(msg)"
            case let .closeFailed(msg): "Failed to close gzip file: \(msg)"
            case let .unknown(msg): "Gzip file error: \(msg)"
        }
    }
}
