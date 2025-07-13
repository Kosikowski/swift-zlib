//
//  FlushMode.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum FlushMode: Int32, Sendable {
    case noFlush = 0
    case partialFlush = 1
    case syncFlush = 2
    case fullFlush = 3
    case finish = 4
    case block = 5
    case trees = 6
    public var zlibFlush: Int32 { rawValue }
}
