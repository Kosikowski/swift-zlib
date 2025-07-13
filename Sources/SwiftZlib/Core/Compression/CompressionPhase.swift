//
//  CompressionPhase.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

public enum CompressionPhase: String {
    case reading, compressing, writing, flushing, finished
}

public struct ProgressInfo {
    public let processedBytes: Int
    public let totalBytes: Int
    public let percentage: Double
    public let speedBytesPerSec: Double?
    public let etaSeconds: Double?
    public let phase: CompressionPhase
    public let timestamp: Date
}

public typealias AdvancedProgressCallback = (ProgressInfo) -> Bool // return false to cancel
