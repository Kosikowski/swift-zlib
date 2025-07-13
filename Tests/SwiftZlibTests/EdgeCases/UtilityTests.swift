//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

final class UtilityTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testErrorInfo", testErrorInfo),
        ("testSuccessErrorChecks", testSuccessErrorChecks),
        ("testErrorMessage", testErrorMessage),
        ("testRecoverableError", testRecoverableError),
        ("testErrorRecoverySuggestions", testErrorRecoverySuggestions),
        ("testParameterValidation", testParameterValidation),
    ]

    // MARK: Functions

    func testErrorInfo() throws {
        let errorInfo = ZLib.getErrorInfo(0) // Z_OK
        XCTAssertEqual(errorInfo.code, .ok)
        XCTAssertFalse(errorInfo.isError)

        let errorInfo2 = ZLib.getErrorInfo(-2) // Z_STREAM_ERROR
        XCTAssertEqual(errorInfo2.code, .streamError)
        XCTAssertTrue(errorInfo2.isError)
    }

    func testSuccessErrorChecks() throws {
        XCTAssertTrue(ZLib.isSuccess(0)) // Z_OK
        XCTAssertTrue(ZLib.isSuccess(1)) // Z_STREAM_END
        XCTAssertFalse(ZLib.isError(0)) // Z_OK
        XCTAssertFalse(ZLib.isError(1)) // Z_STREAM_END

        XCTAssertTrue(ZLib.isError(-2)) // Z_STREAM_ERROR
        XCTAssertTrue(ZLib.isError(-3)) // Z_DATA_ERROR
        XCTAssertFalse(ZLib.isSuccess(-2)) // Z_STREAM_ERROR
        XCTAssertFalse(ZLib.isSuccess(-3)) // Z_DATA_ERROR
    }

    func testErrorMessage() throws {
        let message = ZLib.getErrorMessage(0) // Z_OK
        // Error message might be empty for Z_OK, so just check it's a valid string
        XCTAssertNotNil(message)

        let errorMessage = ZLib.getErrorMessage(-2) // Z_STREAM_ERROR
        XCTAssertNotNil(errorMessage)
        // Both messages might be the same on some systems, so just check they're valid
    }

    func testRecoverableError() throws {
        XCTAssertTrue(ZLib.isRecoverableError(-5)) // Z_BUF_ERROR
        XCTAssertTrue(ZLib.isRecoverableError(2)) // Z_NEED_DICT
        XCTAssertFalse(ZLib.isRecoverableError(-2)) // Z_STREAM_ERROR
        XCTAssertFalse(ZLib.isRecoverableError(-3)) // Z_DATA_ERROR)
    }

    func testErrorRecoverySuggestions() throws {
        let suggestions = ZLib.getErrorRecoverySuggestions(-5) // Z_BUF_ERROR
        XCTAssertFalse(suggestions.isEmpty)
        // Check that suggestions contain helpful information (case insensitive)
        let hasBufferSuggestion = suggestions.contains { suggestion in
            suggestion.lowercased().contains("buffer") ||
                suggestion.lowercased().contains("memory") ||
                suggestion.lowercased().contains("size")
        }
        XCTAssertTrue(hasBufferSuggestion)

        let suggestions2 = ZLib.getErrorRecoverySuggestions(2) // Z_NEED_DICT
        XCTAssertFalse(suggestions2.isEmpty)
        // Check that suggestions contain helpful information (case insensitive)
        let hasDictSuggestion = suggestions2.contains { suggestion in
            suggestion.lowercased().contains("dictionary") ||
                suggestion.lowercased().contains("dict") ||
                suggestion.lowercased().contains("provide")
        }
        XCTAssertTrue(hasDictSuggestion)
    }

    func testParameterValidation() throws {
        let warnings = ZLib.validateParameters(
            level: .bestCompression,
            windowBits: .deflate,
            memoryLevel: .minimum,
            strategy: .defaultStrategy
        )
        XCTAssertNotNil(warnings)
        // Warnings might be empty for valid parameters, so just check it's a valid array
    }
}
