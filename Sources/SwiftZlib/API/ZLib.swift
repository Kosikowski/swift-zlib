//
//  ZLib.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import CZLib
import Foundation

/// High-level ZLib compression and decompression
public enum ZLib {
    // MARK: Nested Types

    /// ZLib compile flags breakdown
    public struct ZLibCompileFlags {
        // MARK: Properties

        public let flags: UInt

        // MARK: Computed Properties

        /// ZLib version
        public var version: String {
            ZLib.version
        }

        /// Size of unsigned int
        public var sizeOfUInt: Int {
            Int((flags >> 0) & 0xFF)
        }

        /// Size of unsigned long
        public var sizeOfULong: Int {
            Int((flags >> 8) & 0xFF)
        }

        /// Size of pointer
        public var sizeOfPointer: Int {
            Int((flags >> 16) & 0xFF)
        }

        /// Size of z_off_t
        public var sizeOfZOffT: Int {
            Int((flags >> 24) & 0xFF)
        }

        /// Compiler flags
        public var compilerFlags: UInt {
            (flags >> 32) & 0xFFFF
        }

        /// Library flags
        public var libraryFlags: UInt {
            (flags >> 48) & 0xFFFF
        }

        /// Is debug build
        public var isDebug: Bool {
            (flags & 0x1000_0000_0000_0000) != 0
        }

        /// Is optimized build
        public var isOptimized: Bool {
            (flags & 0x2000_0000_0000_0000) != 0
        }

        // MARK: Lifecycle

        public init(flags: UInt) {
            self.flags = flags
        }
    }

    // MARK: Static Computed Properties

    /// Get the ZLib version string
    public static var version: String {
        String(cString: swift_zlibVersion())
    }

    /// Get ZLib compile flags
    public static var compileFlags: UInt {
        swift_zlibCompileFlags()
    }

    /// Get detailed ZLib compile flags information
    public static var compileFlagsInfo: ZLibCompileFlags {
        ZLibCompileFlags(flags: compileFlags)
    }

    // MARK: Static Functions

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
        code >= 0
    }

    /// Check if a zlib return code indicates an error
    /// - Parameter code: The zlib return code
    /// - Returns: True if the code indicates an error
    public static func isError(_ code: Int32) -> Bool {
        code < 0
    }

    /// Get a human-readable error message for a zlib error code
    /// - Parameter code: The zlib error code
    /// - Returns: Human-readable error message
    public static func getErrorMessage(_ code: Int32) -> String {
        String(cString: swift_zError(code))
    }

    /// Check if an error is recoverable
    /// - Parameter errorCode: The zlib error code
    /// - Returns: True if the error is recoverable
    public static func isRecoverableError(_ errorCode: Int32) -> Bool {
        switch errorCode {
            case Z_BUF_ERROR,
                 Z_NEED_DICT:
                true
            case Z_STREAM_ERROR,
                 Z_DATA_ERROR,
                 Z_MEM_ERROR,
                 Z_VERSION_ERROR:
                false
            default:
                false
        }
    }

    /// Get error recovery suggestions
    /// - Parameter errorCode: The zlib error code
    /// - Returns: Array of recovery suggestions
    public static func getErrorRecoverySuggestions(_ errorCode: Int32) -> [String] {
        switch errorCode {
            case Z_BUF_ERROR:
                [
                    "Increase output buffer size",
                    "Check if input data is complete",
                    "Ensure sufficient memory is available",
                ]

            case Z_NEED_DICT:
                [
                    "Provide a dictionary for decompression",
                    "Use setDictionary() method",
                    "Check if compressed data requires a dictionary",
                ]

            case Z_STREAM_ERROR:
                [
                    "Reinitialize the stream",
                    "Check stream parameters",
                    "Ensure proper initialization order",
                ]

            case Z_DATA_ERROR:
                [
                    "Check input data integrity",
                    "Verify compression format",
                    "Ensure data is not corrupted",
                ]

            case Z_MEM_ERROR:
                [
                    "Free up system memory",
                    "Reduce compression level",
                    "Use smaller buffer sizes",
                ]

            case Z_VERSION_ERROR:
                [
                    "Update zlib library",
                    "Check version compatibility",
                    "Recompile with compatible zlib version",
                ]

            default:
                ["Unknown error - check zlib documentation"]
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
    )
        -> [String]
    {
        var warnings: [String] = []

        if level == .bestCompression, memoryLevel == .minimum {
            warnings.append("Best compression with minimum memory may be slow")
        }

        if windowBits == .raw, level != .noCompression {
            warnings.append("Raw format with compression may not work as expected")
        }

        if strategy == .huffmanOnly, level == .noCompression {
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
        let inputBuffer = min(4096, windowSize / 4) // 4KB or window size / 4
        let outputBuffer = min(8192, windowSize / 2) // 8KB or window size / 2
        return (inputBuffer, outputBuffer)
    }

    /// Calculate memory usage for a compression operation
    /// - Parameters:
    ///   - windowBits: Window bits
    ///   - memoryLevel: Memory level
    /// - Returns: Estimated memory usage in bytes
    public static func estimateMemoryUsage(windowBits: WindowBits = .deflate, memoryLevel: MemoryLevel = .maximum) -> Int {
        let windowSize = 1 << windowBits.zlibWindowBits
        let memorySize = 1 << (memoryLevel.zlibMemoryLevel + 6) // 2^(memLevel + 6)
        return windowSize + memorySize
    }

    /// Get optimal compression parameters for given data size
    /// - Parameter dataSize: Size of data to compress
    /// - Returns: Tuple of recommended parameters
    public static func getOptimalParameters(for dataSize: Int) -> (level: CompressionLevel, windowBits: WindowBits, memoryLevel: MemoryLevel, strategy: CompressionStrategy) {
        if dataSize < 1024 {
            // Small data: fast compression
            (.bestSpeed, .deflate, .level3, .defaultStrategy)
        } else if dataSize < 1024 * 1024 {
            // Medium data: balanced
            (.defaultCompression, .deflate, .level6, .defaultStrategy)
        } else {
            // Large data: best compression
            (.bestCompression, .deflate, .maximum, .defaultStrategy)
        }
    }

    /// Get performance profile for different compression levels
    /// - Parameter dataSize: Size of data to compress
    /// - Returns: Array of performance profiles
    public static func getPerformanceProfiles(for dataSize: Int) -> [(level: CompressionLevel, estimatedTime: Double, estimatedRatio: Double)] {
        let baseTime = Double(dataSize) / 1_000_000.0 // Rough estimate

        return [
            (.noCompression, baseTime * 0.1, 1.0),
            (.bestSpeed, baseTime * 0.3, 0.8),
            (.defaultCompression, baseTime * 0.6, 0.7),
            (.bestCompression, baseTime * 1.2, 0.6),
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

                while retryResult == Z_BUF_ERROR, bufferMultiplier <= maxMultiplier {
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
        guard maxOutputSize > 0 else {
            throw ZLibError.invalidData
        }

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

            while retryResult == Z_BUF_ERROR, bufferMultiplier <= 16 {
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
        swift_adler32_combine(adler1, adler2, len2)
    }

    /// Combine two CRC-32 checksums
    /// - Parameters:
    ///   - crc1: First CRC-32 checksum
    ///   - crc2: Second CRC-32 checksum
    ///   - len2: Length of the second data block
    /// - Returns: Combined CRC-32 checksum
    public static func crc32Combine(_ crc1: uLong, _ crc2: uLong, len2: Int) -> uLong {
        swift_crc32_combine(crc1, crc2, len2)
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
                try compressor.setGzipHeader(header)
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
