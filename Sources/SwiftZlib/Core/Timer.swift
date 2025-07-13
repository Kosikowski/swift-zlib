//  Timer.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import CoreFoundation
#endif

/// Platform-agnostic timer for performance measurements
@_spi(SwiftZLibTime)
public struct SwiftZlibTimer {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    private let start: CFAbsoluteTime
    #else
    private let start: Date
    #endif
    
    /// Initialize a new timer
    @_spi(SwiftZLibTime)
    public init() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        start = CFAbsoluteTimeGetCurrent()
        #else
        start = Date()
        #endif
    }
    
    /// Get the elapsed time in seconds
    @_spi(SwiftZLibTime)
    public var elapsed: TimeInterval {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return CFAbsoluteTimeGetCurrent() - start
        #else
        return Date().timeIntervalSince(start)
        #endif
    }
    
    /// Get the elapsed time in milliseconds
    @_spi(SwiftZLibTime)
    public var elapsedMilliseconds: Double {
        return elapsed * 1000
    }
} 