import Foundation
import CZLib

/// Errors that can occur during ZLib operations
public enum ZLibError: Error, LocalizedError {
    case compressionFailed(Int32)
    case decompressionFailed(Int32)
    case invalidData
    case memoryError
    case streamError(Int32)
    case versionMismatch
    
    public var errorDescription: String? {
        switch self {
        case .compressionFailed(let code):
            return "Compression failed with code: \(code)"
        case .decompressionFailed(let code):
            return "Decompression failed with code: \(code)"
        case .invalidData:
            return "Invalid data provided"
        case .memoryError:
            return "Memory allocation error"
        case .streamError(let code):
            return "Stream operation failed with code: \(code)"
        case .versionMismatch:
            return "ZLib version mismatch"
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

/// High-level ZLib compression and decompression
public struct ZLib {
    
    /// Get the ZLib version string
    public static var version: String {
        return String(cString: swift_zlibVersion())
    }
    
    /// Compress data with the specified compression level
    /// - Parameters:
    ///   - data: The data to compress
    ///   - level: The compression level (default: .defaultCompression)
    /// - Returns: Compressed data
    /// - Throws: ZLibError if compression fails
    public static func compress(_ data: Data, level: CompressionLevel = .defaultCompression) throws -> Data {
        let sourceLen = uLong(data.count)
        var destLen = swift_compressBound(sourceLen)
        
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
        
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        
        compressedData.count = Int(destLen)
        return compressedData
    }
    
    /// Decompress data
    /// - Parameter data: The compressed data to decompress
    /// - Returns: Decompressed data
    /// - Throws: ZLibError if decompression fails
    public static func decompress(_ data: Data) throws -> Data {
        // For decompression, we need to estimate the output size
        // Start with a reasonable guess and grow if needed
        var destLen = uLong(data.count * 4) // Initial guess
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
        
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        
        decompressedData.count = Int(destLen)
        return decompressedData
    }
}

/// Stream-based compression for large data or streaming scenarios
public class Compressor {
    private var stream = z_stream()
    private var isInitialized = false
    
    deinit {
        if isInitialized {
            swift_deflateEnd(&stream)
        }
    }
    
    /// Initialize the compressor
    /// - Parameter level: Compression level
    /// - Throws: ZLibError if initialization fails
    public func initialize(level: CompressionLevel = .defaultCompression) throws {
        let result = swift_deflateInit(&stream, level.zlibLevel)
        guard result == Z_OK else {
            throw ZLibError.compressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Compress data in chunks
    /// - Parameters:
    ///   - input: Input data chunk
    ///   - flush: Flush mode
    /// - Returns: Compressed data chunk
    /// - Throws: ZLibError if compression fails
    public func compress(_ input: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        var outputBuffer = Data(count: 1024) // 1KB chunks
        
        // Set input data
        try input.withUnsafeBytes { inputPtr in
            stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress!)
            stream.avail_in = uInt(input.count)
            
            // Process all input data
            while stream.avail_in > 0 {
                let outputBufferCount = outputBuffer.count
                let _ = try outputBuffer.withUnsafeMutableBytes { outputPtr -> Int32 in
                    stream.next_out = outputPtr.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    
                    let result = swift_deflate(&stream, flush.zlibFlush)
                    guard result != Z_STREAM_ERROR else {
                        throw ZLibError.streamError(result)
                    }
                    
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let temp = Data(bytes: outputPtr.baseAddress!, count: bytesProcessed)
                        output.append(temp)
                    }
                    
                    return result
                }
            }
        }
        
        return output
    }
    
    /// Finish compression
    /// - Returns: Final compressed data
    /// - Throws: ZLibError if compression fails
    public func finish() throws -> Data {
        return try compress(Data(), flush: .finish)
    }
}

/// Stream-based decompression for large data or streaming scenarios
public class Decompressor {
    private var stream = z_stream()
    private var isInitialized = false
    
    deinit {
        if isInitialized {
            swift_inflateEnd(&stream)
        }
    }
    
    /// Initialize the decompressor
    /// - Throws: ZLibError if initialization fails
    public func initialize() throws {
        let result = swift_inflateInit(&stream)
        guard result == Z_OK else {
            throw ZLibError.decompressionFailed(result)
        }
        isInitialized = true
    }
    
    /// Decompress data in chunks
    /// - Parameters:
    ///   - input: Input compressed data chunk
    ///   - flush: Flush mode
    /// - Returns: Decompressed data chunk
    /// - Throws: ZLibError if decompression fails
    public func decompress(_ input: Data, flush: FlushMode = .noFlush) throws -> Data {
        guard isInitialized else {
            throw ZLibError.streamError(Z_STREAM_ERROR)
        }
        
        var output = Data()
        var outputBuffer = Data(count: 1024) // 1KB chunks
        
        // Set input data
        try input.withUnsafeBytes { inputPtr in
            stream.next_in = UnsafeMutablePointer(mutating: inputPtr.bindMemory(to: Bytef.self).baseAddress!)
            stream.avail_in = uInt(input.count)
            
            // Process all input data
            while stream.avail_in > 0 {
                let outputBufferCount = outputBuffer.count
                let _ = try outputBuffer.withUnsafeMutableBytes { outputPtr -> Int32 in
                    stream.next_out = outputPtr.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBufferCount)
                    
                    let result = swift_inflate(&stream, flush.zlibFlush)
                    guard result != Z_STREAM_ERROR else {
                        throw ZLibError.streamError(result)
                    }
                    
                    let bytesProcessed = outputBufferCount - Int(stream.avail_out)
                    if bytesProcessed > 0 {
                        let temp = Data(bytes: outputPtr.baseAddress!, count: bytesProcessed)
                        output.append(temp)
                    }
                    
                    return result
                }
            }
        }
        
        return output
    }
    
    /// Finish decompression
    /// - Returns: Final decompressed data
    /// - Throws: ZLibError if decompression fails
    public func finish() throws -> Data {
        return try decompress(Data(), flush: .finish)
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
}
