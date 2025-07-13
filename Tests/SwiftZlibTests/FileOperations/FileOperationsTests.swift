@testable import SwiftZlib
import XCTest

final class FileOperationsTests: XCTestCase {
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
        let sourcePath = "/tmp/test_source.txt"
        let destPath = "/tmp/test_compressed.gz"

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Compress file
        let config = StreamingConfig(bufferSize: 1024, compressionLevel: 6)
        let compressor = FileCompressor(config: config)
        try compressor.compressFile(from: sourcePath, to: destPath)

        // Verify compressed file exists and is non-empty
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: destPath))
        XCTAssertFalse(compressedData.isEmpty)
        // Decompress and check round-trip
        let decompressed = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressed, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: destPath)
    }

    func testFileDecompression() throws {
        let testData = "Hello, World! This is a test file for decompression.".data(using: .utf8)!
        let sourcePath = "/tmp/test_source.txt"
        let compressedPath = "/tmp/test_compressed.gz"
        let decompressedPath = "/tmp/test_decompressed.txt"

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
        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: compressedPath)
        try? FileManager.default.removeItem(atPath: decompressedPath)
    }

    func testFileProcessor() throws {
        let testData = "Hello, World! This is a test file for processing.".data(using: .utf8)!
        let sourcePath = "/tmp/test_source.txt"
        let processedPath = "/tmp/test_processed.gz"
        let decompressedPath = "/tmp/test_decompressed.txt"

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Process file (should compress)
        let processor = FileProcessor()
        try processor.processFile(from: sourcePath, to: processedPath)

        // Verify compressed file exists
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: processedPath))
        XCTAssertFalse(compressedData.isEmpty)

        // Process compressed file (should decompress)
        try processor.processFile(from: processedPath, to: decompressedPath)

        // Verify decompressed data matches original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: processedPath)
        try? FileManager.default.removeItem(atPath: decompressedPath)
    }

    func testFileCompressionWithProgress() throws {
        let testData = String(repeating: "Hello, World! ", count: 1000).data(using: .utf8)!
        let sourcePath = "/tmp/test_source_large.txt"
        let destPath = "/tmp/test_compressed_large.gz"

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        var progressCalls = 0
        var lastProgress = 0

        // Compress file with progress
        let compressor = FileChunkedCompressor()
        try compressor.compressFile(from: sourcePath, to: destPath) { processed, total in
            progressCalls += 1
            lastProgress = processed
            XCTAssertGreaterThanOrEqual(processed, 0)
            XCTAssertLessThanOrEqual(processed, total)
        }

        // Verify progress was called
        XCTAssertGreaterThan(progressCalls, 0)
        XCTAssertGreaterThan(lastProgress, 0)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: destPath)
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
        let sourcePath = "/tmp/test_convenience.txt"
        let compressedPath = "/tmp/test_convenience.gz"
        let decompressedPath = "/tmp/test_convenience_decompressed.txt"

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Test convenience compression
        try ZLib.compressFile(from: sourcePath, to: compressedPath)

        // Test convenience decompression
        try ZLib.decompressFile(from: compressedPath, to: decompressedPath)

        // Verify result
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: compressedPath)
        try? FileManager.default.removeItem(atPath: decompressedPath)
    }

    func testFileCompressionToMemory() throws {
        let testData = "Hello, World! This is a test for memory compression.".data(using: .utf8)!
        let sourcePath = "/tmp/test_memory.txt"

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
        let sourcePath = "/tmp/test_memory.txt"
        let compressedPath = "/tmp/test_memory.gz"

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
        let sourcePath = "/tmp/test_chunked_source.txt"
        let destPath = "/tmp/test_chunked_compressed.gz"

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
        let decompressedPath = "/tmp/test_chunked_decompressed.txt"
        try decompressor.decompressFile(from: destPath, to: decompressedPath)

        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData)

        // Clean up
        try? FileManager.default.removeItem(atPath: sourcePath)
        try? FileManager.default.removeItem(atPath: destPath)
        try? FileManager.default.removeItem(atPath: decompressedPath)
    }

    func testFileChunkedCompressionWithDifferentBufferSizes() throws {
        let testData = String(repeating: "Hello, World! ", count: 1000).data(using: .utf8)!
        let sourcePath = "/tmp/test_buffer_source.txt"

        // Write test data to file
        try testData.write(to: URL(fileURLWithPath: sourcePath))

        // Test with different buffer sizes
        let bufferSizes = [1024, 4096, 16384, 65536]

        for bufferSize in bufferSizes {
            let compressor = FileChunkedCompressor(bufferSize: bufferSize)
            let specificDestPath = "/tmp/test_buffer_\(bufferSize).gz"
            try compressor.compressFile(from: sourcePath, to: specificDestPath)

            let compressedData = try Data(contentsOf: URL(fileURLWithPath: specificDestPath))
            XCTAssertFalse(compressedData.isEmpty)

            // Decompress and verify
            let decompressor = FileChunkedDecompressor(bufferSize: bufferSize)
            let decompressedPath = "/tmp/test_buffer_\(bufferSize)_decompressed.txt"
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
} 