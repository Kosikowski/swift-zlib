//
//  ZLibError.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public enum ZLibError: Error, LocalizedError {
    case compressionFailed(Int32)
    case decompressionFailed(Int32)
    case invalidData
    case memoryError
    case streamError(Int32)
    case versionMismatch
    case needDictionary
    case dataError
    case bufferError

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
        }
    }
}
