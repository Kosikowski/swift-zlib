//  Logging.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
import zlib

#if canImport(CoreFoundation)
    import CoreFoundation
#endif

// MARK: - ZLibVerboseConfig

/// Verbose logging configuration for ZLib operations
public enum ZLibVerboseConfig {
    // MARK: Nested Types

    /// Log level for filtering messages
    public enum LogLevel: Int, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        // MARK: Computed Properties

        public var description: String {
            switch self {
                case .debug: "DEBUG"
                case .info: "INFO"
                case .warning: "WARNING"
                case .error: "ERROR"
            }
        }
    }

    // MARK: Static Properties

    /// Enable verbose logging
    public static var enabled: Bool = false

    /// Enable detailed stream state logging
    public static var logStreamState: Bool = false

    /// Enable compression/decompression progress logging
    public static var logProgress: Bool = false

    /// Enable memory allocation logging
    public static var logMemory: Bool = false

    /// Enable error detailed logging
    public static var logErrors: Bool = false

    /// Enable performance timing
    public static var logTiming: Bool = false

    /// Current minimum log level
    public static var minLogLevel: LogLevel = .info

    /// Custom log handler
    public static var logHandler: ((LogLevel, String) -> Void)?

    // MARK: Static Functions

    /// Enable all verbose logging
    public static func enableAll() {
        enabled = true
        logStreamState = true
        logProgress = true
        logMemory = true
        logErrors = true
        logTiming = true
        minLogLevel = .debug
    }

    /// Disable all verbose logging
    public static func disableAll() {
        enabled = false
        logStreamState = false
        logProgress = false
        logMemory = false
        logErrors = false
        logTiming = false
    }
}

/// Internal logging functions
func zlibLog(_ level: ZLibVerboseConfig.LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    guard ZLibVerboseConfig.enabled, level.rawValue >= ZLibVerboseConfig.minLogLevel.rawValue else { return }

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let timestamp = formatter.string(from: Date())

    let fileName = (file as NSString).lastPathComponent
    let logMessage = "[\(timestamp)] [\(level.description)] [\(fileName):\(line)] \(function): \(message)"

    if let handler = ZLibVerboseConfig.logHandler {
        handler(level, logMessage)
    } else {
        print(logMessage)
    }
}

func zlibDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.debug, message, file: file, function: function, line: line)
}

func zlibInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.info, message, file: file, function: function, line: line)
}

func zlibWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.warning, message, file: file, function: function, line: line)
}

func zlibError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.error, message, file: file, function: function, line: line)
}

// MARK: - ZLibTimer

/// Performance timing utilities
class ZLibTimer {
    // MARK: Properties

    private let timer: SwiftZlibTimer
    private let operation: String

    // MARK: Lifecycle

    init(_ operation: String) {
        self.operation = operation
        timer = SwiftZlibTimer()
        zlibDebug("Starting \(operation)")
    }

    // MARK: Functions

    func finish() -> TimeInterval {
        let duration = timer.elapsed
        zlibDebug("Finished \(operation) in \(String(format: "%.4f", duration))s")
        return duration
    }
}

func withTiming<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
    if ZLibVerboseConfig.logTiming {
        let timer = ZLibTimer(operation)
        let result = try block()
        _ = timer.finish()
        return result
    } else {
        return try block()
    }
}

/// Stream state logging utilities
func logStreamState(_ stream: z_stream, operation: String) {
    guard ZLibVerboseConfig.logStreamState else { return }

    zlibDebug("""
    Stream state for \(operation):
    - total_in: \(stream.total_in)
    - total_out: \(stream.total_out)
    - avail_in: \(stream.avail_in)
    - avail_out: \(stream.avail_out)
    - next_in: \(stream.next_in != nil ? "valid" : "nil")
    - next_out: \(stream.next_out != nil ? "valid" : "nil")
    """)
}

func logMemoryUsage(_ operation: String, bytes: Int) {
    guard ZLibVerboseConfig.logMemory else { return }
    zlibDebug("Memory allocation for \(operation): \(bytes) bytes")
}

func logProgress(_ operation: String, processed _: Int, total: Int, current: Int) {
    guard ZLibVerboseConfig.logProgress else { return }
    let percentage = total > 0 ? Double(current) / Double(total) * 100.0 : 0.0
    zlibInfo("\(operation) progress: \(current)/\(total) bytes (\(String(format: "%.1f", percentage))%)")
}
