//
//  CompressionStrategy.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum CompressionStrategy: Int32, Sendable {
    case defaultStrategy = 0
    case filtered = 1
    case huffmanOnly = 2
    case rle = 3
    case fixed = 4
    public var zlibStrategy: Int32 { rawValue }
}
