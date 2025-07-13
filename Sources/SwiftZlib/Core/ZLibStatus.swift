//
//  ZLibStatus.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum ZLibStatus: Int32 {
    case ok = 0
    case streamEnd = 1
    case needDict = 2
    case errNo = -1
    case streamError = -2
    case dataError = -3
    case memoryError = -4
    case bufferError = -5
    case incompatibleVersion = -6
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
