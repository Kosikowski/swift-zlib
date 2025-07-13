import Foundation
import CZLib

// MARK: - Core Types and Enums

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

public enum CompressionLevel: Int32, Sendable {
    case noCompression = 0
    case bestSpeed = 1
    case bestCompression = 9
    case defaultCompression = -1
    public var zlibLevel: Int32 { self.rawValue }
}

public enum CompressionMethod: Int32 {
    case deflate = 8
    public var zlibMethod: Int32 { self.rawValue }
}

public enum WindowBits: Int32, Sendable {
    case deflate = 15
    case gzip = 31
    case raw = -15
    case auto = 47
    public var zlibWindowBits: Int32 { self.rawValue }
}

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
    public var zlibMemoryLevel: Int32 { self.rawValue }
}

public enum CompressionStrategy: Int32, Sendable {
    case defaultStrategy = 0
    case filtered = 1
    case huffmanOnly = 2
    case rle = 3
    case fixed = 4
    public var zlibStrategy: Int32 { self.rawValue }
}

public enum FlushMode: Int32, Sendable {
    case noFlush = 0
    case partialFlush = 1
    case syncFlush = 2
    case fullFlush = 3
    case finish = 4
    case block = 5
    case trees = 6
    public var zlibFlush: Int32 { self.rawValue }
}

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
    public var description: String { String(cString: swift_zError(self.rawValue)) }
    public var isError: Bool { self.rawValue < 0 }
    public var isSuccess: Bool { self.rawValue >= 0 }
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
