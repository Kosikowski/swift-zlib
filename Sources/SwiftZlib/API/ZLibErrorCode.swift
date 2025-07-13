//
//  ZLibErrorCode.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public enum ZLibErrorCode: Int32 {
    case ok = 0
    case streamEnd = 1
    case needDict = 2
    case errNo = -1
    case streamError = -2
    case dataError = -3
    case memoryError = -4
    case bufferError = -5
    case incompatibleVersion = -6
    public var description: String { String(cString: swift_zError(rawValue)) }
    public var isError: Bool { rawValue < 0 }
    public var isSuccess: Bool { rawValue >= 0 }
}
