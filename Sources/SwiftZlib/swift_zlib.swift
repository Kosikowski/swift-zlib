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
public enum CompressionLevel: Int32 {
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
public enum WindowBits: Int32 {
    case deflate = 15      // Standard deflate format
    case gzip = 31         // Gzip format (16 + 15)
    case raw = -15         // Raw deflate format (no header/trailer)
    case auto = 47         // Auto-detect gzip or deflate (32 + 15)
    
    public var zlibWindowBits: Int32 {
        return self.rawValue
    }
}

/// Memory levels for compression
public enum MemoryLevel: Int32 {
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
public enum CompressionStrategy: Int32 {
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
public enum FlushMode: Int32 {
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
public struct GzipHeader {
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
                
                while retryResult == Z_BUF_ERROR && bufferMultiplier <= 512 {
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
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ input: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            zlibError("Decompressor not initialized")
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        zlibDebug("Decompressing \(input.count) bytes with flush mode: \(flush)")
        logStreamState(stream, operation: "Decompression start")
        
        var output = Data()
        var outputBuffer = Data(count: 1024) // 1KB chunks
        
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
                    if inflateResult == Z_STREAM_ERROR {
                        zlibError("Decompression failed with Z_STREAM_ERROR")
                        throw ZLibError.streamError(inflateResult)
                    }
                    
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let temp = Data(bytes: outputPtr.baseAddress!, count: bytesProcessed)
                        output.append(temp)
                        zlibDebug("Produced \(bytesProcessed) bytes of decompressed data")
                    }
                    
                    return inflateResult
                }
            } while stream.avail_out == 0 && stream.avail_in > 0 && result != Z_STREAM_END // Continue while output buffer is full or input remains or until stream ends
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
