import XCTest
@testable import SwiftZlib

final class DecompressorCancellationTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testDecompressorDecompressCancellation", testDecompressorDecompressCancellation),
        ("testDecompressorDecompressChunkedCancellation", testDecompressorDecompressChunkedCancellation),
        ("testDecompressorFinishCancellation", testDecompressorFinishCancellation),
        ("testDecompressorFullWorkflowCancellation", testDecompressorFullWorkflowCancellation),
    ]

    // MARK: Functions

    func testDecompressorDecompressCancellation() async throws {
        let expectation = XCTestExpectation(description: "Should cancel decompression")

        let decompressor = Decompressor()
        try decompressor.initialize()
        let largeData = Data(repeating: 0x41, count: 20_000_000) // 20MB
        guard let compressed = try? ZLib.compress(largeData) else {
            XCTFail("Compression failed")
            return
        }

        let task = Task {
            do {
                // Call the method directly - let it handle cancellation internally
                _ = try decompressor.decompress(compressed, flush: .noFlush)
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 10_000_000)
            task.cancel()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }

    func testDecompressorDecompressChunkedCancellation() async throws {
        let expectation = XCTestExpectation(description: "Should cancel chunked decompression")

        let decompressor = Decompressor()
        try decompressor.initialize()
        let largeData = Data(repeating: 0x41, count: 20_000_000) // 20MB
        guard let compressed = try? ZLib.compress(largeData) else {
            XCTFail("Compression failed")
            return
        }
        let chunkSize = 1024 * 1024 // 1MB

        let task = Task {
            do {
                // Process chunks - let the method handle cancellation internally
                for offset in stride(from: 0, to: compressed.count, by: chunkSize) {
                    let chunk = compressed.subdata(in: offset ..< min(offset + chunkSize, compressed.count))
                    _ = try decompressor.decompress(chunk, flush: .noFlush)
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms delay between chunks
                }
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 10_000_000)
            task.cancel()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }

    func testDecompressorFinishCancellation() async throws {
        let expectation = XCTestExpectation(description: "Should cancel finish")

        let decompressor = Decompressor()
        try decompressor.initialize()
        let largeData = Data(repeating: 0x41, count: 10_000_000) // 10MB to make decompression take longer
        guard let compressed = try? ZLib.compress(largeData) else {
            XCTFail("Compression failed")
            return
        }
        // Decompress with .noFlush to leave the stream unfinished
        _ = try decompressor.decompress(compressed, flush: .noFlush)

        let task = Task {
            do {
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay to allow cancellation
                _ = try decompressor.finish() // Let the method handle cancellation
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 10_000_000)
            task.cancel()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }

    func testDecompressorFullWorkflowCancellation() async throws {
        let expectation = XCTestExpectation(description: "Should cancel full workflow")

        let decompressor = Decompressor()
        try decompressor.initialize()
        let largeData = Data(repeating: 0x41, count: 20_000_000) // 20MB
        guard let compressed = try? ZLib.compress(largeData) else {
            XCTFail("Compression failed")
            return
        }
        let chunkSize = 1024 * 1024 // 1MB

        let task = Task {
            do {
                // Process chunks - let the methods handle cancellation internally
                for offset in stride(from: 0, to: compressed.count, by: chunkSize) {
                    let chunk = compressed.subdata(in: offset ..< min(offset + chunkSize, compressed.count))
                    _ = try decompressor.decompress(chunk, flush: .noFlush)
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms delay between chunks
                }
                _ = try decompressor.finish()
                XCTFail("Should have been cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 10_000_000)
            task.cancel()
        }

        await fulfillment(of: [expectation], timeout: 5)
    }
}
