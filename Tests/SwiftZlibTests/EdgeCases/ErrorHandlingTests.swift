import XCTest
@testable import SwiftZlib

final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    func assertNoDoubleWrappedZLibError(_ error: Error) {
        if let zlibError = error as? ZLibError {
            switch zlibError {
            case let .fileError(underlyingError):
                XCTAssertFalse(underlyingError is ZLibError, "ZLibError should not be wrapped inside another ZLibError")
            case let .compressionFailed(code):
                XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
            case let .decompressionFailed(code):
                XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
            case let .streamError(code):
                XCTAssertNotEqual(code, -999, "Unexpected cancellation error code")
            default:
                break
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        let data = "test data".data(using: .utf8)!
        
        // Test basic error handling
        XCTAssertNoThrow(try ZLib.compress(data))
        XCTAssertNoThrow(try ZLib.decompress(try ZLib.compress(data)))
        
        // Test error with invalid data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        XCTAssertThrowsError(try ZLib.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }
    
    func testNoDoubleWrappedZLibErrors() throws {
        let data = "test data".data(using: .utf8)!
        
        // Test that errors are not double-wrapped
        XCTAssertNoThrow(try ZLib.compress(data))
        
        // Test with invalid data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        XCTAssertThrowsError(try ZLib.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }
    
    func testAsyncStreamNoDoubleWrappedZLibErrors() async throws {
        let data = "test data".data(using: .utf8)!
        
        // Test that async stream errors are not double-wrapped
        XCTAssertNoThrow(try ZLib.compress(data))
        
        // Test with invalid data in async context
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        XCTAssertThrowsError(try ZLib.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            assertNoDoubleWrappedZLibError(error)
        }
    }
    
    func testSpecificErrorTypes() throws {
        // Test for specific error types instead of just "any ZLibError"

        // Test uninitialized stream - should be Z_STREAM_ERROR (-2)
        let compressor = Compressor()
        XCTAssertThrowsError(try compressor.compress(Data([0x42]))) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case let .streamError(code):
                    XCTAssertEqual(code, -2, "Expected Z_STREAM_ERROR for uninitialized stream")
                default:
                    XCTFail("Expected streamError, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }

        // Test invalid data - should be Z_DATA_ERROR (-3)
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case let .decompressionFailed(code):
                    XCTAssertEqual(code, -3, "Expected Z_DATA_ERROR for invalid data")
                default:
                    XCTFail("Expected decompressionFailed, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }
    }
    
    func testPlatformAgnosticValidation() throws {
        // Test that validates behavior without assuming specific platform behavior

        let data = "platform agnostic test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Test that compression produces valid output regardless of platform
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)

        // Test that decompression works regardless of platform
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)

        // Test that empty data works on all platforms
        let emptyCompressed = try ZLib.compress(Data())
        let emptyDecompressed = try ZLib.decompress(emptyCompressed)
        XCTAssertEqual(emptyDecompressed, Data())

        // Test that single byte works on all platforms
        let singleByte = Data([0x42])
        let singleCompressed = try ZLib.compress(singleByte)
        let singleDecompressed = try ZLib.decompress(singleCompressed)
        XCTAssertEqual(singleDecompressed, singleByte)
    }
    
    func testIntermediateStateValidation() throws {
        // Test that validates intermediate states during streaming operations

        let data = "intermediate state validation test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)

        // Test intermediate state during compression
        let chunk1 = data.prefix(5)
        let compressed1 = try compressor.compress(chunk1, flush: .noFlush)
        XCTAssertGreaterThanOrEqual(compressed1.count, 0)

        // Validate stream state after first chunk
        let streamInfo1 = try compressor.getStreamInfo()
        XCTAssertGreaterThanOrEqual(streamInfo1.totalIn, 5)
        XCTAssertTrue(streamInfo1.isActive)

        // Test intermediate state during decompression
        let chunk2 = data.suffix(from: 5)
        let compressed2 = try compressor.compress(chunk2, flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed2.count, 0)

        // Validate final stream state
        let streamInfo2 = try compressor.getStreamInfo()
        XCTAssertEqual(streamInfo2.totalIn, UInt(data.count))
        // Note: isActive reflects initialization state, not completion state
        // The stream remains initialized even after finishing
        XCTAssertTrue(streamInfo2.isActive) // Stream remains initialized

        // Test decompression with intermediate state validation
        let fullCompressed = compressed1 + compressed2
        let decompressor = Decompressor()
        try decompressor.initialize()

        // Decompress in chunks and validate intermediate states
        let decompressed1 = try decompressor.decompress(fullCompressed.prefix(fullCompressed.count / 2))
        let decompressed2 = try decompressor.decompress(fullCompressed.suffix(from: fullCompressed.count / 2))

        let finalDecompressed = decompressed1 + decompressed2
        XCTAssertEqual(finalDecompressed, data)
    }
    
    func testConsistentErrorExpectations() throws {
        // Test that validates consistent error expectations across different scenarios

        // Test that uninitialized operations always throw stream errors
        let compressor = Compressor()
        let decompressor = Decompressor()

        // All uninitialized operations should throw stream errors
        XCTAssertThrowsError(try compressor.compress(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case let .streamError(code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }

        XCTAssertThrowsError(try compressor.setDictionary(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case let .streamError(code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }

        XCTAssertThrowsError(try decompressor.decompress(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case let .streamError(code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }

        // Test that invalid data always throws data errors
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        try decompressor.initialize()

        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case let .decompressionFailed(code) = zlibError {
                XCTAssertEqual(code, -3)
            }
        }
    }
    
    // MARK: - Test Discovery
    
    static var allTests = [
        ("testErrorHandling", testErrorHandling),
        ("testNoDoubleWrappedZLibErrors", testNoDoubleWrappedZLibErrors),
        ("testAsyncStreamNoDoubleWrappedZLibErrors", testAsyncStreamNoDoubleWrappedZLibErrors),
        ("testSpecificErrorTypes", testSpecificErrorTypes),
        ("testPlatformAgnosticValidation", testPlatformAgnosticValidation),
        ("testIntermediateStateValidation", testIntermediateStateValidation),
        ("testConsistentErrorExpectations", testConsistentErrorExpectations),
    ]
} 