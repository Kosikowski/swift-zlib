//
//  GzipHeader.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import CZLib
import Foundation

// MARK: - GzipHeader

/// Swifty representation of a gzip header (gz_header)
public struct GzipHeader: Sendable {
    // MARK: Properties

    /// Text flag (1 if file is ASCII text)
    public var text: Int32 = 0
    /// Modification time (Unix timestamp)
    public var time: UInt32 = 0
    /// Extra flags
    public var xflags: Int32 = 0
    /// Operating system (0 = FAT, 3 = Unix, etc.)
    public var os: Int32 = 255
    /// Extra field data
    public var extra: Data? = nil
    /// Original filename
    public var name: String? = nil
    /// File comment
    public var comment: String? = nil
    /// Header CRC flag
    public var hcrc: Int32 = 0
    /// Header completion flag
    public var done: Int32 = 0

    // MARK: Lifecycle

    /// Initialize a new gzip header with default values
    public init() {}
}

/// Convert Swift GzipHeader to C gz_header
/// - Parameters:
///   - swift: Swift gzip header
///   - cHeader: C gzip header pointer
func to_c_gz_header(_ swift: GzipHeader, cHeader: UnsafeMutablePointer<gz_header>) {
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

/// Convert C gz_header to Swift GzipHeader
/// - Parameter cHeader: C gzip header pointer
/// - Returns: Swift gzip header
func from_c_gz_header(_ cHeader: UnsafePointer<gz_header>) -> GzipHeader {
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
