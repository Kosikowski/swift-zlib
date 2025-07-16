import XCTest
@testable import SwiftZlib

final class CompressorCancellationTests: XCTestCase {
    // MARK: Overridden Functions

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Functions

    // MARK: - Initialization Cancellation Tests

    func testCompressorInitializeCancellation() async throws {
        let expectation = XCTestExpectation(description: "Initialize should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize(level: .bestCompression)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testCompressorInitializeAdvancedCancellation() async throws {
        let expectation = XCTestExpectation(description: "InitializeAdvanced should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initializeAdvanced(
                    level: .bestCompression,
                    method: .deflate,
                    windowBits: .deflate,
                    memoryLevel: .maximum,
                    strategy: .defaultStrategy
                )
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testCompressorResetCancellation() async throws {
        let expectation = XCTestExpectation(description: "Reset should be cancelled")

        let task = Task {
            do {
                let compressor = Compressor()
                try compressor.initialize()
                try compressor.reset()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
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
                let largeData = Data(repeating: 0x41, count: 10_000_000) // 10MB

                // Add artificial delay to allow cancellation to be checked
                try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                // This should be cancelled during processing
                _ = try compressor.compress(largeData, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
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
                    let chunkData = Data(repeating: UInt8(i), count: 1_000_000) // 1MB chunks
                    _ = try compressor.compress(chunkData, flush: i == 10 ? .finish : .noFlush)

                    // Small delay to allow cancellation
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel after a short delay
        try await Task.sleep(nanoseconds: 30_000_000) // 30ms
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

                // Add some data first
                let data = Data(repeating: 0x42, count: 1_000_000) // 1MB
                _ = try compressor.compress(data, flush: .noFlush)

                // Add delay to allow cancellation
                try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                // This should be cancelled during finish processing
                _ = try compressor.finish()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
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
                    let chunkData = Data(repeating: UInt8(i), count: 2_000_000) // 2MB chunks
                    _ = try compressor.compress(chunkData, flush: i == 5 ? .finish : .noFlush)

                    // Small delay to allow cancellation
                    try await Task.sleep(nanoseconds: 20_000_000) // 20ms
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
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
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

                // Add delay to allow cancellation
                try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                // Second compression (this should be cancelled)
                let data2 = Data(repeating: 0x42, count: 10_000_000) // 10MB data
                _ = try compressor.compress(data2, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
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

                // Try to compress empty data
                _ = try compressor.compress(Data(), flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel immediately
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
                try await Task.sleep(nanoseconds: 5_000_000) // 5ms

                _ = try compressor.compress(smallData, flush: .finish)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Cancel during the delay
        try await Task.sleep(nanoseconds: 2_000_000) // 2ms
        task.cancel()

        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
