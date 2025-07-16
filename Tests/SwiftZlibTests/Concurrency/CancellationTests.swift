import XCTest
@testable import SwiftZlib

final class AsyncThrowingStreamCancellationTests: XCTestCase {
    func makeCancellableStream() -> AsyncThrowingStream<Int, Error> {
        var internalTask: Task<Void, Never>?

        let stream = AsyncThrowingStream<Int, Error> { continuation in
            continuation.onTermination = { @Sendable reason in
                print("Stream terminated: \(reason)")
                internalTask?.cancel()
            }

            internalTask = Task {
                do {
                    for i in 1... {
                        try Task.checkCancellation()
                        continuation.yield(i)
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return stream
    }

    func testAsyncThrowingStreamCancellation() async {
        let expectation = XCTestExpectation(description: "Stream yields values and cancels")
        expectation.expectedFulfillmentCount = 1

        var receivedValues: [Int] = []
        var streamTerminated = false

        let stream = makeCancellableStream()

        let consumingTask = Task {
            do {
                for try await value in stream {
                    receivedValues.append(value)
                    print("Received: \(value)")
                }
            } catch {
                XCTFail("Stream error: \(error)")
            }
            expectation.fulfill()
        }

        // Cancel after 3 seconds
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            consumingTask.cancel()
            print("Cancelled consumer task")
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        // Should have received approximately 3 values (1, 2, 3) before cancellation
        XCTAssertGreaterThanOrEqual(receivedValues.count, 2, "Should have received at least 2 values before cancellation")
        XCTAssertLessThanOrEqual(receivedValues.count, 4, "Should not have received more than 4 values due to timing")

        // Verify the values are sequential starting from 1
        for (index, value) in receivedValues.enumerated() {
            XCTAssertEqual(value, index + 1, "Value at index \(index) should be \(index + 1)")
        }
    }

    func testFileChunkedCompressorCancellation() async throws {
        // Create a test file
        let testData = String(repeating: "Hello, World! This is a test file for compression cancellation testing. ", count: 1000)
        let sourcePath = NSTemporaryDirectory() + "test_compression_source.txt"
        let destPath = NSTemporaryDirectory() + "test_compression_dest.gz"

        try testData.write(toFile: sourcePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        let compressor = FileChunkedCompressor(bufferSize: 1024)
        var progressUpdates: [ProgressInfo] = []

        let stream = compressor.compressFileProgressStream(
            from: sourcePath,
            to: destPath,
            progressInterval: 0.1
        )

        let consumingTask = Task {
            do {
                for try await progress in stream {
                    progressUpdates.append(progress)
                    print("Compression progress: \(progress.percentage)%")
                }
            } catch {
                XCTFail("Compression stream error: \(error)")
            }
        }

        // Cancel after 1 second
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            consumingTask.cancel()
            print("Cancelled compression task")
        }

        // Wait for completion or cancellation
        await consumingTask.value

        // Should have received some progress updates before cancellation
        XCTAssertGreaterThan(progressUpdates.count, 0, "Should have received progress updates before cancellation")

        // Verify the progress updates are in order
        for (index, progress) in progressUpdates.enumerated() {
            if index > 0 {
                XCTAssertGreaterThanOrEqual(progress.processedBytes, progressUpdates[index - 1].processedBytes, "Progress should be monotonically increasing")
            }
        }
    }

    func testFileChunkedDecompressorCancellation() async throws {
        // Create a test file and compress it first
        let testData = String(repeating: "Hello, World! This is a test file for decompression cancellation testing. ", count: 1000)
        let sourcePath = NSTemporaryDirectory() + "test_decompression_source.txt"
        let compressedPath = NSTemporaryDirectory() + "test_decompression_compressed.gz"
        let destPath = NSTemporaryDirectory() + "test_decompression_dest.txt"

        try testData.write(toFile: sourcePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        // First compress the file
        let compressor = FileChunkedCompressor(bufferSize: 1024)
        try await compressor.compressFile(from: sourcePath, to: compressedPath)

        let decompressor = FileChunkedDecompressor(bufferSize: 1024)
        var progressUpdates: [ProgressInfo] = []

        let stream = decompressor.decompressFileProgressStream(
            from: compressedPath,
            to: destPath,
            progressInterval: 0.1
        )

        let consumingTask = Task {
            do {
                for try await progress in stream {
                    progressUpdates.append(progress)
                    print("Decompression progress: \(progress.percentage)%")
                }
            } catch {
                XCTFail("Decompression stream error: \(error)")
            }
        }

        // Cancel after 1 second
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            consumingTask.cancel()
            print("Cancelled decompression task")
        }

        // Wait for completion or cancellation
        await consumingTask.value

        // Should have received some progress updates before cancellation
        XCTAssertGreaterThan(progressUpdates.count, 0, "Should have received progress updates before cancellation")

        // Verify the progress updates are in order
        for (index, progress) in progressUpdates.enumerated() {
            if index > 0 {
                XCTAssertGreaterThanOrEqual(progress.processedBytes, progressUpdates[index - 1].processedBytes, "Progress should be monotonically increasing")
            }
        }
    }
}
