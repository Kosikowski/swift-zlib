//
//  GzipFileError.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum GzipFileError: Error, LocalizedError {
    case openFailed(String)
    case readFailed(String)
    case writeFailed(String)
    case seekFailed(String)
    case flushFailed(String)
    case closeFailed(String)
    case unknown(String)

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
