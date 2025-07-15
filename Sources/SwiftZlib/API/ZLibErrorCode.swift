//
//  ZLibErrorCode.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

/// ZLib error codes and their meanings
public enum ZLibErrorCode: Int32 {
    /// Operation completed successfully
    case ok = 0
    /// Stream has reached the end
    case streamEnd = 1
    /// Dictionary is needed for decompression
    case needDict = 2
    /// General error
    case errNo = -1
    /// Stream state error
    case streamError = -2
    /// Data format error
    case dataError = -3
    /// Memory allocation error
    case memoryError = -4
    /// Buffer error
    case bufferError = -5
    /// Incompatible version error
    case incompatibleVersion = -6

    // MARK: Computed Properties

    /// Human-readable description of the error code
    public var description: String { String(cString: zError(rawValue)) }

    /// Whether this code represents an error condition
    public var isError: Bool { rawValue < 0 }

    /// Whether this code represents a successful operation
    public var isSuccess: Bool { rawValue >= 0 }
}
