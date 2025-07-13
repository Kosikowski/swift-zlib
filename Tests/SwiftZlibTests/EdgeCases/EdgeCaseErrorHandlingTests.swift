import XCTest
@testable import SwiftZlib

final class EdgeCaseErrorHandlingTests: XCTestCase {
    /// Helper function to check that ZLibErrors are not double-wrapped
    /// This ensures our error handling doesn't create nested ZLibError.fileError(ZLibError.xxx) patterns
    private func assertNoDoubleWrappedZLibError(_ error: Error) {
        if case let .fileError(underlyingError) = error as? ZLibError {
            XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
        }
    }

    func testErrorHandling() {
        // Test invalid data
        let invalidData = Data([0x78, 0x9C, 0x01, 0x00, 0x00, 0xFF, 0xFF]) // Incomplete zlib data

        XCTAssertThrowsError(try ZLib.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            // Should be a data error (-3) for invalid zlib data
            if case let .decompressionFailed(code) = error as? ZLibError {
                XCTAssertEqual(code, -3, "Expected Z_DATA_ERROR for invalid zlib data")
            }
            assertNoDoubleWrappedZLibError(error)
        }
    }

    func testNoDoubleWrappedZLibErrors() {
        // Test that ZLibErrors are not wrapped in other ZLibErrors
        // This ensures our error handling doesn't create nested ZLibError.fileError(ZLibError.xxx) patterns
        
        // Test file operations that should not double-wrap errors
        let nonExistentPath = "/non/existent/path/file.txt"
        
        // Test FileChunkedCompressor
        let compressor = FileChunkedCompressor()
        XCTAssertThrowsError(try compressor.compressFile(from: nonExistentPath, to: "/tmp/test.gz")) { error in
            // Should be a ZLibError.fileError, but the underlying error should NOT be another ZLibError
            if case let .fileError(underlyingError) = error as? ZLibError {
                // The underlying error should be a Foundation error (like NSError), not another ZLibError
                XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
            } else {
                XCTFail("Expected ZLibError.fileError, got \(error)")
            }
        }
        
        // Test FileChunkedDecompressor
        let decompressor = FileChunkedDecompressor()
        XCTAssertThrowsError(try decompressor.decompressFile(from: nonExistentPath, to: "/tmp/test.txt")) { error in
            // Should be a ZLibError.fileError, but the underlying error should NOT be another ZLibError
            if case let .fileError(underlyingError) = error as? ZLibError {
                // The underlying error should be a Foundation error (like NSError), not another ZLibError
                XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
            } else {
                XCTFail("Expected ZLibError.fileError, got \(error)")
            }
        }
    }

    func testAsyncStreamNoDoubleWrappedZLibErrors() async throws {
        // Specifically test the AsyncStream methods we fixed to ensure they don't double-wrap errors
        let nonExistentPath = "/non/existent/path/file.txt"
        
        // Test compressFileProgressStream
        let compressor = FileChunkedCompressor()
        let compressionStream = compressor.compressFileProgressStream(from: nonExistentPath, to: "/tmp/test.gz")
        
        do {
            for try await _ in compressionStream {
                // Should not reach here
                XCTFail("Should have thrown an error")
            }
        } catch {
            // Should be a ZLibError.fileError, but the underlying error should NOT be another ZLibError
            if case let .fileError(underlyingError) = error as? ZLibError {
                XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
            } else {
                XCTFail("Expected ZLibError.fileError, got \(error)")
            }
        }
        
        // Test decompressFileProgressStream
        let decompressor = FileChunkedDecompressor()
        let decompressionStream = decompressor.decompressFileProgressStream(from: nonExistentPath, to: "/tmp/test.txt")
        
        do {
            for try await _ in decompressionStream {
                // Should not reach here
                XCTFail("Should have thrown an error")
            }
        } catch {
            // Should be a ZLibError.fileError, but the underlying error should NOT be another ZLibError
            if case let .fileError(underlyingError) = error as? ZLibError {
                XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped in another ZLibError")
            } else {
                XCTFail("Expected ZLibError.fileError, got \(error)")
            }
        }
    }

    func testEmptyData() throws {
        let emptyData = Data()

        // Should handle empty data gracefully
        let compressedData = try ZLib.compress(emptyData)
        let decompressedData = try ZLib.decompress(compressedData)

        XCTAssertEqual(decompressedData, emptyData)
    }

    func testSingleByteData() throws {
        let singleByteData = Data([0x42])

        let compressedData = try ZLib.compress(singleByteData)
        let decompressedData = try ZLib.decompress(compressedData)

        XCTAssertEqual(decompressedData, singleByteData)
    }

    func testBinaryData() throws {
        // Test with binary data (not just text)
        var binaryData = Data()
        for i in 0 ..< 1000 {
            binaryData.append(UInt8(i % 256))
        }

        let compressedData = try ZLib.compress(binaryData)
        let decompressedData = try ZLib.decompress(compressedData)

        XCTAssertEqual(decompressedData, binaryData)
    }

    static var allTests = [
        ("testErrorHandling", testErrorHandling),
        ("testNoDoubleWrappedZLibErrors", testNoDoubleWrappedZLibErrors),
        ("testAsyncStreamNoDoubleWrappedZLibErrors", testAsyncStreamNoDoubleWrappedZLibErrors),
        ("testEmptyData", testEmptyData),
        ("testSingleByteData", testSingleByteData),
        ("testBinaryData", testBinaryData),
    ]
} 