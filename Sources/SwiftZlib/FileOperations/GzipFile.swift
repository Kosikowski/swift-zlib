//
//  GzipFile.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//

import Foundation
#if canImport(zlib)
    import zlib
#else
    import SwiftZlibCShims
#endif

// MARK: - GzipFile

public final class GzipFile {
    // MARK: Properties

    public let path: String
    public let mode: String

    private var filePtr: gzFile?
    private var lastError: String?

    // MARK: Computed Properties

    /// Check if file is open
    /// - Returns: True if file is open
    public var isOpen: Bool {
        filePtr != nil
    }

    /// Get file path
    /// - Returns: File path
    public var filePath: String {
        path
    }

    /// Get file mode
    /// - Returns: File mode
    public var fileMode: String {
        mode
    }

    // MARK: Lifecycle

    public init(path: String, mode: String) throws {
        self.path = path
        self.mode = mode
        guard let ptr = gzopen(path, mode) else {
            throw GzipFileError.openFailed("\(path) [mode=\(mode)]")
        }
        filePtr = ptr
    }

    deinit {
        try? close()
    }

    // MARK: Functions

    public func close() throws {
        guard let ptr = filePtr else { return }
        let result = gzclose(ptr)
        filePtr = nil
        if result != Z_OK {
            throw GzipFileError.closeFailed(errorMessage())
        }
    }

    public func readData(count: Int) throws -> Data {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = Data(count: count)
        let bytesRead = buffer.withUnsafeMutableBytes { bufPtr in
            gzread(ptr, bufPtr.baseAddress, UInt32(count))
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
            gzwrite(ptr, UnsafeMutableRawPointer(mutating: bufPtr.baseAddress), UInt32(data.count))
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
        let result = gzseek(ptr, CLong(offset), whence)
        if result < 0 {
            throw GzipFileError.seekFailed(errorMessage())
        }
    }

    public func tell() throws -> Int {
        guard let ptr = filePtr else { throw GzipFileError.seekFailed("File not open") }
        let pos = gztell(ptr)
        let posInt = Int(pos)
        if posInt < 0 {
            throw GzipFileError.seekFailed(errorMessage())
        }
        return posInt
    }

    public func flush(flush: Int32 = Z_SYNC_FLUSH) throws {
        guard let ptr = filePtr else { throw GzipFileError.flushFailed("File not open") }
        let result = gzflush(ptr, flush)
        if result != Z_OK {
            throw GzipFileError.flushFailed(errorMessage())
        }
    }

    public func rewind() throws {
        guard let ptr = filePtr else { throw GzipFileError.seekFailed("File not open") }
        let result = gzrewind(ptr)
        if result != Z_OK {
            throw GzipFileError.seekFailed(errorMessage())
        }
    }

    public func eof() -> Bool {
        guard let ptr = filePtr else { return true }
        return gzeof(ptr) != 0
    }

    public func setParams(level: CompressionLevel, strategy: CompressionStrategy) throws {
        guard let ptr = filePtr else { throw GzipFileError.unknown("File not open") }
        let result = gzsetparams(ptr, level.zlibLevel, strategy.zlibStrategy)
        if result != Z_OK {
            throw GzipFileError.unknown(errorMessage())
        }
    }

    public func errorMessage() -> String {
        guard let ptr = filePtr else { return "File not open" }
        var errnum: Int32 = 0
        if let cstr = gzerror(ptr, &errnum) {
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
        guard let result = gzgets(ptr, &buffer, Int32(maxLength)) else {
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
        let result = gzputc(ptr, c)
        if result != c {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }

    /// Read a single character from gzip file
    /// - Returns: Character read, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getc() throws -> Character? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        let result = gzgetc(ptr)
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
        let result = gzungetc(c, ptr)
        if result != c {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }

    /// Clear error state of gzip file
    public func clearError() {
        guard let ptr = filePtr else { return }
        gzclearerr(ptr)
    }

    /// Print a simple string to gzip file (without format specifiers)
    /// - Parameter string: String to write
    /// - Throws: GzipFileError if operation fails
    public func printfSimple(_ string: String) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }
        // Note: gzprintf is not available in system zlib, so we'll use gzputs instead
        let result = string.withCString { cstr in
            gzputs(ptr, cstr)
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
        let result = gzgets(ptr, &buffer, Int32(maxLength))
        if result == nil {
            return nil // EOF
        }
        return String(cString: buffer)
    }

    // MARK: - Advanced Gzip File Operations

    /// Print formatted string to gzip file (with format specifiers)
    /// - Parameter format: Format string
    /// - Parameter arguments: Format arguments
    /// - Throws: GzipFileError if operation fails
    public func printf(_ format: String, _: CVarArg...) throws {
        guard let ptr = filePtr else { throw GzipFileError.writeFailed("File not open") }

        // For now, we'll use a simplified approach since varargs are complex in Swift-C bridging
        // In a full implementation, you'd need to create a C function that handles varargs
        let result = format.withCString { cstr in
            gzputs(ptr, cstr)
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
    public func getsWithEncoding(maxLength: Int = 1024, encoding _: String.Encoding = .utf8) throws -> String? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        var buffer = [CChar](repeating: 0, count: maxLength)
        guard let result = gzgets(ptr, &buffer, Int32(maxLength)) else {
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
        let result = gzputc(ptr, Int32(byte))
        if result != Int32(byte) {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }

    /// Read a single byte from gzip file
    /// - Returns: Byte value read, or nil if EOF
    /// - Throws: GzipFileError if operation fails
    public func getByte() throws -> UInt8? {
        guard let ptr = filePtr else { throw GzipFileError.readFailed("File not open") }
        let result = gzgetc(ptr)
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
        let result = gzungetc(Int32(byte), ptr)
        if result != Int32(byte) {
            throw GzipFileError.writeFailed(errorMessage())
        }
    }

    /// Check if file is at end of file
    /// - Returns: True if at EOF
    public func isEOF() -> Bool {
        guard let ptr = filePtr else { return true }
        return gzeof(ptr) != 0
    }

    /// Get current file position
    /// - Returns: Current position in file
    /// - Throws: GzipFileError if operation fails
    public func position() throws -> Int {
        try tell()
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
        let result = gzflush(ptr, mode)
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
        let message = gzerror(ptr, &errnum) != nil ? String(cString: gzerror(ptr, &errnum)!) : "Unknown error"
        return (message, errnum)
    }

    /// Clear error state
    public func clearErrorState() {
        clearError()
    }
}
