//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

#if canImport(Combine)
    import Combine
#endif

// MARK: - FileOperationsTests

final class FileOperationsTests: XCTestCase {
    // MARK: Static Properties

    #if canImport(Combine)
        static var allTests = [
            ("testGzipFileAPI", testGzipFileAPI),
            ("testGzipFileFlushModes", testGzipFileFlushModes),
            ("testFileCompression", testFileCompression),
            ("testFileDecompression", testFileDecompression),
            ("testFileProcessor", testFileProcessor),
            ("testFileCompressionWithProgress", testFileCompressionWithProgress),
            ("testChunkedProcessor", testChunkedProcessor),
            ("testStreamingProcessor", testStreamingProcessor),
            ("testConvenienceFileMethods", testConvenienceFileMethods),
            ("testFileCompressionToMemory", testFileCompressionToMemory),
            ("testFileDecompressionToMemory", testFileDecompressionToMemory),
            ("testStreamingConfig", testStreamingConfig),
            ("testFileChunkedCompression", testFileChunkedCompression),
            ("testFileChunkedCompressionWithDifferentBufferSizes", testFileChunkedCompressionWithDifferentBufferSizes),
            ("testCombineFileCompressionDecompression", testCombineFileCompressionDecompression),
            ("testCombineFileCompressionWithProgress", testCombineFileCompressionWithProgress),
            ("testCombineFileDecompressionWithProgress", testCombineFileDecompressionWithProgress),
            ("testCombineFileCompressionError", testCombineFileCompressionError),
            ("testCombineFileDecompressionError", testCombineFileDecompressionError),
        ]
    #else
        static var allTests = [
            ("testGzipFileAPI", testGzipFileAPI),
            ("testGzipFileFlushModes", testGzipFileFlushModes),
            ("testFileCompression", testFileCompression),
            ("testFileDecompression", testFileDecompression),
            ("testFileProcessor", testFileProcessor),
            ("testFileCompressionWithProgress", testFileCompressionWithProgress),
            ("testChunkedProcessor", testChunkedProcessor),
            ("testStreamingProcessor", testStreamingProcessor),
            ("testConvenienceFileMethods", testConvenienceFileMethods),
            ("testFileCompressionToMemory", testFileCompressionToMemory),
            ("testFileDecompressionToMemory", testFileDecompressionToMemory),
            ("testStreamingConfig", testStreamingConfig),
            ("testFileChunkedCompression", testFileChunkedCompression),
            ("testFileChunkedCompressionWithDifferentBufferSizes", testFileChunkedCompressionWithDifferentBufferSizes),
        ]
    #endif

    // MARK: Properties

    #if canImport(Combine)
        private var cancellables = Set<AnyCancellable>()
    #endif

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
        // Disable verbose logging to prevent debug output interference in tests
        ZLibVerboseConfig.disableAll()
    }

    override func tearDown() {
        // Re-enable verbose logging after tests if needed
        ZLibVerboseConfig.disableAll()
        super.tearDown()
    }

    // MARK: Functions

    func testGzipFileAPI() throws {
        // Test gzip file operations
        let testData = "test data for gzip file".data(using: .utf8)!
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.gz")

        // Write compressed data to gzip file
        let gzipFile = try GzipFile(path: testFile.path, mode: "wb")
        try gzipFile.writeData(testData)
        try gzipFile.close()

        // Read and decompress from gzip file
        let readFile = try GzipFile(path: testFile.path, mode: "rb")
        let readData = try readFile.readData(count: testData.count)
        try readFile.close()

        XCTAssertEqual(readData, testData)

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testGzipFileFlushModes() throws {
        let tempFile = "test_gzip_flush.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let gzipFile = try GzipFile(path: tempFile, mode: "w")

        // Test different flush modes
        try gzipFile.writeString("Data before flush")
        try gzipFile.flush(mode: 0) // Z_NO_FLUSH

        try gzipFile.writeString("Data after NO_FLUSH")
        try gzipFile.flush(mode: 1) // Z_PARTIAL_FLUSH

        try gzipFile.writeString("Data after PARTIAL_FLUSH")
        try gzipFile.flush(mode: 2) // Z_SYNC_FLUSH

        try gzipFile.writeString("Data after SYNC_FLUSH")
        try gzipFile.flush(mode: 3) // Z_FULL_FLUSH

        try gzipFile.writeString("Final data")
        try gzipFile.flush(mode: 4) // Z_FINISH

        try gzipFile.close()

        // Verify file was created
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: tempFile))
    }

    func testFileCompression() throws {
        let testData = "Hello, World! This is a test file for compression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_source.txt")
        let destPath = tempFilePath("test_compressed.gz")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Verify source file exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: sourcePath), "Source file should exist after writing")

        // Compress file with better error handling
        let config = StreamingConfig(bufferSize: 1024, compressionLevel: 6)
        let compressor = FileCompressor(config: config)

        do {
            try compressor.compressFile(from: sourcePath, to: destPath)
        } catch {
            XCTFail("Compression failed with error: \(error)")
            return
        }

        // Verify compressed file exists and is non-empty
        XCTAssertTrue(fileManager.fileExists(atPath: destPath), "Compressed file should exist after compression")

        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty, "Compressed data should not be empty")

        // Decompress and check round-trip
        let decompressed = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressed, testData, "Decompressed data should match original data")

        // Clean up with proper error handling for Windows
        try? fileManager.removeItem(atPath: sourcePath)
        try? fileManager.removeItem(atPath: destPath)
    }

    func testFileDecompression() throws {
        let testData = "Hello, World! This is a test file for decompression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_source.txt")
        let compressedPath = tempFilePath("test_compressed.gz")
        let decompressedPath = tempFilePath("test_decompressed.txt")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file
        let compressor = FileChunkedCompressor()
        try compressor.compressFile(from: sourcePath, to: compressedPath)

        // Decompress file
        let decompressor = FileChunkedDecompressor()
        try decompressor.decompressFile(from: compressedPath, to: decompressedPath)

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data exactly")

        // Clean up with proper error handling for Windows
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: sourcePath)
        try? fileManager.removeItem(atPath: compressedPath)
        try? fileManager.removeItem(atPath: decompressedPath)
    }

    func testFileProcessor() throws {
        let testData = "Hello, World! This is a test file for processing.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_source.txt")
        let processedPath = tempFilePath("test_processed.gz")
        let decompressedPath = tempFilePath("test_decompressed.txt")

        // Write test data to file with better error handling
        do {
            try testData.write(to: URL(fileURLWithPath: sourcePath))
        } catch {
            XCTFail("Failed to write test data to file: \(error)")
            return
        }

        // Verify source file exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: sourcePath), "Source file should exist after writing")

        // Process file (should compress) with better error handling
        let processor = FileProcessor()
        do {
            try processor.processFile(from: sourcePath, to: processedPath)
        } catch {
            XCTFail("File processing failed: \(error)")
            return
        }

        // Verify compressed file exists
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: processedPath))
        XCTAssertFalse(compressedData.isEmpty)

        // Process compressed file (should decompress) with better error handling
        do {
            try processor.processFile(from: processedPath, to: decompressedPath)
        } catch {
            XCTFail("File decompression failed: \(error)")
            return
        }

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData)

        // Clean up with proper error handling for Windows
        try? fileManager.removeItem(atPath: sourcePath)
        try? fileManager.removeItem(atPath: processedPath)
        try? fileManager.removeItem(atPath: decompressedPath)
    }

    func testFileCompressionWithProgress() throws {
        let testData = String(repeating: "Hello, World! ", count: 1000).data(using: .utf8)!
        let sourcePath = tempFilePath("test_source_large.txt")
        let destPath = tempFilePath("test_compressed_large.gz")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Verify source file exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: sourcePath), "Source file should exist after writing")

        var progressCalls = 0
        var lastProgress = 0

        // Compress file with progress and better error handling
        let compressor = FileChunkedCompressor()

        do {
            try compressor.compressFile(from: sourcePath, to: destPath) { processed, total in
                progressCalls += 1
                lastProgress = processed
                XCTAssertGreaterThanOrEqual(processed, 0)
                XCTAssertLessThanOrEqual(processed, total)
            }
        } catch {
            XCTFail("Compression with progress failed with error: \(error)")
            return
        }

        // Verify compressed file exists
        XCTAssertTrue(fileManager.fileExists(atPath: destPath), "Compressed file should exist after compression")

        // Verify progress was called
        XCTAssertGreaterThan(progressCalls, 0, "Progress callback should be called")
        XCTAssertGreaterThan(lastProgress, 0, "Progress should be greater than 0")

        // Clean up with proper error handling for Windows
        try? fileManager.removeItem(atPath: sourcePath)
        try? fileManager.removeItem(atPath: destPath)
    }

    func testChunkedProcessor() throws {
        let testData = "Hello, World! This is test data for chunked processing.".data(using: .utf8)!
        let config = StreamingConfig(bufferSize: 10)
        let processor = ChunkedProcessor(config: config)

        // Process data in chunks
        let results = try processor.processChunks(data: testData) { chunk in
            chunk.count
        }

        // Verify chunks were processed
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertEqual(results.reduce(0, +), testData.count)
    }

    func testStreamingProcessor() throws {
        let testData = "Hello, World! This is test data for streaming processing.".data(using: .utf8)!
        let config = StreamingConfig(bufferSize: 10)
        let processor = ChunkedProcessor(config: config)

        // Process data with streaming
        let results = try processor.processStreaming(data: testData) { chunk, isLast in
            (chunk.count, isLast)
        }

        // Verify streaming was processed
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.last?.1 == true) // Last chunk should be marked as last
    }

    func testConvenienceFileMethods() throws {
        let testData = "Hello, World! This is a test for convenience methods.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_convenience.txt")
        let compressedPath = tempFilePath("test_convenience.gz")
        let decompressedPath = tempFilePath("test_convenience_decompressed.txt")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Verify source file exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: sourcePath), "Source file should exist after writing")

        // Test convenience compression with error handling
        do {
            try ZLib.compressFile(from: sourcePath, to: compressedPath)
        } catch {
            XCTFail("Convenience compression failed with error: \(error)")
            return
        }

        // Verify compressed file exists
        XCTAssertTrue(fileManager.fileExists(atPath: compressedPath), "Compressed file should exist after convenience compression")

        // Test convenience decompression with error handling
        do {
            try ZLib.decompressFile(from: compressedPath, to: decompressedPath)
        } catch {
            XCTFail("Convenience decompression failed with error: \(error)")
            return
        }

        // Verify decompressed file exists
        XCTAssertTrue(fileManager.fileExists(atPath: decompressedPath), "Decompressed file should exist after convenience decompression")

        // Verify result
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData, "Decompressed data should match original data")

        // Clean up with proper error handling for Windows
        try? fileManager.removeItem(atPath: sourcePath)
        try? fileManager.removeItem(atPath: compressedPath)
        try? fileManager.removeItem(atPath: decompressedPath)
    }

    func testFileCompressionToMemory() throws {
        let testData = "Hello, World! This is a test for memory compression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_memory.txt")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file to memory
        let compressor = FileCompressor()
        let compressedData = try compressor.compressFileToMemory(from: sourcePath)

        // Verify compressed data is non-empty and decompresses to original
        XCTAssertFalse(compressedData.isEmpty)
        let decompressed = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressed, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
    }

    func testFileDecompressionToMemory() throws {
        let testData = "Hello, World! This is a test for memory decompression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_memory.txt")
        let compressedPath = tempFilePath("test_memory.gz")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file
        let compressor = FileCompressor()
        try compressor.compressFile(from: sourcePath, to: compressedPath)

        // Decompress file to memory
        let decompressor = FileDecompressor()
        let decompressedData = try decompressor.decompressFileToMemory(from: compressedPath)

        // Verify decompressed data
        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: compressedPath)
    }

    func testStreamingConfig() throws {
        let config = StreamingConfig(
            bufferSize: 8192,
            useTempFiles: true,
            compressionLevel: 9,
            windowBits: 31
        )

        XCTAssertEqual(config.bufferSize, 8192)
        XCTAssertTrue(config.useTempFiles)
        XCTAssertEqual(config.compressionLevel, 9)
        XCTAssertEqual(config.windowBits, 31)

        // Test default config
        let defaultConfig = StreamingConfig()
        XCTAssertEqual(defaultConfig.bufferSize, 64 * 1024)
        XCTAssertFalse(defaultConfig.useTempFiles)
        XCTAssertEqual(defaultConfig.compressionLevel, 6)
        XCTAssertEqual(defaultConfig.windowBits, 15)
    }

    func testFileChunkedCompression() throws {
        let testData = "Hello, World! This is a test for true chunked streaming compression.".data(using: .utf8)!
        let sourcePath = tempFilePath("test_chunked_source.txt")
        let destPath = tempFilePath("test_chunked_compressed.gz")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file using true chunked streaming
        let compressor = FileChunkedCompressor(bufferSize: 1024, compressionLevel: .defaultCompression)
        try compressor.compressFile(from: sourcePath, to: destPath)

        // Verify compressed file exists and is non-empty
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty)

        // Decompress and verify round-trip
        let decompressor = FileChunkedDecompressor(bufferSize: 1024)
        let decompressedPath = tempFilePath("test_chunked_decompressed.txt")
        try decompressor.decompressFile(from: destPath, to: decompressedPath)

        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))

        // Add debugging information for Linux CI issues
        print("Original data size: \(testData.count) bytes")
        print("Decompressed data size: \(decompressedData.count) bytes")
        print("Original data: \(String(data: testData, encoding: .utf8) ?? "invalid")")
        print("Decompressed data: \(String(data: decompressedData, encoding: .utf8) ?? "invalid")")

        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: destPath)
        try? FileManager.default.removeItem(atPath: decompressedPath)
    }

    func testFileChunkedCompressionWithDifferentBufferSizes() throws {
        let testData = String(repeating: "Hello, World! ", count: 1000).data(using: .utf8)!
        let sourcePath = tempFilePath("test_buffer_source.txt")

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Test with different buffer sizes
        let bufferSizes = [1024, 4096, 16384, 65536]

        for bufferSize in bufferSizes {
            let compressor = FileChunkedCompressor(bufferSize: bufferSize)
            let specificDestPath = tempFilePath("test_buffer_\(bufferSize).gz")
            try compressor.compressFile(from: sourcePath, to: specificDestPath)

            let compressedData = try Data(contentsOf: URL(fileURLWithPath: specificDestPath))
            XCTAssertFalse(compressedData.isEmpty)

            // Decompress and verify
            let decompressor = FileChunkedDecompressor(bufferSize: bufferSize)
            let decompressedPath = tempFilePath("test_buffer_\(bufferSize)_decompressed.txt")
            try decompressor.decompressFile(from: specificDestPath, to: decompressedPath)

            let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
            XCTAssertEqual(decompressedData, testData)

            // Clean up
            try? FileManager.default.removeItem(atPath: specificDestPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
    }

    /// Get a temporary file path for testing
    private func tempFilePath(_ filename: String) -> String {
        #if os(Windows)
            // On Windows, use a more reliable temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let uniqueFilename = "\(UUID().uuidString)_\(filename)"
            let path = tempDir.appendingPathComponent(uniqueFilename).path

            // Ensure the file doesn't exist before returning the path
            // This helps prevent permission issues on Windows
            try? FileManager.default.removeItem(atPath: path)

            return path
        #else
            let tempDir = FileManager.default.temporaryDirectory
            let path = tempDir.appendingPathComponent(filename).path

            // Ensure the file doesn't exist before returning the path
            // This helps prevent permission issues on Windows
            try? FileManager.default.removeItem(atPath: path)

            return path
        #endif
    }
}

#if canImport(Combine)
    extension FileOperationsTests {
        func testCombineFileCompressionDecompression() throws {
            let testData = "Hello, Combine! This is a test file for Combine compression.".data(using: .utf8)!
            let sourcePath = tempFilePath("test_combine_source.txt")
            let compressedPath = tempFilePath("test_combine_compressed.gz")
            let decompressedPath = tempFilePath("test_combine_decompressed.txt")
            try testData.write(to: URL(fileURLWithPath: sourcePath))

            let compressExpectation = expectation(description: "Combine file compression completes")
            cancellables.removeAll()

            // Compress file using Combine publisher
            ZLib.compressFilePublisher(from: sourcePath, to: compressedPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            compressExpectation.fulfill()
                        case let .failure(error):
                            XCTFail("Compression failed: \(error)")
                    }
                }, receiveValue: {})
                .store(in: &cancellables)

            wait(for: [compressExpectation], timeout: 5.0)

            // Decompress file using Combine publisher
            let decompressExpectation = expectation(description: "Combine file decompression completes")
            ZLib.decompressFilePublisher(from: compressedPath, to: decompressedPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            decompressExpectation.fulfill()
                        case let .failure(error):
                            XCTFail("Decompression failed: \(error)")
                    }
                }, receiveValue: {})
                .store(in: &cancellables)

            wait(for: [decompressExpectation], timeout: 5.0)

            // Verify decompressed data matches original
            let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
            XCTAssertEqual(decompressedData, testData)

            // Clean up
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        func testCombineFileCompressionWithProgress() throws {
            let testData = String(repeating: "Hello, Combine Progress! ", count: 1000).data(using: .utf8)!
            let sourcePath = tempFilePath("test_combine_progress_source.txt")
            let compressedPath = tempFilePath("test_combine_progress_compressed.gz")
            try testData.write(to: URL(fileURLWithPath: sourcePath))

            let progressExpectation = expectation(description: "Combine file compression with progress completes")
            var progressUpdates = 0
            var lastPercent: Double = 0
            cancellables.removeAll()

            ZLib.compressFileProgressPublisher(from: sourcePath, to: compressedPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            progressExpectation.fulfill()
                        case let .failure(error):
                            XCTFail("Compression with progress failed: \(error)")
                    }
                }, receiveValue: { progress in
                    progressUpdates += 1
                    lastPercent = progress.percent
                    XCTAssertGreaterThanOrEqual(progress.percent, 0)
                    XCTAssertLessThanOrEqual(progress.percent, 100)
                })
                .store(in: &cancellables)

            wait(for: [progressExpectation], timeout: 10.0)
            XCTAssertGreaterThan(progressUpdates, 0)
            XCTAssertEqual(lastPercent, 100, accuracy: 0.1)

            // Clean up
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
        }

        func testCombineFileDecompressionWithProgress() throws {
            let testData = String(repeating: "Hello, Combine Decompression Progress! ", count: 1000).data(using: .utf8)!
            let sourcePath = tempFilePath("test_combine_decomp_progress_source.txt")
            let compressedPath = tempFilePath("test_combine_decomp_progress_compressed.gz")
            let decompressedPath = tempFilePath("test_combine_decomp_progress_decompressed.txt")
            try testData.write(to: URL(fileURLWithPath: sourcePath))

            // Compress file first
            let compressExpectation = expectation(description: "Compression for decompression progress test completes")
            cancellables.removeAll()
            ZLib.compressFilePublisher(from: sourcePath, to: compressedPath)
                .sink(receiveCompletion: { completion in
                    if case .finished = completion { compressExpectation.fulfill() }
                }, receiveValue: {})
                .store(in: &cancellables)
            wait(for: [compressExpectation], timeout: 5.0)

            // Decompress file with progress
            let progressExpectation = expectation(description: "Combine file decompression with progress completes")
            var progressUpdates = 0
            var lastPercent: Double = 0
            ZLib.decompressFileProgressPublisher(from: compressedPath, to: decompressedPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            progressExpectation.fulfill()
                        case let .failure(error):
                            XCTFail("Decompression with progress failed: \(error)")
                    }
                }, receiveValue: { progress in
                    progressUpdates += 1
                    lastPercent = progress.percent
                    XCTAssertGreaterThanOrEqual(progress.percent, 0)
                    XCTAssertLessThanOrEqual(progress.percent, 100)
                })
                .store(in: &cancellables)
            wait(for: [progressExpectation], timeout: 10.0)
            XCTAssertGreaterThan(progressUpdates, 0)
            XCTAssertEqual(lastPercent, 100, accuracy: 0.1)

            // Verify decompressed data matches original
            let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
            XCTAssertEqual(decompressedData, testData)

            // Clean up
            try? FileManager.default.removeItem(atPath: sourcePath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: decompressedPath)
        }

        func testCombineFileCompressionError() throws {
            let nonExistentPath = tempFilePath("does_not_exist.txt")
            let destPath = tempFilePath("should_not_be_created.gz")
            let expectation = expectation(description: "Combine compression error")
            cancellables.removeAll()
            ZLib.compressFilePublisher(from: nonExistentPath, to: destPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            XCTFail("Should not finish successfully")
                        case .failure:
                            expectation.fulfill()
                    }
                }, receiveValue: {})
                .store(in: &cancellables)
            wait(for: [expectation], timeout: 5.0)
            try? FileManager.default.removeItem(atPath: destPath)
        }

        func testCombineFileDecompressionError() throws {
            let nonExistentPath = tempFilePath("does_not_exist.gz")
            let destPath = tempFilePath("should_not_be_created.txt")
            let expectation = expectation(description: "Combine decompression error")
            cancellables.removeAll()
            ZLib.decompressFilePublisher(from: nonExistentPath, to: destPath)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            XCTFail("Should not finish successfully")
                        case .failure:
                            expectation.fulfill()
                    }
                }, receiveValue: {})
                .store(in: &cancellables)
            wait(for: [expectation], timeout: 5.0)
            try? FileManager.default.removeItem(atPath: destPath)
        }
    }
#endif
