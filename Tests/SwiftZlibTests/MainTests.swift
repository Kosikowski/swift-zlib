import XCTest
@testable import SwiftZlib

final class MainTests: XCTestCase {
    
    // MARK: - Test Discovery
    
    static var allTests = [
        ("testBasicIntegration", testBasicIntegration),
    ]
    
    // MARK: - Basic Integration Test
    
    func testBasicIntegration() throws {
        // Simple test to verify the test infrastructure works
        let data = "Integration test".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
} 