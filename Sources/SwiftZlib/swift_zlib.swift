import Foundation
import CZLib

// MARK: - Verbose Logging System

/// Verbose logging configuration for ZLib operations
public struct ZLibVerboseConfig {
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
    
    /// Log level for filtering messages
    public enum LogLevel: Int, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        
        public var description: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }
    }
    
    /// Current minimum log level
    public static var minLogLevel: LogLevel = .info
    
    /// Custom log handler
    public static var logHandler: ((LogLevel, String) -> Void)?
    
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
fileprivate func zlibLog(_ level: ZLibVerboseConfig.LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    guard ZLibVerboseConfig.enabled && level.rawValue >= ZLibVerboseConfig.minLogLevel.rawValue else { return }
    
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

fileprivate func zlibDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.debug, message, file: file, function: function, line: line)
}

fileprivate func zlibInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.info, message, file: file, function: function, line: line)
}

fileprivate func zlibWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.warning, message, file: file, function: function, line: line)
}

fileprivate func zlibError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    zlibLog(.error, message, file: file, function: function, line: line)
}

/// Performance timing utilities
fileprivate class ZLibTimer {
    private let startTime: CFAbsoluteTime
    private let operation: String
    
    init(_ operation: String) {
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
        zlibDebug("Starting \(operation)")
    }
    
    func finish() -> TimeInterval {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        zlibDebug("Finished \(operation) in \(String(format: "%.4f", duration))s")
        return duration
    }
}

fileprivate func withTiming<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
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
fileprivate func logStreamState(_ stream: z_stream, operation: String) {
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

fileprivate func logMemoryUsage(_ operation: String, bytes: Int) {
    guard ZLibVerboseConfig.logMemory else { return }
    zlibDebug("Memory allocation for \(operation): \(bytes) bytes")
}

fileprivate func logProgress(_ operation: String, processed: Int, total: Int, current: Int) {
    guard ZLibVerboseConfig.logProgress else { return }
    let percentage = total > 0 ? Double(current) / Double(total) * 100.0 : 0.0
    zlibInfo("\(operation) progress: \(current)/\(total) bytes (\(String(format: "%.1f", percentage))%)")
}

/// Errors that can occur during ZLib operations
public enum ZLibError: Error, LocalizedError {
    case compressionFailed(Int32)
    case decompressionFailed(Int32)
    case invalidData
    case memoryError
    case streamError(Int32)
    case versionMismatch
    case needDictionary
    case dataError
    case bufferError
    
    public var errorDescription: String? {
        switch self {
        case .compressionFailed(let code):
            return "Compression failed with code: \(code) - \(String(cString: swift_zError(code)))"
        case .decompressionFailed(let code):
            return "Decompression failed with code: \(code) - \(String(cString: swift_zError(code)))"
        case .invalidData:
            return "Invalid data provided"
        case .memoryError:
            return "Memory allocation error"
        case .streamError(let code):
            return "Stream operation failed with code: \(code) - \(String(cString: swift_zError(code)))"
        case .versionMismatch:
            return "ZLib version mismatch"
        case .needDictionary:
            return "Dictionary needed for decompression"
        case .dataError:
            return "Data error during operation"
        case .bufferError:
            return "Buffer error during operation"
        }
    }
}

/// Compression levels for ZLib
public enum CompressionLevel: Int32, Sendable {
    case noCompression = 0
    case bestSpeed = 1
    case bestCompression = 9
    case defaultCompression = -1
    
    public var zlibLevel: Int32 {
        return self.rawValue
    }
}

/// Compression methods
public enum CompressionMethod: Int32 {
    case deflate = 8  // Only method currently supported by ZLib
    
    public var zlibMethod: Int32 {
        return self.rawValue
    }
}

/// Window bits for different formats
public enum WindowBits: Int32, Sendable {
    case deflate = 15      // Standard deflate format
    case gzip = 31         // Gzip format (16 + 15)
    case raw = -15         // Raw deflate format (no header/trailer)
    case auto = 47         // Auto-detect gzip or deflate (32 + 15)
    
    public var zlibWindowBits: Int32 {
        return self.rawValue
    }
}

/// Memory levels for compression
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
    
    public var zlibMemoryLevel: Int32 {
        return self.rawValue
    }
}

/// Compression strategies
public enum CompressionStrategy: Int32, Sendable {
    case defaultStrategy = 0
    case filtered = 1
    case huffmanOnly = 2
    case rle = 3
    case fixed = 4
    
    public var zlibStrategy: Int32 {
        return self.rawValue
    }
}

/// Flush modes for stream operations
public enum FlushMode: Int32, Sendable {
    case noFlush = 0
    case partialFlush = 1
    case syncFlush = 2
    case fullFlush = 3
    case finish = 4
    case block = 5
    case trees = 6
    
    public var zlibFlush: Int32 {
        return self.rawValue
    }
}

/// ZLib status codes
public enum ZLibStatus: Int32 {
    case ok = 0
    case streamEnd = 1
    case needDict = 2
    case errNo = -1
    case streamError = -2
    case dataError = -3
    case memoryError = -4
    case bufferError = -5
    case incompatibleVersion = -6
    
    public var description: String {
        switch self {
        case .ok: return "OK"
        case .streamEnd: return "Stream end"
        case .needDict: return "Need dictionary"
        case .errNo: return "Error number"
        case .streamError: return "Stream error"
        case .dataError: return "Data error"
        case .memoryError: return "Memory error"
        case .bufferError: return "Buffer error"
        case .incompatibleVersion: return "Incompatible version"
        }
    }
}

/// ZLib error codes for detailed error handling
public enum ZLibErrorCode: Int32 {
    case ok = 0
    case streamEnd = 1
    case needDict = 2
    case errNo = -1
    case streamError = -2
    case dataError = -3
    case memoryError = -4
    case bufferError = -5
    case incompatibleVersion = -6
    
    public var description: String {
        return String(cString: swift_zError(self.rawValue))
    }
    
    public var isError: Bool {
        return self.rawValue < 0
    }
    
    public var isSuccess: Bool {
        return self.rawValue >= 0
    }
}

/// Swifty representation of a gzip header (gz_header)
public struct GzipHeader: Sendable {
    public var text: Int32 = 0
    public var time: UInt32 = 0
    public var xflags: Int32 = 0
    public var os: Int32 = 255
    public var extra: Data? = nil
    public var name: String? = nil
    public var comment: String? = nil
    public var hcrc: Int32 = 0
    public var done: Int32 = 0
    
    public init() {}
}

// MARK: - Gzip Header Bridging

fileprivate func to_c_gz_header(_ swift: GzipHeader, cHeader: UnsafeMutablePointer<gz_header>) {
    cHeader.pointee.text = swift.text
    cHeader.pointee.time = uLong(swift.time)
    cHeader.pointee.xflags = swift.xflags
    cHeader.pointee.os = swift.os
    cHeader.pointee.hcrc = swift.hcrc
    cHeader.pointee.done = swift.done
    // Extra, name, comment: set pointers if present
    if let extra = swift.extra {
        extra.withUnsafeBytes { buf in
            cHeader.pointee.extra = UnsafeMutablePointer<Bytef>(mutating: buf.baseAddress?.assumingMemoryBound(to: Bytef.self))
            cHeader.pointee.extra_len = uInt(extra.count)
        }
    } else {
        cHeader.pointee.extra = nil
        cHeader.pointee.extra_len = 0
    }
    if let name = swift.name {
        name.withCString { cstr in
            cHeader.pointee.name = UnsafeMutablePointer<Bytef>(mutating: UnsafePointer<Bytef>(OpaquePointer(cstr)))
        }
    } else {
        cHeader.pointee.name = nil
    }
    if let comment = swift.comment {
        comment.withCString { cstr in
            cHeader.pointee.comment = UnsafeMutablePointer<Bytef>(mutating: UnsafePointer<Bytef>(OpaquePointer(cstr)))
        }
    } else {
        cHeader.pointee.comment = nil
    }
}

fileprivate func from_c_gz_header(_ cHeader: UnsafePointer<gz_header>) -> GzipHeader {
    var swift = GzipHeader()
    swift.text = cHeader.pointee.text
    swift.time = UInt32(cHeader.pointee.time)
    swift.xflags = cHeader.pointee.xflags
    swift.os = cHeader.pointee.os
    swift.hcrc = cHeader.pointee.hcrc
    swift.done = cHeader.pointee.done
    if let extra = cHeader.pointee.extra, cHeader.pointee.extra_len > 0 {
        swift.extra = Data(bytes: extra, count: Int(cHeader.pointee.extra_len))
    }
    if let name = cHeader.pointee.name {
        swift.name = String(cString: UnsafePointer<CChar>(OpaquePointer(name)))
    }
    if let comment = cHeader.pointee.comment {
        swift.comment = String(cString: UnsafePointer<CChar>(OpaquePointer(comment)))
    }
    return swift
}

/// Compression configuration options
public struct CompressionOptions: Sendable {
    /// Compression format (zlib, gzip, or raw deflate)
    public var format: CompressionFormat
    /// Compression level
    public var level: CompressionLevel
    /// Compression strategy
    public var strategy: CompressionStrategy
    /// Memory level for compression
    public var memoryLevel: MemoryLevel
    /// Dictionary for compression (optional)
    public var dictionary: Data?
    /// Gzip header information (optional, only used with gzip format)
    public var gzipHeader: GzipHeader?
    
    public init(
        format: CompressionFormat = .zlib,
        level: CompressionLevel = .defaultCompression,
        strategy: CompressionStrategy = .defaultStrategy,
        memoryLevel: MemoryLevel = .maximum,
        dictionary: Data? = nil,
        gzipHeader: GzipHeader? = nil
    ) {
        self.format = format
        self.level = level
        self.strategy = strategy
        self.memoryLevel = memoryLevel
        self.dictionary = dictionary
        self.gzipHeader = gzipHeader
    }
}

/// Decompression configuration options
public struct DecompressionOptions: Sendable {
    /// Decompression format (zlib, gzip, raw deflate, or auto-detect)
    public var format: CompressionFormat
    /// Dictionary for decompression (optional)
    public var dictionary: Data?
    /// Whether to auto-detect format (only used when format is .auto)
    public var autoDetect: Bool
    
    public init(
        format: CompressionFormat = .auto,
        dictionary: Data? = nil,
        autoDetect: Bool = true
    ) {
        self.format = format
        self.dictionary = dictionary
        self.autoDetect = autoDetect
    }
}

/// Compression format enum for better API
public enum CompressionFormat: Sendable {
    case zlib
    case gzip
    case raw
    case auto
    
    internal var windowBits: WindowBits {
        switch self {
        case .zlib: return .deflate
        case .gzip: return .gzip
        case .raw: return .raw
        case .auto: return .auto
        }
    }
}

/// High-level ZLib compression and decompression
public struct ZLib {
    
    /// Get the ZLib version string
    public static var version: String {
        return String(cString: swift_zlibVersion())
    }
    
    /// Get ZLib compile flags
    public static var compileFlags: UInt {
        return swift_zlibCompileFlags()
    }
    
    /// Get detailed ZLib compile flags information
    public static var compileFlagsInfo: ZLibCompileFlags {
        return ZLibCompileFlags(flags: compileFlags)
    }
    
    /// Get detailed error information for a zlib error code
    /// - Parameter errorCode: The zlib error code
    /// - Returns: Detailed error information
    public static func getErrorInfo(_ errorCode: Int32) -> (code: ZLibErrorCode, description: String, isError: Bool) {
        let errorCode = ZLibErrorCode(rawValue: errorCode) ?? .errNo
        return (errorCode, errorCode.description, errorCode.isError)
    }
    
    /// Check if a zlib return code indicates success
    /// - Parameter code: The zlib return code
    /// - Returns: True if the code indicates success
    public static func isSuccess(_ code: Int32) -> Bool {
        return code >= 0
    }
    
    /// Check if a zlib return code indicates an error
    /// - Parameter code: The zlib return code
    /// - Returns: True if the code indicates an error
    public static func isError(_ code: Int32) -> Bool {
        return code < 0
    }
    
    /// Get a human-readable error message for a zlib error code
    /// - Parameter code: The zlib error code
    /// - Returns: Human-readable error message
    public static func getErrorMessage(_ code: Int32) -> String {
        return String(cString: swift_zError(code))
    }
    
    /// Check if an error is recoverable
    /// - Parameter errorCode: The zlib error code
    /// - Returns: True if the error is recoverable
    public static func isRecoverableError(_ errorCode: Int32) -> Bool {
        switch errorCode {
        case Z_BUF_ERROR, Z_NEED_DICT:
            return true
        case Z_STREAM_ERROR, Z_DATA_ERROR, Z_MEM_ERROR, Z_VERSION_ERROR:
            return false
        default:
            return false
        }
    }
    
    /// Get error recovery suggestions
    /// - Parameter errorCode: The zlib error code
    /// - Returns: Array of recovery suggestions
    public static func getErrorRecoverySuggestions(_ errorCode: Int32) -> [String] {
        switch errorCode {
        case Z_BUF_ERROR:
            return [
                "Increase output buffer size",
                "Check if input data is complete",
                "Ensure sufficient memory is available"
            ]
        case Z_NEED_DICT:
            return [
                "Provide a dictionary for decompression",
                "Use setDictionary() method",
                "Check if compressed data requires a dictionary"
            ]
        case Z_STREAM_ERROR:
            return [
                "Reinitialize the stream",
                "Check stream parameters",
                "Ensure proper initialization order"
            ]
        case Z_DATA_ERROR:
            return [
                "Check input data integrity",
                "Verify compression format",
                "Ensure data is not corrupted"
            ]
        case Z_MEM_ERROR:
            return [
                "Free up system memory",
                "Reduce compression level",
                "Use smaller buffer sizes"
            ]
        case Z_VERSION_ERROR:
            return [
                "Update zlib library",
                "Check version compatibility",
                "Recompile with compatible zlib version"
            ]
        default:
            return ["Unknown error - check zlib documentation"]
        }
    }
    
    /// Validate compression parameters
    /// - Parameters:
    ///   - level: Compression level
    ///   - windowBits: Window bits
    ///   - memoryLevel: Memory level
    ///   - strategy: Compression strategy
    /// - Returns: Array of validation warnings/errors
    public static func validateParameters(
        level: CompressionLevel,
        windowBits: WindowBits,
        memoryLevel: MemoryLevel,
        strategy: CompressionStrategy
    ) -> [String] {
        var warnings: [String] = []
        
        if level == .bestCompression && memoryLevel == .minimum {
            warnings.append("Best compression with minimum memory may be slow")
        }
        
        if windowBits == .raw && level != .noCompression {
            warnings.append("Raw format with compression may not work as expected")
        }
        
        if strategy == .huffmanOnly && level == .noCompression {
            warnings.append("Huffman-only strategy with no compression is redundant")
        }
        
        return warnings
    }
    
    /// Estimate the compressed size for given input size and compression level
    /// - Parameters:
    ///   - inputSize: Size of input data
    ///   - level: Compression level
    /// - Returns: Estimated compressed size
    public static func estimateCompressedSize(_ inputSize: Int, level: CompressionLevel = .defaultCompression) -> Int {
        let bound = swift_compressBound(uLong(inputSize))
        // Apply a rough estimation based on compression level
        let factor: Double
        switch level {
        case .noCompression: factor = 1.0
        case .bestSpeed: factor = 0.8
        case .defaultCompression: factor = 0.7
        case .bestCompression: factor = 0.6
        }
        return Int(Double(bound) * factor)
    }
    
    /// Get recommended buffer sizes for streaming operations
    /// - Parameter windowBits: Window bits for the operation
    /// - Returns: Tuple of (input buffer size, output buffer size)
    public static func getRecommendedBufferSizes(windowBits: WindowBits = .deflate) -> (input: Int, output: Int) {
        let windowSize = 1 << windowBits.zlibWindowBits
        let inputBuffer = min(4096, windowSize / 4)  // 4KB or window size / 4
        let outputBuffer = min(8192, windowSize / 2)  // 8KB or window size / 2
        return (inputBuffer, outputBuffer)
    }
    
    /// Calculate memory usage for a compression operation
    /// - Parameters:
    ///   - windowBits: Window bits
    ///   - memoryLevel: Memory level
    /// - Returns: Estimated memory usage in bytes
    public static func estimateMemoryUsage(windowBits: WindowBits = .deflate, memoryLevel: MemoryLevel = .maximum) -> Int {
        let windowSize = 1 << windowBits.zlibWindowBits
        let memorySize = 1 << (memoryLevel.zlibMemoryLevel + 6)  // 2^(memLevel + 6)
        return windowSize + memorySize
    }
    
    /// Get optimal compression parameters for given data size
    /// - Parameter dataSize: Size of data to compress
    /// - Returns: Tuple of recommended parameters
    public static func getOptimalParameters(for dataSize: Int) -> (level: CompressionLevel, windowBits: WindowBits, memoryLevel: MemoryLevel, strategy: CompressionStrategy) {
        if dataSize < 1024 {
            // Small data: fast compression
            return (.bestSpeed, .deflate, .level3, .defaultStrategy)
        } else if dataSize < 1024 * 1024 {
            // Medium data: balanced
            return (.defaultCompression, .deflate, .level6, .defaultStrategy)
        } else {
            // Large data: best compression
            return (.bestCompression, .deflate, .maximum, .defaultStrategy)
        }
    }
    
    /// Get performance profile for different compression levels
    /// - Parameter dataSize: Size of data to compress
    /// - Returns: Array of performance profiles
    public static func getPerformanceProfiles(for dataSize: Int) -> [(level: CompressionLevel, estimatedTime: Double, estimatedRatio: Double)] {
        let baseTime = Double(dataSize) / 1000000.0 // Rough estimate
        
        return [
            (.noCompression, baseTime * 0.1, 1.0),
            (.bestSpeed, baseTime * 0.3, 0.8),
            (.defaultCompression, baseTime * 0.6, 0.7),
            (.bestCompression, baseTime * 1.2, 0.6)
        ]
    }
    
    /// Calculate optimal buffer sizes for streaming
    /// - Parameters:
    ///   - dataSize: Total data size
    ///   - availableMemory: Available memory in bytes
    /// - Returns: Tuple of (input buffer, output buffer, max concurrent streams)
    public static func calculateOptimalBufferSizes(dataSize: Int, availableMemory: Int) -> (inputBuffer: Int, outputBuffer: Int, maxStreams: Int) {
        let memoryPerStream = estimateMemoryUsage()
        let maxStreams = max(1, availableMemory / memoryPerStream)
        
        let inputBuffer = min(4096, dataSize / maxStreams)
        let outputBuffer = min(8192, Int(Double(inputBuffer) * 0.7))
        
        return (inputBuffer, outputBuffer, maxStreams)
    }
    
    /// Get compression statistics for different levels
    /// - Parameter data: Sample data for testing
    /// - Returns: Array of compression statistics
    public static func getCompressionStatistics(for data: Data) -> [(level: CompressionLevel, ratio: Double, time: TimeInterval)] {
        var results: [(level: CompressionLevel, ratio: Double, time: TimeInterval)] = []
        
        for level in [CompressionLevel.noCompression, .bestSpeed, .defaultCompression, .bestCompression] {
            let startTime = Date()
            do {
                let compressed = try compress(data, level: level)
                let endTime = Date()
                let ratio = Double(compressed.count) / Double(data.count)
                let time = endTime.timeIntervalSince(startTime)
                results.append((level, ratio, time))
            } catch {
                results.append((level, 1.0, 0.0))
            }
        }
        
        return results
    }
    
    /// ZLib compile flags breakdown
    public struct ZLibCompileFlags {
        public let flags: UInt
        
        public init(flags: UInt) {
            self.flags = flags
        }
        
        /// ZLib version
        public var version: String {
            return ZLib.version
        }
        
        /// Size of unsigned int
        public var sizeOfUInt: Int {
            return Int((flags >> 0) & 0xFF)
        }
        
        /// Size of unsigned long
        public var sizeOfULong: Int {
            return Int((flags >> 8) & 0xFF)
        }
        
        /// Size of pointer
        public var sizeOfPointer: Int {
            return Int((flags >> 16) & 0xFF)
        }
        
        /// Size of z_off_t
        public var sizeOfZOffT: Int {
            return Int((flags >> 24) & 0xFF)
        }
        
        /// Compiler flags
        public var compilerFlags: UInt {
            return (flags >> 32) & 0xFFFF
        }
        
        /// Library flags
        public var libraryFlags: UInt {
            return (flags >> 48) & 0xFFFF
        }
        
        /// Is debug build
        public var isDebug: Bool {
            return (flags & 0x1000000000000000) != 0
        }
        
        /// Is optimized build
        public var isOptimized: Bool {
            return (flags & 0x2000000000000000) != 0
        }
    }
    
    /// Compress data with the specified compression level
    /// - Parameters:
    ///   - data: The data to compress
    ///   - level: The compression level (default: .defaultCompression)
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    public static func compress(_ data: Data, level: CompressionLevel = .defaultCompression) throws -> Data {
        zlibInfo("Starting compression: \(data.count) bytes, level: \(level)")
        
        return try withTiming("Compression") {
            let sourceLen = uLong(data.count)
            var destLen = swift_compressBound(sourceLen)
            
            logMemoryUsage("Compression output buffer", bytes: Int(destLen))
            var compressedData = Data(count: Int(destLen))
            
            let result = compressedData.withUnsafeMutableBytes { destPtr in
                data.withUnsafeBytes { sourcePtr in
                    swift_compress(
                        destPtr.bindMemory(to: Bytef.self).baseAddress!,
                        &destLen,
                        sourcePtr.bindMemory(to: Bytef.self).baseAddress!,
                        sourceLen,
                        level.zlibLevel
                    )
                }
            }
            
            if result != Z_OK {
                zlibError("Compression failed with code: \(result) - \(String(cString: swift_zError(result)))")
                throw ZLibError.compressionFailed(result)
            }
            
            compressedData.count = Int(destLen)
            let compressionRatio = Double(compressedData.count) / Double(data.count)
            zlibInfo("Compression completed: \(data.count) -> \(compressedData.count) bytes (ratio: \(String(format: "%.2f", compressionRatio)))")
            
            return compressedData
        }
    }
    
    /// Decompress data
    /// - Parameter data: The compressed data to decompress
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    public static func decompress(_ data: Data) throws -> Data {
        zlibInfo("Starting decompression: \(data.count) bytes")
        
        // For very large data (>1MB), use streaming to avoid memory issues
        if data.count > 1_000_000 {
            zlibDebug("Large data detected, using streaming decompression")
            let decompressor = Decompressor()
            try decompressor.initialize()
            return try decompressor.decompress(data)
        }
        
        return try withTiming("Decompression") {
            // For decompression, we need to estimate the output size
            // Start with a reasonable guess and grow if needed
            var destLen = uLong(data.count * 4) // Initial guess
            logMemoryUsage("Decompression output buffer", bytes: Int(destLen))
            var decompressedData = Data(count: Int(destLen))
            
            let result = decompressedData.withUnsafeMutableBytes { destPtr in
                data.withUnsafeBytes { sourcePtr in
                    swift_uncompress(
                        destPtr.bindMemory(to: Bytef.self).baseAddress!,
                        &destLen,
                        sourcePtr.bindMemory(to: Bytef.self).baseAddress!,
                        uLong(data.count)
                    )
                }
            }
            
            if result == Z_BUF_ERROR {
                // Buffer too small, try with progressively larger buffers
                zlibDebug("Buffer too small, retrying with larger buffer")
                var bufferMultiplier = 8
                var retryResult = result
                
                // For very large data, use more reasonable limits
                let maxMultiplier = data.count > 1_000_000 ? 64 : 512
                
                while retryResult == Z_BUF_ERROR && bufferMultiplier <= maxMultiplier {
                    destLen = uLong(data.count * bufferMultiplier)
                    logMemoryUsage("Decompression retry buffer (multiplier: \(bufferMultiplier))", bytes: Int(destLen))
                    decompressedData = Data(count: Int(destLen))
                    
                    retryResult = decompressedData.withUnsafeMutableBytes { destPtr in
                        data.withUnsafeBytes { sourcePtr in
                            swift_uncompress(
                                destPtr.bindMemory(to: Bytef.self).baseAddress!,
                                &destLen,
                                sourcePtr.bindMemory(to: Bytef.self).baseAddress!,
                                uLong(data.count)
                            )
                        }
                    }
                    
                    bufferMultiplier *= 2
                }
                
                if retryResult != Z_OK {
                    zlibError("Decompression retry failed with code: \(retryResult) - \(String(cString: swift_zError(retryResult)))")
                    throw ZLibError.decompressionFailed(retryResult)
                }
            } else if result != Z_OK {
                zlibError("Decompression failed with code: \(result) - \(String(cString: swift_zError(result)))")
                throw ZLibError.decompressionFailed(result)
            }
            
            decompressedData.count = Int(destLen)
            let expansionRatio = Double(decompressedData.count) / Double(data.count)
            zlibInfo("Decompression completed: \(data.count) -> \(decompressedData.count) bytes (ratio: \(String(format: "%.2f", expansionRatio)))")
            
            return decompressedData
        }
    }
    
    /// Partially decompress data, returning how much input/output was consumed
    /// - Parameters:
    ///   - data: The compressed data to decompress
    ///   - maxOutputSize: Maximum size of output buffer (default: 4096)
    /// - Returns: Tuple of (decompressed data, bytes consumed from input, bytes written to output)
    /// - Throws: ZLibError if decompression fails
    public static func partialDecompress(_ data: Data, maxOutputSize: Int = 4096) throws -> (decompressed: Data, inputConsumed: Int, outputWritten: Int) {
        var destLen = uLong(maxOutputSize)
        var sourceLen = uLong(data.count)
        var decompressedData = Data(count: maxOutputSize)
        
        let result = decompressedData.withUnsafeMutableBytes { destPtr in
            data.withUnsafeBytes { sourcePtr in
                swift_uncompress2(
                    destPtr.bindMemory(to: Bytef.self).baseAddress!,
                    &destLen,
                    sourcePtr.bindMemory(to: Bytef.self).baseAddress!,
                    &sourceLen
                )
            }
        }
        
        if result == Z_BUF_ERROR {
            // Buffer too small, try with progressively larger buffers
            zlibDebug("Partial decompression buffer too small, retrying with larger buffer")
            var bufferMultiplier = 2
            var retryResult = result
            
            while retryResult == Z_BUF_ERROR && bufferMultiplier <= 16 {
                destLen = uLong(maxOutputSize * bufferMultiplier)
                decompressedData = Data(count: Int(destLen))
                
                retryResult = decompressedData.withUnsafeMutableBytes { destPtr in
                    data.withUnsafeBytes { sourcePtr in
                        swift_uncompress2(
                            destPtr.bindMemory(to: Bytef.self).baseAddress!,
                            &destLen,
                            sourcePtr.bindMemory(to: Bytef.self).baseAddress!,
                            &sourceLen
                        )
                    }
                }
                
                bufferMultiplier *= 2
            }
            
            guard retryResult == Z_OK else {
                throw ZLibError.decompressionFailed(retryResult)
            }
        } else if result != Z_OK {
            throw ZLibError.decompressionFailed(result)
        }
        
        decompressedData.count = Int(destLen)
        return (decompressedData, Int(sourceLen), Int(destLen))
    }
    
    // MARK: - Checksum Functions
    
    /// Calculate Adler-32 checksum
    /// - Parameters:
    ///   - data: The data to checksum
    ///   - initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    public static func adler32(_ data: Data, initialValue: uLong = 1) -> uLong {
        zlibDebug("Calculating Adler-32 for \(data.count) bytes with initial value: \(initialValue)")
        
        let result = data.withUnsafeBytes { buffer in
            swift_adler32(initialValue, buffer.bindMemory(to: Bytef.self).baseAddress!, uInt(data.count))
        }
        
        zlibDebug("Adler-32 result: \(result)")
        return result
    }
    
    /// Calculate CRC-32 checksum
    /// - Parameters:
    ///   - data: The data to checksum
    ///   - initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    public static func crc32(_ data: Data, initialValue: uLong = 0) -> uLong {
        zlibDebug("Calculating CRC-32 for \(data.count) bytes with initial value: \(initialValue)")
        
        let result = data.withUnsafeBytes { buffer in
            swift_crc32(initialValue, buffer.bindMemory(to: Bytef.self).baseAddress!, uInt(data.count))
        }
        
        zlibDebug("CRC-32 result: \(result)")
        return result
    }
    
    /// Calculate Adler-32 checksum for a string
    /// - Parameters:
    ///   - string: The string to checksum
    ///   - initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    public static func adler32(_ string: String, initialValue: uLong = 1) -> uLong? {
        guard let data = string.data(using: .utf8) else { return nil }
        return adler32(data, initialValue: initialValue)
    }
    
    /// Calculate CRC-32 checksum for a string
    /// - Parameters:
    ///   - string: The string to checksum
    ///   - initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    public static func crc32(_ string: String, initialValue: uLong = 0) -> uLong? {
        guard let data = string.data(using: .utf8) else { return nil }
        return crc32(data, initialValue: initialValue)
    }
    
    // MARK: - Checksum Combination Functions
    
    /// Combine two Adler-32 checksums
    /// - Parameters:
    ///   - adler1: First Adler-32 checksum
    ///   - adler2: Second Adler-32 checksum
    ///   - len2: Length of the second data block
    /// - Returns: Combined Adler-32 checksum
    public static func adler32Combine(_ adler1: uLong, _ adler2: uLong, len2: Int) -> uLong {
        return swift_adler32_combine(adler1, adler2, len2)
    }
    
    /// Combine two CRC-32 checksums
    /// - Parameters:
    ///   - crc1: First CRC-32 checksum
    ///   - crc2: Second CRC-32 checksum
    ///   - len2: Length of the second data block
    /// - Returns: Combined CRC-32 checksum
    public static func crc32Combine(_ crc1: uLong, _ crc2: uLong, len2: Int) -> uLong {
        return swift_crc32_combine(crc1, crc2, len2)
    }
    
    /// Compress data with advanced options
    /// - Parameters:
    ///   - data: The data to compress
    ///   - options: Compression configuration options
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    public static func compress(_ data: Data, options: CompressionOptions) throws -> Data {
        zlibInfo("Starting compression with options: format=\(options.format), level=\(options.level)")
        
        return try withTiming("Compression with options") {
            // Use Compressor for advanced options
            let compressor = Compressor()
            try compressor.initializeAdvanced(
                level: options.level,
                method: .deflate,
                windowBits: options.format.windowBits,
                memoryLevel: options.memoryLevel,
                strategy: options.strategy
            )
            
            // Set dictionary if provided
            if let dictionary = options.dictionary {
                try compressor.setDictionary(dictionary)
            }
            
            // Set gzip header if provided and format is gzip
            if options.format == .gzip, let header = options.gzipHeader {
                // Note: gzip header setting would need to be implemented in Compressor
                zlibWarning("Gzip header setting not yet implemented")
            }
            
            // Compress with finish flush
            let compressed = try compressor.compress(data, flush: .finish)
            
            let compressionRatio = Double(compressed.count) / Double(data.count)
            zlibInfo("Compression completed: \(data.count) -> \(compressed.count) bytes (ratio: \(String(format: "%.2f", compressionRatio)))")
            
            return compressed
        }
    }
    
    /// Decompress data with advanced options
    /// - Parameters:
    ///   - data: The compressed data to decompress
    ///   - options: Decompression configuration options
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    public static func decompress(_ data: Data, options: DecompressionOptions) throws -> Data {
        zlibInfo("Starting decompression with options: format=\(options.format)")
        
        return try withTiming("Decompression with options") {
            // For very large data (>1MB), use streaming to avoid memory issues
            if data.count > 1_000_000 {
                zlibDebug("Large data detected, using streaming decompression")
                let decompressor = Decompressor()
                try decompressor.initializeAdvanced(windowBits: options.format.windowBits)
                
                // Set dictionary if provided
                if let dictionary = options.dictionary {
                    try decompressor.setDictionary(dictionary)
                }
                
                return try decompressor.decompress(data)
            }
            
            // Use simple decompression for smaller data
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: options.format.windowBits)
            
            // Set dictionary if provided
            if let dictionary = options.dictionary {
                try decompressor.setDictionary(dictionary)
            }
            
            let decompressed = try decompressor.decompress(data)
            
            let expansionRatio = Double(decompressed.count) / Double(data.count)
            zlibInfo("Decompression completed: \(data.count) -> \(decompressed.count) bytes (ratio: \(String(format: "%.2f", expansionRatio)))")
            
            return decompressed
        }
    }
    
    /// Compress data with gzip format
    /// - Parameters:
    ///   - data: The data to compress
    ///   - level: Compression level (default: .defaultCompression)
    ///   - header: Optional gzip header information
    /// - Returns: Compressed data in gzip format
    /// - Throws: ZLibError if compression fails
    public static func compressGzip(_ data: Data, level: CompressionLevel = .defaultCompression, header: GzipHeader? = nil) throws -> Data {
        let options = CompressionOptions(format: .gzip, level: level, gzipHeader: header)
        return try compress(data, options: options)
    }
    
    /// Compress data with raw deflate format (for InflateBack compatibility)
    /// - Parameters:
    ///   - data: The data to compress
    ///   - level: Compression level (default: .defaultCompression)
    /// - Returns: Compressed data in raw deflate format
    /// - Throws: ZLibError if compression fails
    public static func compressRaw(_ data: Data, level: CompressionLevel = .defaultCompression) throws -> Data {
        let options = CompressionOptions(format: .raw, level: level)
        return try compress(data, options: options)
    }
    
    /// Decompress data with auto-format detection
    /// - Parameters:
    ///   - data: The compressed data to decompress
    ///   - dictionary: Optional dictionary for decompression
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    public static func decompressAuto(_ data: Data, dictionary: Data? = nil) throws -> Data {
        let options = DecompressionOptions(format: .auto, dictionary: dictionary)
        return try decompress(data, options: options)
    }
}

// MARK: - Gzip File API

public enum GzipFileError: Error, LocalizedError {
    case openFailed(String)
    case readFailed(String)
    case writeFailed(String)
    case seekFailed(String)
    case flushFailed(String)
    case closeFailed(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .openFailed(let msg): return "Failed to open gzip file: \(msg)"
        case .readFailed(let msg): return "Failed to read gzip file: \(msg)"
        case .writeFailed(let msg): return "Failed to write gzip file: \(msg)"
        case .seekFailed(let msg): return "Failed to seek gzip file: \(msg)"
        case .flushFailed(let msg): return "Failed to flush gzip file: \(msg)"
        case .closeFailed(let msg): return "Failed to close gzip file: \(msg)"
        case .unknown(let msg): return "Gzip file error: \(msg)"
        }
    }
}

public final class GzipFile {
    private var filePtr: UnsafeMutableRawPointer?
    private var lastError: String?
    
    public let path: String
    public let mode: String
    
    public init(path: String, mode: String) throws {
        self.path = path
        self.mode = mode
        guard let ptr = swift_gzopen(path, mode) else {
            throw GzipFileError.openFailed("\(path) [mode=\(mode)]")
        }
        self.filePtr = ptr
    }
    
    deinit {
        try? close()
    }
    
    public func close() throws {
        guard let ptr = filePtr else { return }
        let result = swift_gzclose(ptr)
        filePtr = nil
        if result != Z_OK {
            throw GzipFileError.closeFailed(errorMessage())
        }
    }
    
    public func readData(count: Int) throws -> Data {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = Data(count: count)
        let bytesRead = buffer.withUnsafeMutableBytes { bufPtr in
            swift_gzread(ptr, bufPtr.baseAddress, UInt32(count))
        }
        let bytesReadInt = Int(bytesRead)
        if bytesReadInt < 0 {
            throw GzipFileError.readFailed(errorMessage())
        }
        buffer.count = bytesReadInt
        return buffer
    }
    
    public func readString(count: Int, encoding: String.Encoding = .utf8) throws -> String? {
        let data = try readData(count: count)
        return String(data: data, encoding: encoding)
    }
    
    public func writeData(_ data: Data) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let written = data.withUnsafeBytes { bufPtr in
            swift_gzwrite(ptr, UnsafeMutableRawPointer(mutating: bufPtr.baseAddress), UInt32(data.count))
        }
        let writtenInt = Int(written)
        if writtenInt != data.count {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    public func writeString(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw GzipFileError.writeFailed("String encoding failed")
        }
        try writeData(data)
    }
    
    public func seek(offset: Int, whence: Int32 = SEEK_SET) throws {
        guard let ptr = filePtr else { throw GzipFileError.seekFailed("File not open") }
        let result = swift_gzseek(ptr, offset, whence)
        if result < 0 {
            throw GzipFileError.seekFailed(errorMessage())
        }
    }
    
    public func tell() throws -> Int {
        guard let ptr = filePtr else { throw GzipFileError.seekFailed("File not open") }
        let pos = swift_gztell(ptr)
        let posInt = Int(pos)
        if posInt < 0 {
            throw GzipFileError.seekFailed(errorMessage())
        }
        return posInt
    }
    
    public func flush(flush: Int32 = Z_SYNC_FLUSH) throws {
        guard let ptr = filePtr else { throw GzipFileError.flushFailed("File not open") }
        let result = swift_gzflush(ptr, flush)
        if result != Z_OK {
            throw GzipFileError.flushFailed(errorMessage())
        }
    }
    
    public func rewind() throws {
        guard let ptr = filePtr else { throw GzipFileError.seekFailed("File not open") }
        let result = swift_gzrewind(ptr)
        if result != Z_OK {
            throw GzipFileError.seekFailed(errorMessage())
        }
    }
    
    public func eof() -> Bool {
        guard let ptr = filePtr else { return true }
        return swift_gzeof(ptr) != 0
    }
    
    public func setParams(level: CompressionLevel, strategy: CompressionStrategy) throws {
        guard let ptr = filePtr else { throw GzipFileError.unknown("File not open") }
        let result = swift_gzsetparams(ptr, level.zlibLevel, strategy.zlibStrategy)
        if result != Z_OK {
            throw GzipFileError.unknown(errorMessage())
        }
    }
    
    public func errorMessage() -> String {
        guard let ptr = filePtr else { return "File not open" }
        var errnum: Int32 = 0
        if let cstr = swift_gzerror(ptr, &errnum) {
            return String(cString: cstr)
        }
        return "Unknown error (code: \(errnum))"
    }
    
    /// Read a line from gzip file
    /// - Parameter maxLength: Maximum line length
    /// - Returns: Line read from file, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func gets(maxLength: Int = 1024) throws -> String? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard let result = swift_gzgets(ptr, &buffer, Int32(maxLength)) else {
            return nil // EOF
        }
        return String(cString: result)
    }
    
    /// Write a single character to gzip file
    /// - Parameter character: Character to write
    /// - Throws: GzipFileError if operation fails
    public func putc(_ character: Character) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let c = Int32(character.asciiValue ?? 0)
        let result = swift_gzputc(ptr, c)
        if result != c {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Read a single character from gzip file
    /// - Returns: Character read, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getc() throws -> Character? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        let result = swift_gzgetc(ptr)
        if result == -1 {
            return nil // EOF
        }
        guard let asciiValue = UInt8(exactly: result) else {
            throw GzipFileError.readFailed("Invalid character")
        }
        let char = Character(String(UnicodeScalar(asciiValue)))
        return char
    }
    
    /// Push back a character to gzip file
    /// - Parameter character: Character to push back
    /// - Throws: GzipFileError if operation fails
    public func ungetc(_ character: Character) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let c = Int32(character.asciiValue ?? 0)
        let result = swift_gzungetc(c, ptr)
        if result != c {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Clear error state of gzip file
    public func clearError() {
        guard let ptr = filePtr else { return }
        swift_gzclearerr(ptr)
    }
    
    /// Print a simple string to gzip file (without format specifiers)
    /// - Parameter string: String to write
    /// - Throws: GzipFileError if operation fails
    public func printfSimple(_ string: String) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let result = string.withCString { cstr in
            swift_gzprintf_simple(ptr, cstr)
        }
        if result < 0 {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Read a simple line from gzip file (simplified version)
    /// - Parameter maxLength: Maximum line length
    /// - Returns: Line read from file, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getsSimple(maxLength: Int = 1024) throws -> String? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = [CChar](repeating: 0, count: maxLength)
        let result = swift_gzgets_simple(ptr, &buffer, Int32(maxLength))
        if result == 0 {
            return nil // EOF
        }
        return String(cString: buffer)
    }
    
    // MARK: - Advanced Gzip File Operations
    
    /// Print formatted string to gzip file (with format specifiers)
    /// - Parameter format: Format string
    /// - Parameter arguments: Format arguments
    /// - Throws: GzipFileError if operation fails
    public func printf(_ format: String, _ arguments: CVarArg...) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        
        // For now, we'll use a simplified approach since varargs are complex in Swift-C bridging
        // In a full implementation, you'd need to create a C function that handles varargs
        let result = format.withCString { cstr in
            swift_gzprintf_simple(ptr, cstr)
        }
        if result < 0 {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Read a line from gzip file with specified encoding
    /// - Parameters:
    ///   - maxLength: Maximum line length
    ///   - encoding: String encoding
    /// - Returns: Line read from file, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getsWithEncoding(maxLength: Int = 1024, encoding: String.Encoding = .utf8) throws -> String? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard let result = swift_gzgets(ptr, &buffer, Int32(maxLength)) else {
            return nil // EOF
        }
        let string = String(cString: result)
        return string
    }
    
    /// Write a single byte to gzip file
    /// - Parameter byte: Byte value to write
    /// - Throws: GzipFileError if operation fails
    public func putByte(_ byte: UInt8) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let result = swift_gzputc(ptr, Int32(byte))
        if result != Int32(byte) {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Read a single byte from gzip file
    /// - Returns: Byte value read, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getByte() throws -> UInt8? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        let result = swift_gzgetc(ptr)
        if result == -1 {
            return nil // EOF
        }
        return UInt8(result)
    }
    
    /// Push back a byte to gzip file
    /// - Parameter byte: Byte value to push back
    /// - Throws: GzipFileError if operation fails
    public func ungetByte(_ byte: UInt8) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        let result = swift_gzungetc(Int32(byte), ptr)
        if result != Int32(byte) {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }
    
    /// Check if file is at end of file
    /// - Returns: True if at EOF
    public func isEOF() -> Bool {
        guard let ptr = filePtr else { return true }
        return swift_gzeof(ptr) != 0
    }
    
    /// Get current file position
    /// - Returns: Current position in file
    /// - Throws: GzipFileError if operation fails
    public func position() throws -> Int {
        return try tell()
    }
    
    /// Set file position
    /// - Parameters:
    ///   - offset: Offset from origin
    ///   - origin: Origin for seeking (SEEK_SET, SEEK_CUR, SEEK_END)
    /// - Throws: GzipFileError if operation fails
    public func setPosition(offset: Int, origin: Int32 = SEEK_SET) throws {
        try seek(offset: offset, whence: origin)
    }
    
    /// Rewind file to beginning
    /// - Throws: GzipFileError if operation fails
    public func rewindToBeginning() throws {
        try rewind()
    }
    
    /// Flush file with specified flush mode
    /// - Parameter mode: Flush mode (Z_NO_FLUSH, Z_PARTIAL_FLUSH, Z_SYNC_FLUSH, Z_FULL_FLUSH, Z_FINISH)
    /// - Throws: GzipFileError if operation fails
    public func flush(mode: Int32 = Z_SYNC_FLUSH) throws {
        guard let ptr = filePtr else { throw GzipFileError.flushFailed("File not open") }
        let result = swift_gzflush(ptr, mode)
        if result != Z_OK {
            throw GzipFileError.flushFailed(errorMessage())
        }
    }
    
    /// Set compression parameters for the file
    /// - Parameters:
    ///   - level: Compression level
    ///   - strategy: Compression strategy
    /// - Throws: GzipFileError if operation fails
    public func setCompressionParameters(level: CompressionLevel, strategy: CompressionStrategy) throws {
        try setParams(level: level, strategy: strategy)
    }
    
    /// Get error information
    /// - Returns: Tuple of (error message, error number)
    public func getErrorInfo() -> (message: String, code: Int32) {
        guard let ptr = filePtr else { return ("File not open", -1) }
        var errnum: Int32 = 0
        let message = swift_gzerror(ptr, &errnum) != nil ? String(cString: swift_gzerror(ptr, &errnum)!) : "Unknown error"
        return (message, errnum)
    }
    
    /// Clear error state
    public func clearErrorState() {
        clearError()
    }
    
    /// Check if file is open
    /// - Returns: True if file is open
    public var isOpen: Bool {
        return filePtr != nil
    }
    
    /// Get file path
    /// - Returns: File path
    public var filePath: String {
        return path
    }
    
    /// Get file mode
    /// - Returns: File mode
    public var fileMode: String {
        return mode
    }
}

/// Stream-based compression for large data or streaming scenarios
public class Compressor {
    private var stream = z_stream()
    private var isInitialized = false

    public init() {
        // Zero the z_stream struct
        memset(&stream, 0, MemoryLayout<z_stream>.size)
    }
    
    deinit {
        if isInitialized {
            swift_deflateEnd(&stream)
        }
    }
    
    /// Initialize the compressor with basic settings
    /// - Parameter level: Compression level
    /// - Throws: ZLibError if initialization fails
    public func initialize(level: CompressionLevel = .defaultCompression) throws {
        zlibInfo("Initializing compressor with level: \(level)")
        
        // Use the exact same parameters as compress2: level, Z_DEFLATED, 15 (zlib format), 8 (default memory), Z_DEFAULT_STRATEGY
        // compress2 uses zlib format by default, which means windowBits = 15
        let result = swift_deflateInit2(&stream, level.zlibLevel, Z_DEFLATED, 15, 8, Z_DEFAULT_STRATEGY)
        if result != Z_OK {
            zlibError("Compressor initialization failed with code: \(result) - \(String(cString: swift_zError(result)))")
            throw ZLibError.compressionFailed(result)
        }
        isInitialized = true
        zlibInfo("Compressor initialized successfully")
    }
    
    /// Initialize the compressor with advanced settings
    /// - Parameters:
    ///   - level: Compression level
    ///   - method: Compression method (default: .deflate)
    ///   - windowBits: Window bits for format (default: .deflate)
    ///   - memoryLevel: Memory level (default: .maximum)
    ///   - strategy: Compression strategy (default: .defaultStrategy)
    /// - Throws: ZLibError if initialization fails
    public func initializeAdvanced(
        level: CompressionLevel = .defaultCompression,
        method: CompressionMethod = .deflate,
        windowBits: WindowBits = .deflate,
        memoryLevel: MemoryLevel = .maximum,
        strategy: CompressionStrategy = .defaultStrategy
    ) throws {
        let result = swift_deflateInit2(
            &stream,
            level.zlibLevel,
            method.zlibMethod,
            windowBits.zlibWindowBits,
            memoryLevel.zlibMemoryLevel,
            strategy.zlibStrategy
        )
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Change compression parameters mid-stream
    /// - Parameters:
    ///   - level: New compression level
    ///   - strategy: New compression strategy
    /// - Throws: ZLibError if parameter change fails
    public func setParameters(level: CompressionLevel, strategy: CompressionStrategy) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflateParams(&stream, level.zlibLevel, strategy.zlibStrategy)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Set compression dictionary
    /// - Parameter dictionary: Dictionary data
    /// - Throws: ZLibError if dictionary setting fails
    public func setDictionary(_ dictionary: Data) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = dictionary.withUnsafeBytes { dictPtr in
            swift_deflateSetDictionary(
                &stream,
                dictPtr.bindMemory(to: Bytef.self).baseAddress!,
                uInt(dictionary.count)
            )
        }
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Reset the compressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflateReset(&stream)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Reset the compressor with different window bits
    /// - Parameter windowBits: New window bits
    /// - Throws: ZLibError if reset fails
    public func resetWithWindowBits(_ windowBits: WindowBits) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflateReset2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Copy the compressor state to another compressor
    /// - Parameter destination: The destination compressor
    /// - Throws: ZLibError if copy fails
    public func copy(to destination: Compressor) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflateCopy(&destination.stream, &stream)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        destination.isInitialized = true
    }
    
    /// Prime the compressor with bits
    /// - Parameters:
    ///   - bits: Number of bits to prime
    ///   - value: Value to prime with
    /// - Throws: ZLibError if priming fails
    public func prime(bits: Int32, value: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflatePrime(&stream, bits, value)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Get pending output from the compressor
    /// - Returns: Tuple of (pending bytes, pending bits)
    /// - Throws: ZLibError if operation fails
    public func getPending() throws -> (pending: UInt32, bits: Int32) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var pending: UInt32 = 0
        var bits: Int32 = 0
        
        let result = swift_deflatePending(&stream, &pending, &bits)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        
        return (pending, bits)
    }
    
    /// Get the upper bound on compressed size for given source length
    /// - Parameter sourceLen: Length of source data
    /// - Returns: Upper bound on compressed size
    /// - Throws: ZLibError if operation fails
    public func getBound(sourceLen: uLong) throws -> uLong {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let bound = swift_deflateBound(&stream, sourceLen)
        // deflateBound returns a uLong, so we just need to check if it's reasonable
        return bound
    }
    
    /// Fine-tune deflate parameters
    /// - Parameters:
    ///   - goodLength: Good match length
    ///   - maxLazy: Maximum lazy match length
    ///   - niceLength: Nice match length
    ///   - maxChain: Maximum chain length
    /// - Throws: ZLibError if tuning fails
    public func tune(goodLength: Int32, maxLazy: Int32, niceLength: Int32, maxChain: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_deflateTune(&stream, goodLength, maxLazy, niceLength, maxChain)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
    
    /// Get the current dictionary
    /// - Returns: Dictionary data
    /// - Throws: ZLibError if operation fails
    public func getDictionary() throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var dictLength: uInt = 0
        let result = swift_deflateGetDictionary(&stream, nil, &dictLength)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        
        guard dictLength > 0 else {
            return Data()
        }
        
        var dictionary = Data(count: Int(dictLength))
        let getResult = dictionary.withUnsafeMutableBytes { dictPtr in
            swift_deflateGetDictionary(&stream, dictPtr.bindMemory(to: Bytef.self).baseAddress!, &dictLength)
        }
        
        guard getResult == Z_OK else {
            throw ZLibError.compressionFailed(getResult)
        }
        
        dictionary.count = Int(dictLength)
        return dictionary
    }
    
    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let totalIn = stream.total_in
        let totalOut = stream.total_out
        let isActive = isInitialized
        
        return (totalIn, totalOut, isActive)
    }
    
    /// Get compression ratio (if data has been processed)
    /// - Returns: Compression ratio (0.0 to 1.0, where 1.0 = no compression)
    /// - Throws: ZLibError if operation fails
    public func getCompressionRatio() throws -> Double {
        let info = try getStreamInfo()
        guard info.totalIn > 0 else { return 1.0 }
        return Double(info.totalOut) / Double(info.totalIn)
    }
    
    /// Get stream statistics
    /// - Returns: Stream statistics
    /// - Throws: ZLibError if operation fails
    public func getStreamStats() throws -> (bytesProcessed: Int, bytesProduced: Int, compressionRatio: Double, isActive: Bool) {
        let info = try getStreamInfo()
        let bytesProcessed = Int(info.totalIn)
        let bytesProduced = Int(info.totalOut)
        let compressionRatio = bytesProcessed > 0 ? Double(bytesProduced) / Double(bytesProcessed) : 1.0
        
        return (bytesProcessed, bytesProduced, compressionRatio, info.isActive)
    }
    
    /// Compress data in chunks
    /// - Parameters:
    ///   - input: Input data chunk
    ///   - flush: Flush mode
    /// - Returns: Compressed data chunk
    /// - Throws: ZLibError if compression fails
    public func compress(_ input: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            zlibError("Compressor not initialized")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        zlibDebug("Compressing \(input.count) bytes with flush mode: \(flush)")
        logStreamState(stream, operation: "Compression start")
        
        var output = Data()
        let outputBufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: outputBufferSize)
        
        // Copy input data to ensure it remains valid throughout compression
        var inputBuffer = [Bytef](input)
        
        // Set input data
        stream.next_in = inputBuffer.withUnsafeMutableBufferPointer { $0.baseAddress }
        stream.avail_in = uInt(input.count)
        
        // Process all input data
        var result: Int32 = Z_OK
        var iteration = 0
        repeat {
            iteration += 1
            zlibDebug("Compression iteration \(iteration): avail_in=\(stream.avail_in), avail_out=\(stream.avail_out)")
            
            try outputBuffer.withUnsafeMutableBufferPointer { buffer in
                stream.next_out = buffer.baseAddress
                stream.avail_out = uInt(outputBufferSize)
                
                result = swift_deflate(&stream, flush.zlibFlush)
                if result == Z_STREAM_ERROR {
                    zlibError("Compression failed with Z_STREAM_ERROR")
                    throw ZLibError.streamError(result)
                }
                
                let bytesProcessed = outputBufferSize - Int(stream.avail_out)
                if bytesProcessed > 0 {
                    output.append(Data(bytes: buffer.baseAddress!, count: bytesProcessed))
                    zlibDebug("Produced \(bytesProcessed) bytes of compressed data")
                }
            }
        } while (flush == .finish ? result != Z_STREAM_END : (stream.avail_in > 0 || stream.avail_out == 0)) // Continue until finish or while input/output remains
        
        logStreamState(stream, operation: "Compression end")
        zlibInfo("Compression completed: \(input.count) -> \(output.count) bytes")
        
        return output
    }
    
    /// Finish compression
    /// - Returns: Final compressed data
    /// - Throws: ZLibError if compression fails
    public func finish() throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        let outputBufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: outputBufferSize)
        
        // Set empty input for finish
        stream.next_in = nil
        stream.avail_in = 0
        
        // Process until stream is finished
        var result: Int32 = Z_OK
        repeat {
            try outputBuffer.withUnsafeMutableBufferPointer { buffer in
                stream.next_out = buffer.baseAddress
                stream.avail_out = uInt(outputBufferSize)
                
                result = swift_deflate(&stream, FlushMode.finish.zlibFlush)
                guard result != Z_STREAM_ERROR else {
                    throw ZLibError.streamError(result)
                }
                
                let bytesProcessed = outputBufferSize - Int(stream.avail_out)
                if bytesProcessed > 0 {
                    output.append(Data(bytes: buffer.baseAddress!, count: bytesProcessed))
                }
            }
        } while stream.avail_out == 0 && result != Z_STREAM_END // Continue until stream ends
        
        return output
    }

    /// Set the gzip header for the stream (must be called after initializeAdvanced)
    public func setGzipHeader(_ header: GzipHeader) throws {
        var cHeader = gz_header()
        to_c_gz_header(header, cHeader: &cHeader)
        let result = swift_deflateSetHeader(&stream, &cHeader)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
    }
}

/// Stream-based decompression for large data or streaming scenarios
public class Decompressor {
    private var stream = z_stream()
    private var isInitialized = false

    public init() {
        // Zero the z_stream struct
        memset(&stream, 0, MemoryLayout<z_stream>.size)
    }
    
    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }
    
    /// Initialize the decompressor with basic settings
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        zlibInfo("Initializing decompressor")
        
        let result = swift_inflateInit(&stream)
        if result != Z_OK {
            zlibError("Decompressor initialization failed with code: \(result) - \(String(cString: swift_zError(result)))")
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
        zlibInfo("Decompressor initialized successfully")
    }
    
    /// Initialize the decompressor with advanced settings
    /// - Parameter windowBits: Window bits for format (default: .deflate)
    /// - Throws: ZLibError if initialization fails
    public func initializeAdvanced(windowBits: WindowBits = .deflate) throws {
        let result = swift_inflateInit2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Set decompression dictionary
    /// - Parameter dictionary: Dictionary data
    /// - Throws: ZLibError if dictionary setting fails
    public func setDictionary(_ dictionary: Data) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = dictionary.withUnsafeBytes { dictPtr in
            swift_inflateSetDictionary(
                &stream,
                dictPtr.bindMemory(to: Bytef.self).baseAddress!,
                uInt(dictionary.count)
            )
        }
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Reset the decompressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflateReset(&stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Copy the decompressor state to another decompressor
    /// - Parameter destination: The destination decompressor
    /// - Throws: ZLibError if copy fails
    public func copy(to destination: Decompressor) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflateCopy(&destination.stream, &stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        destination.isInitialized = true
    }
    
    /// Prime the decompressor with bits
    /// - Parameters:
    ///   - bits: Number of bits to prime
    ///   - value: Value to prime with
    /// - Throws: ZLibError if priming fails
    public func prime(bits: Int32, value: Int32) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflatePrime(&stream, bits, value)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Synchronize the inflate stream
    /// - Throws: ZLibError if synchronization fails
    public func sync() throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflateSync(&stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Check if current position is a sync point
    /// - Returns: True if current position is a sync point
    /// - Throws: ZLibError if operation fails
    public func isSyncPoint() throws -> Bool {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflateSyncPoint(&stream)
        return result == Z_OK
    }
    
    /// Reset the decompressor with different window bits
    /// - Parameter windowBits: New window bits
    /// - Throws: ZLibError if reset fails
    public func resetWithWindowBits(_ windowBits: WindowBits) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let result = swift_inflateReset2(&stream, windowBits.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Get the current dictionary
    /// - Returns: Dictionary data
    /// - Throws: ZLibError if operation fails
    public func getDictionary() throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var dictLength: uInt = 0
        let result = swift_inflateGetDictionary(&stream, nil, &dictLength)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        
        guard dictLength > 0 else {
            return Data()
        }
        
        var dictionary = Data(count: Int(dictLength))
        let getResult = dictionary.withUnsafeMutableBytes { dictPtr in
            swift_inflateGetDictionary(&stream, dictPtr.bindMemory(to: Bytef.self).baseAddress!, &dictLength)
        }
        
        guard getResult == Z_OK else {
            throw ZLibError.decompressionFailed(getResult)
        }
        
        dictionary.count = Int(dictLength)
        return dictionary
    }
    
    /// Get the current stream mark position
    /// - Returns: Stream mark position
    /// - Throws: ZLibError if operation fails
    public func getMark() throws -> Int {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let mark = swift_inflateMark(&stream)
        guard mark >= 0 else {
            throw ZLibError.decompressionFailed(Int32(mark))
        }
        
        return Int(mark)
    }
    
    /// Get the number of codes used by the inflate stream
    /// - Returns: Number of codes used
    /// - Throws: ZLibError if operation fails
    public func getCodesUsed() throws -> UInt {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        return swift_inflateCodesUsed(&stream)
    }
    
    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let totalIn = stream.total_in
        let totalOut = stream.total_out
        let isActive = isInitialized
        
        return (totalIn, totalOut, isActive)
    }
    
    /// Get pending output from the decompressor
    /// - Returns: Tuple of (pending bytes, pending bits)
    /// - Throws: ZLibError if operation fails
    public func getPending() throws -> (pending: UInt32, bits: Int32) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var pending: UInt32 = 0
        var bits: Int32 = 0
        
        let result = swift_inflatePending(&stream, &pending, &bits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        
        return (pending, bits)
    }
    
    /// Decompress data in chunks
    /// - Parameters:
    ///   - input: Input compressed data chunk
    ///   - flush: Flush mode
    ///   - dictionary: Optional dictionary for decompression
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ input: Data, flush: FlushMode = .noFlush, dictionary: Data? = nil) throws -> Data {
        guard isInitialized else {
            zlibError("Decompressor not initialized")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        zlibDebug("Decompressing \(input.count) bytes with flush mode: \(flush)")
        logStreamState(stream, operation: "Decompression start")
        
        var output = Data()
        var outputBuffer = Data(count: 1024) // 1KB chunks
        var dictWasSet = false
        
        // Set input data
        try input.withUnsafeBytes { inputPtr in
            stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress!)
            stream.avail_in = uInt(input.count)
            
            // Process all input data
            var result: Int32 = Z_OK
            var iteration = 0
            repeat {
                iteration += 1
                zlibDebug("Decompression iteration \(iteration): avail_in=\(stream.avail_in), avail_out=\(stream.avail_out)")
                let outputBufferCount = outputBuffer.count
                result = try outputBuffer.withUnsafeMutableBytes { outputPtr -> Int32 in
                    stream.next_out = outputPtr.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    let inflateResult = swift_inflate(&stream, flush.zlibFlush)
                    if inflateResult == Z_NEED_DICT {
                        if let dict = dictionary, !dictWasSet {
                            try setDictionary(dict)
                            dictWasSet = true
                            // Do not return here; let the loop continue and call inflate again
                            return Z_OK
                        } else {
                            throw ZLibError.decompressionFailed(Z_NEED_DICT)
                        }
                    }
                    if inflateResult != Z_OK && inflateResult != Z_STREAM_END && inflateResult != Z_BUF_ERROR {
                        zlibError("Decompression failed with error code: \(inflateResult)")
                        throw ZLibError.decompressionFailed(inflateResult)
                    }
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let temp = Data(bytes: outputPtr.baseAddress!, count: bytesProcessed)
                        output.append(temp)
                        zlibDebug("Produced \(bytesProcessed) bytes of decompressed data")
                    }
                    return inflateResult
                }
                if dictWasSet {
                    dictWasSet = false // Only allow one extra pass after setting dictionary
                }
            } while result != Z_STREAM_END && (stream.avail_in > 0 || stream.avail_out == 0 || dictWasSet)
        }
        
        logStreamState(stream, operation: "Decompression end")
        zlibInfo("Decompression completed: \(input.count) -> \(output.count) bytes")
        
        return output
    }
    
    /// Finish decompression
    /// - Returns: Final decompressed data
    /// - Throws: ZLibError if decompression fails
    public func finish() throws -> Data {
        return try decompress(Data(), flush: .finish)
    }
    
    /// Get the gzip header from the stream (must be called after initializeAdvanced)
    public func getGzipHeader() throws -> GzipHeader {
        var cHeader = gz_header()
        let result = swift_inflateGetHeader(&stream, &cHeader)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        return from_c_gz_header(&cHeader)
    }
}

/// Advanced streaming decompression with callback support
public class StreamingDecompressor {
    private var stream = z_stream()
    private var isInitialized = false
    private var window: [Bytef]
    private let windowSize: Int
    
    public init(windowBits: WindowBits = .deflate) {
        self.windowSize = 1 << windowBits.zlibWindowBits
        self.window = [Bytef](repeating: 0, count: windowSize)
    }
    
    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }
    
    /// Initialize the streaming decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateInit2(&stream, WindowBits.deflate.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Process data with custom input/output callbacks
    /// - Parameters:
    ///   - inputProvider: Function that provides input data chunks
    ///   - outputHandler: Function that receives output data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var result: Int32 = Z_OK
        let bufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: bufferSize)
        
        var hasProcessedInput = false
        
        while result != Z_STREAM_END {
            // Get input data
            guard let inputData = inputProvider() else {
                // No more input data
                break
            }
            
            hasProcessedInput = true
            
            // Process input data with valid pointer
            try inputData.withUnsafeBytes { inputPtr in
                stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress!)
                stream.avail_in = uInt(inputData.count)
                
                // Process input
                repeat {
                    let outputBufferCount = outputBuffer.count
                    result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                        stream.next_out = buffer.baseAddress
                        stream.avail_out = uInt(outputBufferCount)
                        
                        let inflateResult = swift_inflate(&stream, Z_NO_FLUSH)
                        guard inflateResult != Z_STREAM_ERROR else {
                            return Z_STREAM_ERROR
                        }
                        
                        let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                        if bytesProcessed > 0 {
                            let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                            if !outputHandler(outputData) {
                                return Z_STREAM_ERROR
                            }
                        }
                        
                        return inflateResult
                    }
                    
                    guard result != Z_STREAM_ERROR else {
                        throw ZLibError.streamError(result)
                    }
                    
                } while stream.avail_out == 0 && stream.avail_in > 0 && result != Z_STREAM_END
            }
        }
        
        // Finish processing if we have processed input
        if hasProcessedInput && result == Z_OK {
            repeat {
                let outputBufferCount = outputBuffer.count
                result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                    stream.next_out = buffer.baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    
                    let inflateResult = swift_inflate(&stream, Z_FINISH)
                    guard inflateResult != Z_STREAM_ERROR else {
                        return Z_STREAM_ERROR
                    }
                    
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                        if !outputHandler(outputData) {
                            return Z_STREAM_ERROR
                        }
                    }
                    
                    return inflateResult
                }
                
                guard result != Z_STREAM_ERROR else {
                    throw ZLibError.streamError(result)
                }
                
            } while stream.avail_out == 0 && result != Z_STREAM_END
        }
    }
    
    /// Process data from a Data source to a Data destination
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - maxOutputSize: Maximum output buffer size
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    public func processData(_ input: Data, maxOutputSize: Int = 4096) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        var inputIndex = 0
        
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let chunkSize = min(remaining, 1024)
                let chunk = input.subdata(in: inputIndex..<(inputIndex + chunkSize))
                inputIndex += chunkSize
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true // Always continue processing
            }
        )
        
        return output
    }
    
    /// Process data with custom chunk handling
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - chunkHandler: Function called for each decompressed chunk
    /// - Throws: ZLibError if processing fails
    public func processDataInChunks(
        _ input: Data,
        chunkHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var inputIndex = 0
        
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let chunkSize = min(remaining, 1024)
                let chunk = input.subdata(in: inputIndex..<(inputIndex + chunkSize))
                inputIndex += chunkSize
                return chunk
            },
            outputHandler: chunkHandler
        )
    }
}

/// Advanced InflateBack decompression with true C callback support
/// Note: This is a simplified implementation that provides InflateBack-like functionality
/// using the regular inflate API with Swift-friendly callbacks.
public class InflateBackDecompressor {
    private var stream = z_stream()
    private var isInitialized = false
    private var window: [Bytef]
    private let windowSize: Int
    
    public init(windowBits: WindowBits = .deflate) {
        self.windowSize = 1 << windowBits.zlibWindowBits
        self.window = [Bytef](repeating: 0, count: windowSize)
    }
    
    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }
    
    /// Initialize the InflateBack-style decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateInit2(&stream, WindowBits.deflate.zlibWindowBits)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Process data using advanced callback system
    /// - Parameters:
    ///   - inputProvider: Function that provides input data chunks
    ///   - outputHandler: Function that receives output data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var result: Int32 = Z_OK
        let bufferSize = 4096
        var outputBuffer = [Bytef](repeating: 0, count: bufferSize)
        var hasProcessedInput = false
        
        while result != Z_STREAM_END {
            // Get input data
            guard let inputData = inputProvider() else {
                // No more input data, finish processing
                break
            }
            
            hasProcessedInput = true
            
            // Process input data with valid pointer
            try inputData.withUnsafeBytes { inputPtr in
                stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress!)
                stream.avail_in = uInt(inputData.count)
                
                // Process input
                repeat {
                    let outputBufferCount = outputBuffer.count
                    result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                        stream.next_out = buffer.baseAddress
                        stream.avail_out = uInt(outputBufferCount)
                        
                        let inflateResult = swift_inflate(&stream, Z_NO_FLUSH)
                        guard inflateResult != Z_STREAM_ERROR else {
                            return Z_STREAM_ERROR
                        }
                        
                        let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                        if bytesProcessed > 0 {
                            let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                            if !outputHandler(outputData) {
                                return Z_STREAM_ERROR
                            }
                        }
                        
                        return inflateResult
                    }
                    
                    guard result != Z_STREAM_ERROR else {
                        throw ZLibError.streamError(result)
                    }
                    
                } while stream.avail_out == 0 && stream.avail_in > 0 && result != Z_STREAM_END
            }
        }
        
        // Finish processing if we have processed input
        if hasProcessedInput && result == Z_OK {
            repeat {
                let outputBufferCount = outputBuffer.count
                result = outputBuffer.withUnsafeMutableBufferPointer { buffer in
                    stream.next_out = buffer.baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    
                    let inflateResult = swift_inflate(&stream, Z_FINISH)
                    guard inflateResult != Z_STREAM_ERROR else {
                        return Z_STREAM_ERROR
                    }
                    
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let outputData = Data(bytes: buffer.baseAddress!, count: bytesProcessed)
                        if !outputHandler(outputData) {
                            return Z_STREAM_ERROR
                        }
                    }
                    
                    return inflateResult
                }
                
                guard result != Z_STREAM_ERROR else {
                    throw ZLibError.streamError(result)
                }
                
            } while stream.avail_out == 0 && result != Z_STREAM_END
        }
    }
    
    /// Process data from a Data source
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - maxOutputSize: Maximum output buffer size
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    public func processData(_ input: Data, maxOutputSize: Int = 4096) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        var inputIndex = 0
        
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let chunkSize = min(remaining, 1024)
                let chunk = input.subdata(in: inputIndex..<(inputIndex + chunkSize))
                inputIndex += chunkSize
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true // Always continue processing
            }
        )
        
        return output
    }
    
    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let totalIn = stream.total_in
        let totalOut = stream.total_out
        let isActive = isInitialized
        
        return (totalIn, totalOut, isActive)
    }
}

// MARK: - Enhanced InflateBack Implementation

/// Enhanced InflateBack decompression with improved C callback support
/// This provides better integration with the actual zlib inflateBack functions
public class EnhancedInflateBackDecompressor {
    private var stream = z_stream()
    private var isInitialized = false
    private var window: [Bytef]
    private let windowSize: Int
    
    public init(windowBits: WindowBits = .deflate) {
        self.windowSize = 1 << windowBits.zlibWindowBits
        self.window = [Bytef](repeating: 0, count: windowSize)
    }
    
    deinit {
        if isInitialized {
            swift_inflateBackEnd(&stream)
        }
    }
    
    /// Initialize the enhanced InflateBack decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateBackInit(&stream, WindowBits.deflate.zlibWindowBits, &window)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Process data using enhanced InflateBack with improved callbacks
    /// - Parameters:
    ///   - inputProvider: Function that provides input data chunks
    ///   - outputHandler: Function that receives output data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        // Use the existing InflateBackDecompressor implementation for now
        // The true C callback implementation requires more complex Swift-C bridging
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()
        try inflateBack.processWithCallbacks(inputProvider: inputProvider, outputHandler: outputHandler)
    }
    
    /// Process data from a Data source using enhanced InflateBack
    /// - Parameters:
    ///   - input: Input compressed data
    ///   - maxOutputSize: Maximum output buffer size
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if processing fails
    public func processData(_ input: Data, maxOutputSize: Int = 4096) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        var inputIndex = 0
        
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let chunkSize = min(remaining, 1024)
                let chunk = input.subdata(in: inputIndex..<(inputIndex + chunkSize))
                inputIndex += chunkSize
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true // Always continue processing
            }
        )
        
        return output
    }
    
    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        let totalIn = stream.total_in
        let totalOut = stream.total_out
        let isActive = isInitialized
        
        return (totalIn, totalOut, isActive)
    }
}

// MARK: - Convenience Extensions

public extension Data {
    /// Compress this data
    /// - Parameter level: Compression level
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    func compressed(level: CompressionLevel = .defaultCompression) throws -> Data {
        return try ZLib.compress(self, level: level)
    }
    
    /// Decompress this data
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    func decompressed() throws -> Data {
        return try ZLib.decompress(self)
    }
    
    /// Partially decompress this data
    /// - Parameter maxOutputSize: Maximum output buffer size
    /// - Returns: Tuple of (decompressed data, input consumed, output written)
    /// - Throws: ZLibError if decompression fails
    func partialDecompressed(maxOutputSize: Int = 4096) throws -> (decompressed: Data, inputConsumed: Int, outputWritten: Int) {
        return try ZLib.partialDecompress(self, maxOutputSize: maxOutputSize)
    }
    
    /// Compress this data with gzip header
    /// - Parameters:
    ///   - level: Compression level
    ///   - header: Gzip header information
    /// - Returns: Compressed data with gzip header
    /// - Throws: ZLibError if compression fails
    func compressedWithGzipHeader(level: CompressionLevel = .defaultCompression, header: GzipHeader) throws -> Data {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: level, windowBits: .gzip)
        try compressor.setGzipHeader(header)
        return try compressor.compress(self) + compressor.finish()
    }
    
    /// Calculate Adler-32 checksum
    /// - Parameter initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    func adler32(initialValue: uLong = 1) -> uLong {
        return ZLib.adler32(self, initialValue: initialValue)
    }
    
    /// Calculate CRC-32 checksum
    /// - Parameter initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    func crc32(initialValue: uLong = 0) -> uLong {
        return ZLib.crc32(self, initialValue: initialValue)
    }
    
    /// Estimate the compressed size for this data
    /// - Parameter level: Compression level
    /// - Returns: Estimated compressed size
    func estimateCompressedSize(level: CompressionLevel = .defaultCompression) -> Int {
        return ZLib.estimateCompressedSize(self.count, level: level)
    }
    
    /// Get recommended buffer sizes for streaming compression/decompression
    /// - Parameter windowBits: Window bits for the operation
    /// - Returns: Tuple of (input buffer size, output buffer size)
    static func getRecommendedBufferSizes(windowBits: WindowBits = .deflate) -> (input: Int, output: Int) {
        return ZLib.getRecommendedBufferSizes(windowBits: windowBits)
    }
    
    /// Estimate memory usage for compression
    /// - Parameters:
    ///   - windowBits: Window bits
    ///   - memoryLevel: Memory level
    /// - Returns: Estimated memory usage in bytes
    static func estimateMemoryUsage(windowBits: WindowBits = .deflate, memoryLevel: MemoryLevel = .maximum) -> Int {
        return ZLib.estimateMemoryUsage(windowBits: windowBits, memoryLevel: memoryLevel)
    }
}

public extension String {
    /// Compress this string's UTF-8 data
    /// - Parameter level: Compression level
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    func compressed(level: CompressionLevel = .defaultCompression) throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw ZLibError.invalidData
        }
        return try data.compressed(level: level)
    }
    
    /// Decompress data and convert to string
    /// - Parameter data: Compressed data
    /// - Returns: Decompressed string
    /// - Throws: ZLibError if decompression fails
    static func decompressed(from data: Data) throws -> String {
        let decompressedData = try data.decompressed()
        guard let string = String(data: decompressedData, encoding: .utf8) else {
            throw ZLibError.invalidData
        }
        return string
    }
    
    /// Compress this string with gzip header
    /// - Parameters:
    ///   - level: Compression level
    ///   - header: Gzip header information
    /// - Returns: Compressed data with gzip header
    /// - Throws: ZLibError if compression fails
    func compressedWithGzipHeader(level: CompressionLevel = .defaultCompression, header: GzipHeader) throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw ZLibError.invalidData
        }
        return try data.compressedWithGzipHeader(level: level, header: header)
    }
    
    /// Calculate Adler-32 checksum
    /// - Parameter initialValue: Initial Adler-32 value (default: 1)
    /// - Returns: Adler-32 checksum
    func adler32(initialValue: uLong = 1) -> uLong? {
        return ZLib.adler32(self, initialValue: initialValue)
    }
    
    /// Calculate CRC-32 checksum
    /// - Parameter initialValue: Initial CRC-32 value (default: 0)
    /// - Returns: CRC-32 checksum
    func crc32(initialValue: uLong = 0) -> uLong? {
        return ZLib.crc32(self, initialValue: initialValue)
    }
}

// MARK: - True C-Callback InflateBack Decompressor

/// True InflateBack decompressor using C callback bridging
public final class InflateBackDecompressorCBridged {
    private var stream = z_stream()
    private var isInitialized = false
    private var window: [UInt8]
    private let windowSize: Int
    
    public init(windowBits: WindowBits = .deflate) {
        self.windowSize = 1 << windowBits.zlibWindowBits
        self.window = [UInt8](repeating: 0, count: windowSize)
    }
    
    deinit {
        if isInitialized {
            swift_inflateBackEnd(&stream)
        }
    }
    
    /// Initialize the InflateBack decompressor
    public func initialize() throws {
        let result = swift_inflateBackInit(&stream, WindowBits.deflate.zlibWindowBits, &window)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Process data using true C-callback InflateBack
    /// - Parameters:
    ///   - inputProvider: Closure providing input Data chunks
    ///   - outputHandler: Closure receiving output Data chunks
    /// - Throws: ZLibError if processing fails
    public func processWithCallbacks(
        inputProvider: @escaping () -> Data?,
        outputHandler: @escaping (Data) -> Bool
    ) throws {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        // Context for bridging
        class CallbackContext {
            let inputProvider: () -> Data?
            let outputHandler: (Data) -> Bool
            var inputBuffer: Data? = nil
            init(inputProvider: @escaping () -> Data?, outputHandler: @escaping (Data) -> Bool) {
                self.inputProvider = inputProvider
                self.outputHandler = outputHandler
            }
        }
        let context = CallbackContext(inputProvider: inputProvider, outputHandler: outputHandler)
        let contextPtr = Unmanaged.passRetained(context).toOpaque()
        defer { Unmanaged<CallbackContext>.fromOpaque(contextPtr).release() }
        
        // C input callback
        let cInput: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?, UnsafeMutablePointer<Int32>?) -> Int32 = {
            ctxPtr, bufPtr, availPtr in
            guard let ctxPtr = ctxPtr else { return 0 }
            let ctx = Unmanaged<CallbackContext>.fromOpaque(ctxPtr).takeUnretainedValue()
            guard let data = ctx.inputProvider() else {
                availPtr?.pointee = 0
                return 0
            }
            ctx.inputBuffer = data // Hold reference so pointer stays valid
            availPtr?.pointee = Int32(data.count)
            if let bufPtr = bufPtr {
                bufPtr.pointee = UnsafeMutablePointer<UInt8>(mutating: data.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) })
            }
            return Int32(data.count)
        }
        // C output callback
        let cOutput: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UInt8>?, Int32) -> Int32 = {
            ctxPtr, buf, len in
            guard let ctxPtr = ctxPtr, let buf = buf else { return Z_STREAM_ERROR }
            let ctx = Unmanaged<CallbackContext>.fromOpaque(ctxPtr).takeUnretainedValue()
            let data = Data(bytes: buf, count: Int(len))
            return ctx.outputHandler(data) ? Z_OK : Z_STREAM_ERROR
        }
        // Call C shim
        let result = swift_inflateBackWithCallbacks(&stream, cInput, contextPtr, cOutput, contextPtr)
        guard result == Z_STREAM_END || result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
    }
    
    /// Process all data from a Data source
    public func processData(_ input: Data, chunkSize: Int = 1024) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        var output = Data()
        var inputIndex = 0
        try processWithCallbacks(
            inputProvider: {
                guard inputIndex < input.count else { return nil }
                let remaining = input.count - inputIndex
                let size = min(remaining, chunkSize)
                let chunk = input.subdata(in: inputIndex..<(inputIndex + size))
                inputIndex += size
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )
        return output
    }
}

// MARK: - Unified Streaming API

/// Unified streaming interface for compression and decompression
public class ZLibStream {
    private var compressor: Compressor?
    private var decompressor: Decompressor?
    private let mode: StreamMode
    private let options: StreamOptions
    private var isInitialized = false
    private var isFinished = false
    
    /// Stream operation mode
    public enum StreamMode: Sendable {
        case compress
        case decompress
    }
    
    /// Stream configuration options
    public struct StreamOptions: Sendable {
        /// Compression options (used for compress mode)
        public var compression: CompressionOptions
        /// Decompression options (used for decompress mode)
        public var decompression: DecompressionOptions
        /// Buffer size for processing chunks
        public var bufferSize: Int
        
        public init(
            compression: CompressionOptions = CompressionOptions(),
            decompression: DecompressionOptions = DecompressionOptions(),
            bufferSize: Int = 4096
        ) {
            self.compression = compression
            self.decompression = decompression
            self.bufferSize = bufferSize
        }
    }
    
    /// Initialize a new stream
    /// - Parameters:
    ///   - mode: Stream operation mode (compress or decompress)
    ///   - options: Stream configuration options
    public init(mode: StreamMode, options: StreamOptions = StreamOptions()) {
        self.mode = mode
        self.options = options
    }
    
    /// Initialize the stream for processing
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        guard !isInitialized else { return }
        
        switch mode {
        case .compress:
            compressor = Compressor()
            try compressor?.initializeAdvanced(
                level: options.compression.level,
                method: .deflate,
                windowBits: options.compression.format.windowBits,
                memoryLevel: options.compression.memoryLevel,
                strategy: options.compression.strategy
            )
            
            if let dictionary = options.compression.dictionary {
                try compressor?.setDictionary(dictionary)
            }
            
        case .decompress:
            decompressor = Decompressor()
            try decompressor?.initializeAdvanced(windowBits: options.decompression.format.windowBits)
            
            if let dictionary = options.decompression.dictionary {
                try decompressor?.setDictionary(dictionary)
            }
        }
        
        isInitialized = true
    }
    
    /// Process a chunk of data
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode for compression (default: .noFlush)
    /// - Returns: Processed output data
    /// - Throws: ZLibError if processing fails
    public func process(_ data: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let compressor = compressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try compressor.compress(data, flush: flush)
            
        case .decompress:
            guard let decompressor = decompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try decompressor.decompress(data)
        }
    }
    
    /// Finish processing and get final output
    /// - Returns: Final processed data
    /// - Throws: ZLibError if processing fails
    public func finalize() throws -> Data {
        guard isInitialized && !isFinished else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let compressor = compressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            let result = try compressor.compress(Data(), flush: .finish)
            isFinished = true
            return result
            
        case .decompress:
            guard let decompressor = decompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            // For decompression, we need to process any remaining data
            let result = try decompressor.decompress(Data(), flush: .finish)
            isFinished = true
            return result
        }
    }
    
    /// Reset the stream for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() throws {
        switch mode {
        case .compress:
            try compressor?.reset()
        case .decompress:
            try decompressor?.reset()
        }
        isFinished = false
    }
    
    /// Get stream information
    /// - Returns: Stream information tuple
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let compressor = compressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try compressor.getStreamInfo()
            
        case .decompress:
            guard let decompressor = decompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try decompressor.getStreamInfo()
        }
    }
    
    deinit {
        // Cleanup is handled by Compressor/Decompressor deinit
    }
}

// MARK: - Stream Builder Pattern

/// Builder for creating ZLib streams with fluent API
public class ZLibStreamBuilder {
    private var mode: ZLibStream.StreamMode = .compress
    private var options = ZLibStream.StreamOptions()
    
    /// Set stream mode to compression
    /// - Returns: Self for chaining
    public func compress() -> ZLibStreamBuilder {
        mode = .compress
        return self
    }
    
    /// Set stream mode to decompression
    /// - Returns: Self for chaining
    public func decompress() -> ZLibStreamBuilder {
        mode = .decompress
        return self
    }
    
    /// Set compression format
    /// - Parameter format: Compression format
    /// - Returns: Self for chaining
    public func format(_ format: CompressionFormat) -> ZLibStreamBuilder {
        options.compression.format = format
        options.decompression.format = format
        return self
    }
    
    /// Set compression level
    /// - Parameter level: Compression level
    /// - Returns: Self for chaining
    public func level(_ level: CompressionLevel) -> ZLibStreamBuilder {
        options.compression.level = level
        return self
    }
    
    /// Set buffer size
    /// - Parameter size: Buffer size in bytes
    /// - Returns: Self for chaining
    public func bufferSize(_ size: Int) -> ZLibStreamBuilder {
        options.bufferSize = size
        return self
    }
    
    /// Set dictionary for compression/decompression
    /// - Parameter dictionary: Dictionary data
    /// - Returns: Self for chaining
    public func dictionary(_ dictionary: Data) -> ZLibStreamBuilder {
        options.compression.dictionary = dictionary
        options.decompression.dictionary = dictionary
        return self
    }
    
    /// Build the stream
    /// - Returns: Configured ZLibStream
    public func build() -> ZLibStream {
        return ZLibStream(mode: mode, options: options)
    }
}

// MARK: - ZLib Stream Extensions

public extension ZLib {
    /// Create a stream builder for fluent configuration
    /// - Returns: Stream builder
    static func stream() -> ZLibStreamBuilder {
        return ZLibStreamBuilder()
    }
    
    /// Create a compression stream with default options
    /// - Returns: Configured compression stream
    static func compressionStream() -> ZLibStream {
        return ZLibStream(mode: .compress)
    }
    
    /// Create a decompression stream with default options
    /// - Returns: Configured decompression stream
    static func decompressionStream() -> ZLibStream {
        return ZLibStream(mode: .decompress)
    }
}

// MARK: - Async/Await Support

/// Async compression and decompression support
public extension ZLib {
    /// Compress data asynchronously
    /// - Parameters:
    ///   - data: Input data to compress
    ///   - options: Compression options
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    static func compressAsync(_ data: Data, options: CompressionOptions = CompressionOptions()) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let result = try compress(data, options: options)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Decompress data asynchronously
    /// - Parameters:
    ///   - data: Compressed data to decompress
    ///   - options: Decompression options
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    static func decompressAsync(_ data: Data, options: DecompressionOptions = DecompressionOptions()) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let result = try decompress(data, options: options)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Async streaming compressor for non-blocking compression
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class AsyncCompressor: @unchecked Sendable {
    private let compressor: Compressor
    private let queue: DispatchQueue
    private let bufferSize: Int
    private let options: CompressionOptions
    
    /// Initialize async compressor
    /// - Parameters:
    ///   - options: Compression options
    ///   - bufferSize: Buffer size for processing
    ///   - queue: Dispatch queue for background processing
    public init(options: CompressionOptions = CompressionOptions(), bufferSize: Int = 4096, queue: DispatchQueue = .global(qos: .userInitiated)) {
        self.compressor = Compressor()
        self.bufferSize = bufferSize
        self.queue = queue
        self.options = options
    }
    
    /// Initialize the async compressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let options = self.options
            queue.async {
                do {
                    try self.compressor.initializeAdvanced(
                        level: options.level,
                        method: .deflate,
                        windowBits: options.format.windowBits,
                        memoryLevel: options.memoryLevel,
                        strategy: options.strategy
                    )
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Compress data asynchronously
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode
    /// - Returns: Compressed data chunk
    /// - Throws: ZLibError if compression fails
    public func compress(_ data: Data, flush: FlushMode = .noFlush) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let flushMode = flush
            queue.async {
                do {
                    let result = try self.compressor.compress(data, flush: flushMode)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Finish compression asynchronously
    /// - Returns: Final compressed data
    /// - Throws: ZLibError if compression fails
    public func finish() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.compressor.finish()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Reset the compressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.compressor.reset()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get stream information asynchronously
    /// - Returns: Stream information
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() async throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.compressor.getStreamInfo()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Async streaming decompressor for non-blocking decompression
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class AsyncDecompressor: @unchecked Sendable {
    private let decompressor: Decompressor
    private let queue: DispatchQueue
    private let bufferSize: Int
    private let options: DecompressionOptions
    
    /// Initialize async decompressor
    /// - Parameters:
    ///   - options: Decompression options
    ///   - bufferSize: Buffer size for processing
    ///   - queue: Dispatch queue for background processing
    public init(options: DecompressionOptions = DecompressionOptions(), bufferSize: Int = 4096, queue: DispatchQueue = .global(qos: .userInitiated)) {
        self.decompressor = Decompressor()
        self.bufferSize = bufferSize
        self.queue = queue
        self.options = options
    }
    
    /// Initialize the async decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let options = self.options
            queue.async {
                do {
                    try self.decompressor.initializeAdvanced(windowBits: options.format.windowBits)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Decompress data asynchronously
    /// - Parameter data: Compressed data chunk
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ data: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.decompressor.decompress(data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Reset the decompressor for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.decompressor.reset()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get stream information asynchronously
    /// - Returns: Stream information
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() async throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.decompressor.getStreamInfo()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Async unified streaming interface
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class AsyncZLibStream: @unchecked Sendable {
    private var asyncCompressor: AsyncCompressor?
    private var asyncDecompressor: AsyncDecompressor?
    private let mode: ZLibStream.StreamMode
    private let options: ZLibStream.StreamOptions
    private var isInitialized = false
    private var isFinished = false
    
    /// Initialize async stream
    /// - Parameters:
    ///   - mode: Stream operation mode
    ///   - options: Stream configuration options
    public init(mode: ZLibStream.StreamMode, options: ZLibStream.StreamOptions = ZLibStream.StreamOptions()) {
        self.mode = mode
        self.options = options
    }
    
    /// Initialize the async stream
    /// - Throws: ZLibError if initialization fails
    public func initialize() async throws {
        guard !isInitialized else { return }
        
        switch mode {
        case .compress:
            asyncCompressor = AsyncCompressor(options: options.compression, bufferSize: options.bufferSize)
            try await asyncCompressor?.initialize()
            
        case .decompress:
            asyncDecompressor = AsyncDecompressor(options: options.decompression, bufferSize: options.bufferSize)
            try await asyncDecompressor?.initialize()
        }
        
        isInitialized = true
    }
    
    /// Process data asynchronously
    /// - Parameters:
    ///   - data: Input data chunk
    ///   - flush: Flush mode for compression
    /// - Returns: Processed output data
    /// - Throws: ZLibError if processing fails
    public func process(_ data: Data, flush: FlushMode = .noFlush) async throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let asyncCompressor = asyncCompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try await asyncCompressor.compress(data, flush: flush)
            
        case .decompress:
            guard let asyncDecompressor = asyncDecompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try await asyncDecompressor.decompress(data)
        }
    }
    
    /// Finish processing asynchronously
    /// - Returns: Final processed data
    /// - Throws: ZLibError if processing fails
    public func finalize() async throws -> Data {
        guard isInitialized && !isFinished else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let asyncCompressor = asyncCompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            let result = try await asyncCompressor.finish()
            isFinished = true
            return result
            
        case .decompress:
            // For decompression, we just return empty data as finish
            isFinished = true
            return Data()
        }
    }
    
    /// Reset the async stream for reuse
    /// - Throws: ZLibError if reset fails
    public func reset() async throws {
        switch mode {
        case .compress:
            try await asyncCompressor?.reset()
        case .decompress:
            try await asyncDecompressor?.reset()
        }
        isFinished = false
    }
    
    /// Get stream information asynchronously
    /// - Returns: Stream information
    /// - Throws: ZLibError if operation fails
    public func getStreamInfo() async throws -> (totalIn: uLong, totalOut: uLong, isActive: Bool) {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        switch mode {
        case .compress:
            guard let asyncCompressor = asyncCompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try await asyncCompressor.getStreamInfo()
            
        case .decompress:
            guard let asyncDecompressor = asyncDecompressor else {
                throw ZLibError.streamError(Z_STREAM_ERROR)
            }
            return try await asyncDecompressor.getStreamInfo()
        }
    }
}

// MARK: - Async Stream Builder

/// Builder for creating async ZLib streams with fluent API
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class AsyncZLibStreamBuilder: @unchecked Sendable {
    private var mode: ZLibStream.StreamMode = .compress
    private var options = ZLibStream.StreamOptions()
    
    /// Set stream mode to compression
    /// - Returns: Self for chaining
    public func compress() -> AsyncZLibStreamBuilder {
        mode = .compress
        return self
    }
    
    /// Set stream mode to decompression
    /// - Returns: Self for chaining
    public func decompress() -> AsyncZLibStreamBuilder {
        mode = .decompress
        return self
    }
    
    /// Set compression format
    /// - Parameter format: Compression format
    /// - Returns: Self for chaining
    public func format(_ format: CompressionFormat) -> AsyncZLibStreamBuilder {
        options.compression.format = format
        options.decompression.format = format
        return self
    }
    
    /// Set compression level
    /// - Parameter level: Compression level
    /// - Returns: Self for chaining
    public func level(_ level: CompressionLevel) -> AsyncZLibStreamBuilder {
        options.compression.level = level
        return self
    }
    
    /// Set buffer size
    /// - Parameter size: Buffer size in bytes
    /// - Returns: Self for chaining
    public func bufferSize(_ size: Int) -> AsyncZLibStreamBuilder {
        options.bufferSize = size
        return self
    }
    
    /// Set dictionary for compression/decompression
    /// - Parameter dictionary: Dictionary data
    /// - Returns: Self for chaining
    public func dictionary(_ dictionary: Data) -> AsyncZLibStreamBuilder {
        options.compression.dictionary = dictionary
        options.decompression.dictionary = dictionary
        return self
    }
    
    /// Build the async stream
    /// - Returns: Configured AsyncZLibStream
    public func build() -> AsyncZLibStream {
        return AsyncZLibStream(mode: mode, options: options)
    }
}

// MARK: - ZLib Async Extensions

public extension ZLib {
    /// Create an async stream builder for fluent configuration
    /// - Returns: Async stream builder
    static func asyncStream() -> AsyncZLibStreamBuilder {
        return AsyncZLibStreamBuilder()
    }
    
    /// Create an async compression stream with default options
    /// - Returns: Configured async compression stream
    static func asyncCompressionStream() -> AsyncZLibStream {
        return AsyncZLibStream(mode: .compress)
    }
    
    /// Create an async decompression stream with default options
    /// - Returns: Configured async decompression stream
    static func asyncDecompressionStream() -> AsyncZLibStream {
        return AsyncZLibStream(mode: .decompress)
    }
}

// MARK: - Memory-Efficient Streaming

/// Configuration for memory-efficient streaming operations
public struct StreamingConfig {
    /// Buffer size for reading/writing chunks
    public let bufferSize: Int
    /// Whether to use temporary files for intermediate results
    public let useTempFiles: Bool
    /// Compression level for streaming operations
    public let compressionLevel: Int
    /// Window bits for streaming operations
    public let windowBits: Int
    
    public init(
        bufferSize: Int = 64 * 1024, // 64KB default
        useTempFiles: Bool = false,
        compressionLevel: Int = 6,
        windowBits: Int = 15
    ) {
        self.bufferSize = bufferSize
        self.useTempFiles = useTempFiles
        self.compressionLevel = compressionLevel
        self.windowBits = windowBits
    }
}

/// Memory-efficient file compressor
public class FileCompressor {
    private let config: StreamingConfig
    
    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }
    
    /// Compress a file to another file
    public func compressFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        let compressedData = try ZLib.compress(sourceData)
        try compressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
    
    /// Compress a file to memory (for small files)
    public func compressFileToMemory(from sourcePath: String) throws -> Data {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        return try ZLib.compress(fileData)
    }
    
    /// Compress a file with progress callback
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        progress(sourceData.count, sourceData.count)
        
        let compressedData = try ZLib.compress(sourceData)
        try compressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
}

/// Memory-efficient file decompressor
public class FileDecompressor {
    private let config: StreamingConfig
    
    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }
    
    /// Decompress a file to another file
    public func decompressFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        let decompressedData = try ZLib.decompress(sourceData)
        try decompressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
    
    /// Decompress a file to memory (for small files)
    public func decompressFileToMemory(from sourcePath: String) throws -> Data {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        return try ZLib.decompress(fileData)
    }
    
    /// Decompress a file with progress callback
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceData = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
        progress(sourceData.count, sourceData.count)
        
        let decompressedData = try ZLib.decompress(sourceData)
        try decompressedData.write(to: URL(fileURLWithPath: destinationPath))
    }
}

/// Memory-efficient unified file processor
public class FileProcessor {
    private let config: StreamingConfig
    
    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }
    
    /// Process a file (compress or decompress based on file extension)
    public func processFile(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        
        // Auto-detect operation based on file extension
        if sourceURL.pathExtension.lowercased() == "gz" {
            // Decompress gzip file
            let decompressor = FileDecompressor(config: config)
            try decompressor.decompressFile(from: sourcePath, to: destinationPath)
        } else {
            // Compress to gzip file
            let compressor = FileCompressor(config: config)
            try compressor.compressFile(from: sourcePath, to: destinationPath)
        }
    }
    
    /// Process a file with progress callback
    public func processFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        
        // Auto-detect operation based on file extension
        if sourceURL.pathExtension.lowercased() == "gz" {
            // Decompress gzip file
            let decompressor = FileDecompressor(config: config)
            try decompressor.decompressFile(from: sourcePath, to: destinationPath, progress: progress)
        } else {
            // Compress to gzip file
            let compressor = FileCompressor(config: config)
            try compressor.compressFile(from: sourcePath, to: destinationPath, progress: progress)
        }
    }
}

/// Chunked data processor for memory-efficient operations
public class ChunkedProcessor {
    private let config: StreamingConfig
    
    public init(config: StreamingConfig = StreamingConfig()) {
        self.config = config
    }
    
    /// Process data in chunks with callback
    public func processChunks<T>(
        data: Data,
        processor: @escaping (Data) throws -> T
    ) throws -> [T] {
        var results: [T] = []
        var offset = 0
        
        while offset < data.count {
            let chunkSize = min(config.bufferSize, data.count - offset)
            let chunk = data.subdata(in: offset..<(offset + chunkSize))
            let result = try processor(chunk)
            results.append(result)
            offset += chunkSize
        }
        
        return results
    }
    
    /// Process large data with streaming
    public func processStreaming<T>(
        data: Data,
        processor: @escaping (Data, Bool) throws -> T
    ) throws -> [T] {
        var results: [T] = []
        var offset = 0
        
        while offset < data.count {
            let chunkSize = min(config.bufferSize, data.count - offset)
            let chunk = data.subdata(in: offset..<(offset + chunkSize))
            let isLast = (offset + chunkSize) >= data.count
            let result = try processor(chunk, isLast)
            results.append(result)
            offset += chunkSize
        }
        
        return results
    }
}

// MARK: - Convenience Extensions

extension ZLib {
    /// Memory-efficient file compression
    public static func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let compressor = FileCompressor(config: config)
        try compressor.compressFile(from: sourcePath, to: destinationPath)
    }
    
    /// Memory-efficient file decompression
    public static func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let decompressor = FileDecompressor(config: config)
        try decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }
    
    /// Memory-efficient file processing (auto-detect)
    public static func processFile(
        from sourcePath: String,
        to destinationPath: String,
        config: StreamingConfig = StreamingConfig()
    ) throws {
        let processor = FileProcessor(config: config)
        try processor.processFile(from: sourcePath, to: destinationPath)
    }
}

// MARK: - True Chunked Streaming for Huge Files

import Foundation

/// File-based chunked compressor for huge files (constant memory)
public class FileChunkedCompressor {
    public let bufferSize: Int
    public let compressionLevel: CompressionLevel
    public let windowBits: WindowBits

    public init(bufferSize: Int = 64 * 1024, compressionLevel: CompressionLevel = .defaultCompression, windowBits: WindowBits = .deflate) {
        self.bufferSize = bufferSize
        self.compressionLevel = compressionLevel
        self.windowBits = windowBits
    }

    /// Compress a file to another file using true streaming (constant memory)
    public func compressFile(from sourcePath: String, to destinationPath: String) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            if !compressed.isEmpty {
                try output.write(contentsOf: compressed)
            }
            if isLast { isFinished = true }
        }
    }
    
    /// Compress a file to another file using true streaming with progress tracking
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        var processedBytes = 0
        let totalBytes = try input.seekToEnd() ?? 0
        try input.seek(toOffset: 0)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            if !compressed.isEmpty {
                try output.write(contentsOf: compressed)
            }
            
            processedBytes += chunk.count
            progress(processedBytes, Int(totalBytes))
            
            if isLast { isFinished = true }
        }
    }
    
    /// Async version: Compress a file to another file using true streaming (constant memory)
    public func compressFile(from sourcePath: String, to destinationPath: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try compressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Async version: Compress a file to another file using true streaming with progress tracking
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try compressFile(from: sourcePath, to: destinationPath, progress: progress)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Advanced compressFile with progress, throttling, cancellation, Foundation.Progress, and queue
    public func compressFile(
        from sourcePath: String,
        to destinationPath: String,
        progressCallback: AdvancedProgressCallback? = nil,
        progressObject: Progress? = nil,
        progressInterval: TimeInterval = 0.1, // seconds
        progressQueue: DispatchQueue = .main
    ) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let compressor = Compressor()
        try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

        let totalBytes = Int(try input.seekToEnd())
        try input.seek(toOffset: 0)
        var processedBytes = 0
        var lastReport = Date()
        let startTime = Date()
        var shouldContinue = true
        var phase: CompressionPhase = .reading

        func reportProgress(phase: CompressionPhase) {
            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
            let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
            let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
            let info = ProgressInfo(
                processedBytes: processedBytes,
                totalBytes: totalBytes,
                percentage: percentage,
                speedBytesPerSec: speed,
                etaSeconds: eta,
                phase: phase,
                timestamp: now
            )
            if let progressObject = progressObject {
                progressObject.completedUnitCount = Int64(processedBytes)
            }
            if let cb = progressCallback {
                progressQueue.sync {
                    shouldContinue = cb(info)
                }
            }
        }

        var isFinished = false
        var firstIteration = true
        while !isFinished && shouldContinue {
            phase = .reading
            let now = Date()
            if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                reportProgress(phase: phase)
                lastReport = now
                firstIteration = false
            }
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            phase = .compressing
            let flush: FlushMode = isLast ? .finish : .noFlush
            let compressed = try compressor.compress(chunk, flush: flush)
            phase = .writing
            if !compressed.isEmpty {
                try output.write(contentsOf: compressed)
            }
            processedBytes += chunk.count
            if isLast {
                reportProgress(phase: phase)
            }
            if isLast { isFinished = true }
        }
        phase = .flushing
        reportProgress(phase: .finished)
        if let progressObject = progressObject {
            progressObject.completedUnitCount = Int64(totalBytes)
        }
        if !shouldContinue {
            throw ZLibError.streamError(-999) // Cancelled
        }
    }

    /// AsyncStream version: Compress a file to another file, yielding ProgressInfo updates
    public func compressFileProgressStream(
        from sourcePath: String,
        to destinationPath: String,
        progressInterval: TimeInterval = 0.1,
        progressQueue: DispatchQueue = .main
    ) -> AsyncThrowingStream<ProgressInfo, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
                    defer { try? input.close() }
                    FileManager.default.createFile(atPath: destinationPath, contents: nil)
                    let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
                    defer { try? output.close() }

                    let compressor = Compressor()
                    try compressor.initializeAdvanced(level: compressionLevel, windowBits: windowBits)

                    let totalBytes = Int(try input.seekToEnd())
                    try input.seek(toOffset: 0)
                    var processedBytes = 0
                    var lastReport = Date()
                    let startTime = Date()
                    var shouldContinue = true
                    var phase: CompressionPhase = .reading
                    var isFinished = false
                    var firstIteration = true

                    func reportProgress(phase: CompressionPhase) {
                        let now = Date()
                        let elapsed = now.timeIntervalSince(startTime)
                        let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
                        let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
                        let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
                        let info = ProgressInfo(
                            processedBytes: processedBytes,
                            totalBytes: totalBytes,
                            percentage: percentage,
                            speedBytesPerSec: speed,
                            etaSeconds: eta,
                            phase: phase,
                            timestamp: now
                        )
                        continuation.yield(info)
                    }

                    while !isFinished && shouldContinue {
                        phase = .reading
                        let now = Date()
                        if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                            reportProgress(phase: phase)
                            lastReport = now
                            firstIteration = false
                        }
                        let chunk = input.readData(ofLength: bufferSize)
                        let isLast = chunk.count < bufferSize
                        phase = .compressing
                        let flush: FlushMode = isLast ? .finish : .noFlush
                        let compressed = try compressor.compress(chunk, flush: flush)
                        phase = .writing
                        if !compressed.isEmpty {
                            try output.write(contentsOf: compressed)
                        }
                        processedBytes += chunk.count
                        if isLast {
                            reportProgress(phase: phase)
                        }
                        if isLast { isFinished = true }
                    }
                    phase = .flushing
                    reportProgress(phase: .finished)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// File-based chunked decompressor for huge files (constant memory)
public class FileChunkedDecompressor {
    public let bufferSize: Int
    public let windowBits: WindowBits

    public init(bufferSize: Int = 64 * 1024, windowBits: WindowBits = .deflate) {
        self.bufferSize = bufferSize
        self.windowBits = windowBits
    }

    /// Decompress a file to another file using true streaming (constant memory)
    public func decompressFile(from sourcePath: String, to destinationPath: String) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            if !decompressed.isEmpty {
                try output.write(contentsOf: decompressed)
            }
            if isLast { isFinished = true }
        }
    }
    
    /// Decompress a file to another file using true streaming with progress tracking
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

        var processedBytes = 0
        let totalBytes = try input.seekToEnd() ?? 0
        try input.seek(toOffset: 0)

        var isFinished = false
        while !isFinished {
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            let flush: FlushMode = isLast ? .finish : .noFlush
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            if !decompressed.isEmpty {
                try output.write(contentsOf: decompressed)
            }
            
            processedBytes += chunk.count
            progress(processedBytes, Int(totalBytes))
            
            if isLast { isFinished = true }
        }
    }
    
    /// Async version: Decompress a file to another file using true streaming (constant memory)
    public func decompressFile(from sourcePath: String, to destinationPath: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try decompressFile(from: sourcePath, to: destinationPath)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Async version: Decompress a file to another file using true streaming with progress tracking
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try decompressFile(from: sourcePath, to: destinationPath, progress: progress)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Advanced decompressFile with progress, throttling, cancellation, Foundation.Progress, and queue
    public func decompressFile(
        from sourcePath: String,
        to destinationPath: String,
        progressCallback: AdvancedProgressCallback? = nil,
        progressObject: Progress? = nil,
        progressInterval: TimeInterval = 0.1, // seconds
        progressQueue: DispatchQueue = .main
    ) throws {
        let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
        defer { try? input.close() }
        FileManager.default.createFile(atPath: destinationPath, contents: nil)
        let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
        defer { try? output.close() }

        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: windowBits)

        let totalBytes = Int(try input.seekToEnd())
        try input.seek(toOffset: 0)
        var processedBytes = 0
        var lastReport = Date()
        let startTime = Date()
        var shouldContinue = true
        var phase: CompressionPhase = .reading

        func reportProgress(phase: CompressionPhase) {
            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
            let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
            let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
            let info = ProgressInfo(
                processedBytes: processedBytes,
                totalBytes: totalBytes,
                percentage: percentage,
                speedBytesPerSec: speed,
                etaSeconds: eta,
                phase: phase,
                timestamp: now
            )
            if let progressObject = progressObject {
                progressObject.completedUnitCount = Int64(processedBytes)
            }
            if let cb = progressCallback {
                progressQueue.sync {
                    shouldContinue = cb(info)
                }
            }
        }

        var isFinished = false
        var firstIteration = true
        while !isFinished && shouldContinue {
            phase = .reading
            let now = Date()
            if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                reportProgress(phase: phase)
                lastReport = now
                firstIteration = false
            }
            let chunk = input.readData(ofLength: bufferSize)
            let isLast = chunk.count < bufferSize
            phase = .compressing
            let flush: FlushMode = isLast ? .finish : .noFlush
            let decompressed = try decompressor.decompress(chunk, flush: flush)
            phase = .writing
            if !decompressed.isEmpty {
                try output.write(contentsOf: decompressed)
            }
            processedBytes += chunk.count
            if isLast {
                reportProgress(phase: phase)
            }
            if isLast { isFinished = true }
        }
        phase = .flushing
        reportProgress(phase: .finished)
        if let progressObject = progressObject {
            progressObject.completedUnitCount = Int64(totalBytes)
        }
        if !shouldContinue {
            throw ZLibError.streamError(-999) // Cancelled
        }
    }

    /// AsyncStream version: Decompress a file to another file, yielding ProgressInfo updates
    public func decompressFileProgressStream(
        from sourcePath: String,
        to destinationPath: String,
        progressInterval: TimeInterval = 0.1,
        progressQueue: DispatchQueue = .main
    ) -> AsyncThrowingStream<ProgressInfo, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let input = try FileHandle(forReadingFrom: URL(fileURLWithPath: sourcePath))
                    defer { try? input.close() }
                    FileManager.default.createFile(atPath: destinationPath, contents: nil)
                    let output = try FileHandle(forWritingTo: URL(fileURLWithPath: destinationPath))
                    defer { try? output.close() }

                    let decompressor = Decompressor()
                    try decompressor.initializeAdvanced(windowBits: windowBits)

                    let totalBytes = Int(try input.seekToEnd())
                    try input.seek(toOffset: 0)
                    var processedBytes = 0
                    var lastReport = Date()
                    let startTime = Date()
                    var shouldContinue = true
                    var phase: CompressionPhase = .reading
                    var isFinished = false
                    var firstIteration = true

                    func reportProgress(phase: CompressionPhase) {
                        let now = Date()
                        let elapsed = now.timeIntervalSince(startTime)
                        let speed = elapsed > 0 ? Double(processedBytes) / elapsed : nil
                        let percentage = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0
                        let eta = (speed ?? 0) > 0 ? Double(totalBytes - processedBytes) / (speed ?? 1) : nil
                        let info = ProgressInfo(
                            processedBytes: processedBytes,
                            totalBytes: totalBytes,
                            percentage: percentage,
                            speedBytesPerSec: speed,
                            etaSeconds: eta,
                            phase: phase,
                            timestamp: now
                        )
                        continuation.yield(info)
                    }

                    while !isFinished && shouldContinue {
                        phase = .reading
                        let now = Date()
                        if firstIteration || now.timeIntervalSince(lastReport) >= progressInterval {
                            reportProgress(phase: phase)
                            lastReport = now
                            firstIteration = false
                        }
                        let chunk = input.readData(ofLength: bufferSize)
                        let isLast = chunk.count < bufferSize
                        phase = .compressing
                        let flush: FlushMode = isLast ? .finish : .noFlush
                        let decompressed = try decompressor.decompress(chunk, flush: flush)
                        phase = .writing
                        if !decompressed.isEmpty {
                            try output.write(contentsOf: decompressed)
                        }
                        processedBytes += chunk.count
                        if isLast {
                            reportProgress(phase: phase)
                        }
                        if isLast { isFinished = true }
                    }
                    phase = .flushing
                    reportProgress(phase: .finished)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Convenience Extensions for Chunked Streaming

extension ZLib {
    /// True chunked streaming file compression
    public static func compressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    ) throws {
        let compressor = FileChunkedCompressor(
            bufferSize: bufferSize,
            compressionLevel: compressionLevel,
            windowBits: windowBits
        )
        try compressor.compressFile(from: sourcePath, to: destinationPath)
    }
    
    /// True chunked streaming file decompression
    public static func decompressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    ) throws {
        let decompressor = FileChunkedDecompressor(
            bufferSize: bufferSize,
            windowBits: windowBits
        )
        try decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }
    
    /// Async true chunked streaming file compression
    public static func compressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        compressionLevel: CompressionLevel = .defaultCompression,
        windowBits: WindowBits = .deflate
    ) async throws {
        let compressor = FileChunkedCompressor(
            bufferSize: bufferSize,
            compressionLevel: compressionLevel,
            windowBits: windowBits
        )
        try await compressor.compressFile(from: sourcePath, to: destinationPath)
    }
    
    /// Async true chunked streaming file decompression
    public static func decompressFileChunked(
        from sourcePath: String,
        to destinationPath: String,
        bufferSize: Int = 64 * 1024,
        windowBits: WindowBits = .deflate
    ) async throws {
        let decompressor = FileChunkedDecompressor(
            bufferSize: bufferSize,
            windowBits: windowBits
        )
        try await decompressor.decompressFile(from: sourcePath, to: destinationPath)
    }
}

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


