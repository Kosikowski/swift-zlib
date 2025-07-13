//
//  CompressionLevel.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum CompressionLevel: Int32, Sendable {
    case noCompression = 0
    case bestSpeed = 1
    case bestCompression = 9
    case defaultCompression = -1
    public var zlibLevel: Int32 { rawValue }
}
