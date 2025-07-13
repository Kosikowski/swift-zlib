//
//  MemoryLevel.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Memory usage levels for ZLib operations
public enum MemoryLevel: Int32, Sendable {
    /// Minimum memory usage (slowest)
    case minimum = 1
    /// Level 2 memory usage
    case level2 = 2
    /// Level 3 memory usage
    case level3 = 3
    /// Level 4 memory usage
    case level4 = 4
    /// Level 5 memory usage
    case level5 = 5
    /// Level 6 memory usage
    case level6 = 6
    /// Level 7 memory usage
    case level7 = 7
    /// Level 8 memory usage
    case level8 = 8
    /// Maximum memory usage (fastest)
    case maximum = 9

    // MARK: Computed Properties

    /// The corresponding zlib memory level
    public var zlibMemoryLevel: Int32 { rawValue }
}
