//
//  CompressionPhase.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

// MARK: - CompressionPhase

/// Phases of the compression process
public enum CompressionPhase: String {
    /// Reading input data
    case reading
    /// Compressing data
    case compressing
    /// Writing output data
    case writing
    /// Flushing remaining data
    case flushing
    /// Compression completed
    case finished
}

// MARK: - ProgressInfo

/// Information about compression progress
public struct ProgressInfo {
    /// Number of bytes processed so far
    public let processedBytes: Int
    /// Total number of bytes to process
    public let totalBytes: Int
    /// Progress percentage (0.0 to 1.0)
    public let percentage: Double
    /// Processing speed in bytes per second (if available)
    public let speedBytesPerSec: Double?
    /// Estimated time to completion in seconds (if available)
    public let etaSeconds: Double?
    /// Current compression phase
    public let phase: CompressionPhase
    /// Timestamp of this progress update
    public let timestamp: Date
}

/// Callback for advanced progress reporting
/// - Parameter info: Progress information
/// - Returns: True to continue, false to cancel
public typealias AdvancedProgressCallback = (ProgressInfo) -> Bool
