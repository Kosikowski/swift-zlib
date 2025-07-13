//
//  ZLibStatus.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Status codes for ZLib operations
public enum ZLibStatus: Int32 {
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

    /// Human-readable description of the status
    public var description: String {
        switch self {
            case .ok: return "OK"
            case .streamEnd: return "Stream end"
            case .needDict: return "Need dictionary"
            case .errNo: return "Error number"
            case .streamError: return "Stream error"
            case .dataError: return "Data error"
            case .memoryError: return "Memory error"
            case .bufferError: return "Buffer error"
            case .incompatibleVersion: return "Incompatible version"
        }
    }
}
