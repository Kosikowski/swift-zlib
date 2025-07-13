//
//  MemoryLevel.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

public enum MemoryLevel: Int32, Sendable {
    case minimum = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    case level5 = 5
    case level6 = 6
    case level7 = 7
    case level8 = 8
    case maximum = 9
    public var zlibMemoryLevel: Int32 { rawValue }
}
