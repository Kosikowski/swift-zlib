//
//  MemoryLevel.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

/// Memory usage levels for ZLib operations
///
/// The memory level controls how much memory zlib uses for compression.
/// Higher levels use more memory but provide better compression speed.
/// Memory usage follows the formula: 2^(memLevel + 6) bytes
///
/// For example:
/// - Level 1: 128KB memory usage
/// - Level 6: 4MB memory usage
/// - Level 9: 32MB memory usage
public enum MemoryLevel: Int32, Sendable {
    /// Minimum memory usage (128KB)
    ///
    /// Uses the least memory but is the slowest compression option.
    /// Best for:
    /// - Memory-constrained environments (embedded systems, mobile devices)
    /// - When memory is more important than speed
    /// - Batch processing where memory needs to be shared
    ///
    /// Memory usage: 128KB
    /// Performance: Slowest
    case minimum = 1

    /// Low memory usage (256KB)
    ///
    /// Slightly more memory than minimum, with modest performance improvement.
    /// Good balance for memory-constrained systems that need some speed.
    ///
    /// Memory usage: 256KB
    /// Performance: Very slow
    case level2 = 2

    /// Low-medium memory usage (512KB)
    ///
    /// Moderate memory usage with noticeable performance improvement.
    /// Suitable for systems with limited but not severely constrained memory.
    ///
    /// Memory usage: 512KB
    /// Performance: Slow
    case level3 = 3

    /// Medium memory usage (1MB)
    ///
    /// Balanced memory usage with good performance improvement.
    /// Default choice for most applications when memory isn't severely limited.
    ///
    /// Memory usage: 1MB
    /// Performance: Moderate
    case level4 = 4

    /// Medium-high memory usage (2MB)
    ///
    /// Higher memory usage with significant performance improvement.
    /// Good choice for desktop applications and servers with adequate memory.
    ///
    /// Memory usage: 2MB
    /// Performance: Good
    case level5 = 5

    /// High memory usage (4MB)
    ///
    /// Substantial memory usage with excellent performance.
    /// Recommended for most modern systems and applications.
    ///
    /// Memory usage: 4MB
    /// Performance: Very good
    case level6 = 6

    /// Very high memory usage (8MB)
    ///
    /// High memory usage with near-optimal performance.
    /// Best for systems with plenty of available memory.
    ///
    /// Memory usage: 8MB
    /// Performance: Excellent
    case level7 = 7

    /// Ultra-high memory usage (16MB)
    ///
    /// Very high memory usage with optimal performance.
    /// Use when memory is abundant and maximum speed is needed.
    ///
    /// Memory usage: 16MB
    /// Performance: Near optimal
    case level8 = 8

    /// Maximum memory usage (32MB)
    ///
    /// Uses the most memory but provides the fastest compression.
    /// Best for:
    /// - High-performance servers with abundant memory
    /// - When speed is critical and memory is available
    /// - Batch processing where speed matters more than memory
    ///
    /// Memory usage: 32MB
    /// Performance: Fastest
    case maximum = 9

    // MARK: Computed Properties

    /// The corresponding zlib memory level
    public var zlibMemoryLevel: Int32 { rawValue }

    /// The actual memory usage in bytes for this memory level
    ///
    /// Calculated using the formula: 2^(memLevel + 6) bytes
    /// This represents the internal buffer size used by zlib for compression
    public var memoryUsageBytes: Int {
        1 << (rawValue + 6)
    }

    /// The memory usage in a human-readable format
    public var memoryUsageDescription: String {
        let bytes = memoryUsageBytes
        if bytes >= 1024 * 1024 {
            return "\(bytes / (1024 * 1024))MB"
        } else if bytes >= 1024 {
            return "\(bytes / 1024)KB"
        } else {
            return "\(bytes)B"
        }
    }

    /// A description of the performance characteristics
    public var performanceDescription: String {
        switch self {
            case .minimum:
                "Slowest (memory-optimized)"
            case .level2:
                "Very slow"
            case .level3:
                "Slow"
            case .level4:
                "Moderate"
            case .level5:
                "Good"
            case .level6:
                "Very good"
            case .level7:
                "Excellent"
            case .level8:
                "Near optimal"
            case .maximum:
                "Fastest (speed-optimized)"
        }
    }
}
