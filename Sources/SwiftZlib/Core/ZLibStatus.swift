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
            case .ok: "OK"
            case .streamEnd: "Stream end"
            case .needDict: "Need dictionary"
            case .errNo: "Error number"
            case .streamError: "Stream error"
            case .dataError: "Data error"
            case .memoryError: "Memory error"
            case .bufferError: "Buffer error"
            case .incompatibleVersion: "Incompatible version"
        }
    }
}
