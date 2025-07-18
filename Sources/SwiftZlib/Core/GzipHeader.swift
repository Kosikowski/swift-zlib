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
/// - Returns: Tuple of allocated pointers (extra, name, comment) for cleanup
func to_c_gz_header(_ swift: GzipHeader, cHeader: UnsafeMutablePointer<gz_header>) -> (extra: UnsafeMutablePointer<Bytef>?, name: UnsafeMutablePointer<CChar>?, comment: UnsafeMutablePointer<CChar>?) {
    cHeader.pointee.text = swift.text
    cHeader.pointee.time = uLong(swift.time)
    cHeader.pointee.xflags = swift.xflags
    cHeader.pointee.os = swift.os
    cHeader.pointee.hcrc = swift.hcrc
    cHeader.pointee.done = swift.done

    var extraPtr: UnsafeMutablePointer<Bytef>?
    var namePtr: UnsafeMutablePointer<CChar>?
    var commentPtr: UnsafeMutablePointer<CChar>?

    // Extra field: we need to ensure the pointer remains valid
    if let extra = swift.extra {
        // Allocate memory for the extra data and copy it
        let ptr = UnsafeMutablePointer<Bytef>.allocate(capacity: extra.count)
        extra.copyBytes(to: ptr, count: extra.count)
        cHeader.pointee.extra = ptr
        cHeader.pointee.extra_len = uInt(extra.count)
        extraPtr = ptr
    } else {
        cHeader.pointee.extra = nil
        cHeader.pointee.extra_len = 0
    }

    // Name: we need to ensure the pointer remains valid
    if let name = swift.name {
        // Allocate memory for the C string and copy it
        let nameLength = name.utf8.count + 1 // +1 for null terminator
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: nameLength)
        name.utf8CString.withUnsafeBufferPointer { buffer in
            ptr.initialize(from: buffer.baseAddress!, count: nameLength)
        }
        cHeader.pointee.name = UnsafeMutablePointer<Bytef>(OpaquePointer(ptr))
        namePtr = ptr
    } else {
        cHeader.pointee.name = nil
    }

    // Comment: we need to ensure the pointer remains valid
    if let comment = swift.comment {
        // Allocate memory for the C string and copy it
        let commentLength = comment.utf8.count + 1 // +1 for null terminator
        let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: commentLength)
        comment.utf8CString.withUnsafeBufferPointer { buffer in
            ptr.initialize(from: buffer.baseAddress!, count: commentLength)
        }
        cHeader.pointee.comment = UnsafeMutablePointer<Bytef>(OpaquePointer(ptr))
        commentPtr = ptr
    } else {
        cHeader.pointee.comment = nil
    }

    return (extraPtr, namePtr, commentPtr)
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

/// Clean up allocated memory for a gz_header structure
/// - Parameter cHeader: C gzip header pointer
func cleanup_gz_header(_ cHeader: UnsafeMutablePointer<gz_header>) {
    // Free extra field memory
    if let extra = cHeader.pointee.extra {
        extra.deallocate()
        cHeader.pointee.extra = nil
        cHeader.pointee.extra_len = 0
    }

    // Free name memory
    if let name = cHeader.pointee.name {
        let namePtr = UnsafeMutablePointer<CChar>(OpaquePointer(name))
        namePtr.deallocate()
        cHeader.pointee.name = nil
    }

    // Free comment memory
    if let comment = cHeader.pointee.comment {
        let commentPtr = UnsafeMutablePointer<CChar>(OpaquePointer(comment))
        commentPtr.deallocate()
        cHeader.pointee.comment = nil
    }
}

// MARK: - GzipHeaderStorage

/// Storage class to own gz_header and its memory for zlib interop
final class GzipHeaderStorage {
    // MARK: Properties

    var cHeader: gz_header

    private var extraPtr: UnsafeMutablePointer<Bytef>?
    private var namePtr: UnsafeMutablePointer<CChar>?
    private var commentPtr: UnsafeMutablePointer<CChar>?

    /// Track allocation state for safety
    private var isDeallocated = false

    // MARK: Lifecycle

    init(swiftHeader: GzipHeader) {
        cHeader = gz_header()
        cHeader.text = swiftHeader.text
        cHeader.time = uLong(swiftHeader.time)
        cHeader.xflags = swiftHeader.xflags
        cHeader.os = swiftHeader.os
        cHeader.hcrc = swiftHeader.hcrc
        cHeader.done = swiftHeader.done

        // Extra field
        if let extra = swiftHeader.extra {
            // Validate input data - allow reasonable sizes
            guard !extra.isEmpty, extra.count <= 65535 else {
                fatalError("Invalid extra field size: \(extra.count)")
            }

            let ptr = UnsafeMutablePointer<Bytef>.allocate(capacity: extra.count)
            extra.copyBytes(to: ptr, count: extra.count)
            cHeader.extra = ptr
            cHeader.extra_len = uInt(extra.count)
            extraPtr = ptr
        } else {
            cHeader.extra = nil
            cHeader.extra_len = 0
        }

        // Name
        if let name = swiftHeader.name {
            // Validate input string - allow reasonable names
            guard !name.isEmpty, name.count <= 255 else {
                fatalError("Invalid name length: \(name.count)")
            }

            let nameLength = name.utf8.count + 1
            let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: nameLength)
            name.utf8CString.withUnsafeBufferPointer { buffer in
                ptr.initialize(from: buffer.baseAddress!, count: nameLength)
            }
            cHeader.name = UnsafeMutablePointer<Bytef>(OpaquePointer(ptr))
            namePtr = ptr
        } else {
            cHeader.name = nil
        }

        // Comment
        if let comment = swiftHeader.comment {
            // Validate input string - allow reasonable comments
            guard comment.count <= 65535 else {
                fatalError("Invalid comment length: \(comment.count)")
            }

            let commentLength = comment.utf8.count + 1
            let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: commentLength)
            comment.utf8CString.withUnsafeBufferPointer { buffer in
                ptr.initialize(from: buffer.baseAddress!, count: commentLength)
            }
            cHeader.comment = UnsafeMutablePointer<Bytef>(OpaquePointer(ptr))
            commentPtr = ptr
        } else {
            cHeader.comment = nil
        }
    }

    deinit {
        // Prevent double deallocation
        guard !isDeallocated else { return }
        isDeallocated = true

        // Safely deallocate memory with validation
        if let extraPtr {
            // Validate pointer before deallocation
            guard extraPtr != UnsafeMutablePointer<Bytef>(bitPattern: 0xDEAD_BEEF) else {
                fatalError("Attempting to deallocate invalid pointer")
            }
            extraPtr.deallocate()
        }
        if let namePtr {
            // Validate pointer before deallocation
            guard namePtr != UnsafeMutablePointer<CChar>(bitPattern: 0xDEAD_BEEF) else {
                fatalError("Attempting to deallocate invalid pointer")
            }
            namePtr.deallocate()
        }
        if let commentPtr {
            // Validate pointer before deallocation
            guard commentPtr != UnsafeMutablePointer<CChar>(bitPattern: 0xDEAD_BEEF) else {
                fatalError("Attempting to deallocate invalid pointer")
            }
            commentPtr.deallocate()
        }
    }
}
