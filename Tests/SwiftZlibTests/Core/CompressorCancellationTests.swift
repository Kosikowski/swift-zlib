import XCTest
@testable import SwiftZlib

final class CompressorCancellationTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testCompressorResetCancellation", testCompressorResetCancellation),
        ("testCompressorCompressCancellation", testCompressorCompressCancellation),
        ("testCompressorCompressChunkedCancellation", testCompressorCompressChunkedCancellation),
        ("testCompressorFinishCancellation", testCompressorFinishCancellation),
        ("testCompressorFullWorkflowCancellation", testCompressorFullWorkflowCancellation),
        ("testCompressorResetAndReuseCancellation", testCompressorResetAndReuseCancellation),
        ("testCompressorCancellationWithEmptyData", testCompressorCancellationWithEmptyData),
        ("testCompressorCancellationWithSmallData", testCompressorCancellationWithSmallData),
    ]

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Functions

    func testCompressorResetCancellation() async throws {
        let expectation = XCTestExpectation(description: "Reset should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Add some data first to make reset more meaningful
                let data = Data(repeating: 0x42, count: 1_000_000) // 1MB
                _ = try compressor.compress(data, flush: .noFlush)

                // Add delay to allow cancellation before reset
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                try compressor.reset()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Compression Cancellation Tests

    func testCompressorCompressCancellation() async throws {
        let expectation = XCTestExpectation(description: "Compress should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Create very large data to ensure compression takes time
                let largeData = Data(repeating: 0x41, count: 20_000_000) // 20MB

                // This should be cancelled during processing
                _ = try compressor.compress(largeData, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testCompressorCompressChunkedCancellation() async throws {
        let expectation = XCTestExpectation(description: "Chunked compress should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Process multiple chunks
                for i in 1 ... 10 {
                    let chunkData = Data(repeating: UInt8(i), count: 2_000_000) // 2MB chunks
                    _ = try compressor.compress(chunkData, flush: i == 10 ? .finish : .noFlush)

                    // Small delay to allow cancellation between chunks
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testCompressorFinishCancellation() async throws {
        let expectation = XCTestExpectation(description: "Finish should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Add large amount of data to make finish operation take longer
                let data = Data(repeating: 0x42, count: 10_000_000) // 10MB
                _ = try compressor.compress(data, flush: .noFlush)

                // Add delay to allow cancellation before finish
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                // This should be cancelled during finish processing
                _ = try compressor.finish()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Integration Cancellation Tests

    func testCompressorFullWorkflowCancellation() async throws {
        let expectation = XCTestExpectation(description: "Full workflow should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()

                // Initialize
                try compressor.initialize()

                // Compress multiple chunks
                for i in 1 ... 5 {
                    let chunkData = Data(repeating: UInt8(i), count: 4_000_000) // 4MB chunks
                    _ = try compressor.compress(chunkData, flush: i == 5 ? .finish : .noFlush)

                    // Small delay to allow cancellation between chunks
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }

                // Finish
                _ = try compressor.finish()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel during processing
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testCompressorResetAndReuseCancellation() async throws {
        let expectation = XCTestExpectation(description: "Reset and reuse should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // First compression
                let data1 = Data(repeating: 0x41, count: 1_000_000) // 1MB
                _ = try compressor.compress(data1, flush: .finish)
                _ = try compressor.finish()

                // Reset
                try compressor.reset()

                // Add delay to allow cancellation before second compression
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                // Second compression (this should be cancelled)
                let data2 = Data(repeating: 0x42, count: 20_000_000) // 20MB data
                _ = try compressor.compress(data2, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Edge Case Cancellation Tests

    func testCompressorCancellationWithEmptyData() async throws {
        let expectation = XCTestExpectation(description: "Empty data compression should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Add delay to allow cancellation before compress
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                // Try to compress empty data
                _ = try compressor.compress(Data(), flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testCompressorCancellationWithSmallData() async throws {
        let expectation = XCTestExpectation(description: "Small data compression should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()

                // Small data that should compress quickly
                let smallData = Data(repeating: 0x41, count: 100)

                // Add artificial delay to allow cancellation
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                _ = try compressor.compress(smallData, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel during the delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
