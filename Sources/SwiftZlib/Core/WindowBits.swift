//
//  WindowBits.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum WindowBits: Int32, Sendable {
    case deflate = 15
    case gzip = 31
    case raw = -15
    case auto = 47
    public var zlibWindowBits: Int32 { rawValue }
}
