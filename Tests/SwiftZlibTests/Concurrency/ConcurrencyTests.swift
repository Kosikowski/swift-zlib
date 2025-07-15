//  Compression.swift
//  SwiftZlib
//
//  Created by Mateusz Kosikowski on 13/07/2025.
//
import XCTest
@testable import SwiftZlib

// MARK: - ResultsBox

actor ResultsBox<T> {
    // MARK: Properties

    private var items: [T] = []

    // MARK: Functions

    @inline(never)
    func append(_ item: T) { items.append(item) }

    @inline(never)
    func set(_ item: T, at index: Int) { if items.indices.contains(index) { items[index] = item } }

    @inline(never)
    func getAll() -> [T] { items }

    @inline(never)
    func count() -> Int { items.count }

    @inline(never)
    func removeAll() { items.removeAll() }
}

// MARK: - ConcurrencyTests

final class ConcurrencyTests: XCTestCase {
    // MARK: Static Properties

    static var allTests = [
        ("testConcurrentCompression", testConcurrentCompression),
        ("testConcurrentDecompression", testConcurrentDecompression),
        ("testConcurrentMixedOperations", testConcurrentMixedOperations),
        ("testConcurrentStreamingCompression", testConcurrentStreamingCompression),
        ("testConcurrentStreamingDecompression", testConcurrentStreamingDecompression),
        ("testConcurrentCompressorInstances", testConcurrentCompressorInstances),
        ("testConcurrentDecompressorInstances", testConcurrentDecompressorInstances),
        ("testConcurrentDifferentCompressionLevels", testConcurrentDifferentCompressionLevels),
        ("testThreadSafetyOfAPI", testThreadSafetyOfAPI),
        ("testConcurrentDifferentWindowBits", testConcurrentDifferentWindowBits),
        ("testConcurrentDictionaryOperations", testConcurrentDictionaryOperations),
        ("testConcurrentStringOperations", testConcurrentStringOperations),
        ("testConcurrentDataExtensions", testConcurrentDataExtensions),
        ("testConcurrentErrorHandling", testConcurrentErrorHandling),
        ("testConcurrentMemoryPressure", testConcurrentMemoryPressure),
        ("testConcurrentStressTest", testConcurrentStressTest),
    ]

    // MARK: Functions

    //
    // Only per-instance concurrency is valid for zlib and this wrapper.
    // Each thread must use its own Compressor/Decompressor instance.
    // Sharing a single instance across threads is not supported and is undefined behavior.
    //
    // All concurrency tests below ensure that each thread uses its own instance.
    //

    func testConcurrentCompression() async throws {
        let testData = "Concurrent compression test data".data(using: .utf8)!
        let iterations = 10
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try ZLib.compress(testData)
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDecompression() async throws {
        let testData = "Concurrent decompression test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 10
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let decompressed = try ZLib.decompress(compressedData)
                        await results.append(decompressed)
                    } catch {
                        XCTFail("Concurrent decompression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in allResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentMixedOperations() async throws {
        let testStrings = [
            "First concurrent test string",
            "Second concurrent test string",
            "Third concurrent test string",
            "Fourth concurrent test string",
        ]
        let testData = testStrings.map { $0.data(using: .utf8)! }

        let compressedResults = ResultsBox<(index: Int, data: Data)>()
        let decompressedResults = ResultsBox<(index: Int, data: Data)>()
        let errors = ResultsBox<Error>()

        // Compress all data concurrently with index tracking
        await withTaskGroup(of: Void.self) { group in
            for (index, data) in testData.enumerated() {
                group.addTask {
                    do {
                        let compressed = try ZLib.compress(data)
                        await compressedResults.append((index: index, data: compressed))
                    } catch {
                        await errors.append(error)
                    }
                }
            }
        }

        // Check for compression errors
        let allErrors = await errors.getAll()
        XCTAssertEqual(allErrors.count, 0, "Compression errors: \(allErrors)")

        let allCompressedResults = await compressedResults.getAll()
        XCTAssertEqual(allCompressedResults.count, testData.count)

        // Sort compressed results by index to maintain order
        let sortedCompressedResults = allCompressedResults.sorted { $0.index < $1.index }

        // Now decompress all compressed data concurrently
        await errors.removeAll()
        await withTaskGroup(of: Void.self) { group in
            for (index, compressed) in sortedCompressedResults {
                group.addTask {
                    do {
                        let decompressed = try ZLib.decompress(compressed)
                        await decompressedResults.append((index: index, data: decompressed))
                    } catch {
                        await errors.append(error)
                    }
                }
            }
        }

        // Check for decompression errors
        let decompressionErrors = await errors.getAll()
        XCTAssertEqual(decompressionErrors.count, 0, "Decompression errors: \(decompressionErrors)")

        // Verify results match original data in correct order
        let allDecompressedResults = await decompressedResults.getAll()
        let sortedDecompressedResults = allDecompressedResults.sorted { $0.index < $1.index }

        for (i, decompressed) in sortedDecompressedResults.enumerated() {
            // Convert to strings for more reliable comparison
            let originalString = String(data: testData[i], encoding: .utf8) ?? ""
            let decompressedString = String(data: decompressed.data, encoding: .utf8) ?? ""
            XCTAssertEqual(decompressedString, originalString, "Decompressed data at index \(i) doesn't match original")

            // Also verify byte-by-byte comparison
            XCTAssertEqual(decompressed.data, testData[i], "Decompressed data at index \(i) doesn't match original bytes")
        }
    }

    func testConcurrentStreamingCompression() async throws {
        let testData = "Concurrent streaming compression test data".data(using: .utf8)!
        let iterations = 5
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressor = Compressor()
                        try compressor.initialize(level: .defaultCompression)

                        // Split data into chunks
                        let chunkSize = 10
                        var compressed = Data()

                        for i in stride(from: 0, to: testData.count, by: chunkSize) {
                            let end = min(i + chunkSize, testData.count)
                            let chunk = testData[i ..< end]
                            let flush: FlushMode = end == testData.count ? .finish : .noFlush
                            let chunkCompressed = try compressor.compress(chunk, flush: flush)
                            compressed.append(chunkCompressed)
                        }

                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent streaming compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStreamingDecompression() async throws {
        let testData = "Concurrent streaming decompression test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 5
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let decompressor = Decompressor()
                        try decompressor.initialize()

                        // Split compressed data into chunks
                        let chunkSize = 20
                        var decompressed = Data()

                        for i in stride(from: 0, to: compressedData.count, by: chunkSize) {
                            let end = min(i + chunkSize, compressedData.count)
                            let chunk = compressedData[i ..< end]
                            let chunkDecompressed = try decompressor.decompress(chunk)
                            decompressed.append(chunkDecompressed)
                        }

                        let finalChunk = try decompressor.finish()
                        decompressed.append(finalChunk)

                        await results.append(decompressed)
                    } catch {
                        XCTFail("Concurrent streaming decompression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in allResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentCompressorInstances() async throws {
        let testData = "Concurrent compressor instances test data".data(using: .utf8)!
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressor = Compressor()
                        try compressor.initialize(level: .bestCompression)
                        let compressed = try compressor.compress(testData)
                        let final = try compressor.finish()
                        var fullCompressed = compressed
                        fullCompressed.append(final)

                        await results.append(fullCompressed)
                    } catch {
                        XCTFail("Concurrent compressor instances failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDecompressorInstances() async throws {
        let testData = "Concurrent decompressor instances test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let decompressor = Decompressor()
                        try decompressor.initialize()
                        let decompressed = try decompressor.decompress(compressedData)
                        let final = try decompressor.finish()
                        var fullDecompressed = decompressed
                        fullDecompressed.append(final)

                        await results.append(fullDecompressed)
                    } catch {
                        XCTFail("Concurrent decompressor instances failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in allResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDifferentCompressionLevels() async throws {
        let testData = "Concurrent different compression levels test data".data(using: .utf8)!
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for level in levels {
                group.addTask {
                    do {
                        let compressed = try ZLib.compress(testData, level: level)
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent compression with level \(level) failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, levels.count)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testThreadSafetyOfAPI() async throws {
        // This test verifies that our Swift API is thread-safe
        // by testing that multiple threads can use separate instances
        // without interfering with each other
        let testData = "Thread safety test data".data(using: .utf8)!
        let iterations = 10
        let compressionResults = ResultsBox<Data>()
        let decompressionResults = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< iterations {
                group.addTask {
                    do {
                        // Each thread gets its own instances
                        let compressor = Compressor()
                        let decompressor = Decompressor()

                        // Initialize with different levels to test variety
                        let level = CompressionLevel(rawValue: Int32(i % 4)) ?? .defaultCompression
                        try compressor.initialize(level: level)
                        try decompressor.initialize()

                        // Compress
                        let compressed = try compressor.compress(testData, flush: .finish)

                        // Decompress
                        let decompressed = try decompressor.decompress(compressed)

                        await compressionResults.append(compressed)
                        await decompressionResults.append(decompressed)
                    } catch {
                        XCTFail("Thread safety test failed: \(error)")
                    }
                }
            }
        }

        let allCompressionResults = await compressionResults.getAll()
        let allDecompressionResults = await decompressionResults.getAll()
        XCTAssertEqual(allCompressionResults.count, iterations)
        XCTAssertEqual(allDecompressionResults.count, iterations)

        // Verify all results are correct
        for decompressed in allDecompressionResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

    /// Test concurrent compression and decompression with different windowBits values.
    ///
    /// Note: `.auto` is only valid for decompression (inflate), not for compression (deflate).
    /// Using `.auto` for compression will result in a stream error (Z_STREAM_ERROR).
    /// Only use `.raw`, `.deflate`, or `.gzip` for compression.
    func testConcurrentDifferentWindowBits() async throws {
        let testData = "Concurrent different window bits test data".data(using: .utf8)!
        let windowBits: [WindowBits] = [.raw, .gzip, .deflate] // Only valid for compression
        let results = ResultsBox<(windowBits: WindowBits, compressed: Data)>()

        await withTaskGroup(of: Void.self) { group in
            for bits in windowBits {
                group.addTask {
                    do {
                        let compressor = Compressor()
                        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: bits)
                        let compressed = try compressor.compress(testData)
                        let final = try compressor.finish()
                        var fullCompressed = compressed
                        fullCompressed.append(final)

                        await results.append((bits, fullCompressed))
                    } catch {
                        XCTFail("Concurrent compression with windowBits \(bits) failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, windowBits.count)

        // Verify all compressed data can be decompressed with the correct windowBits
        for (bits, compressed) in allResults {
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: bits)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDictionaryOperations() async throws {
        let dictionary = "test dictionary".data(using: .utf8)!
        let testData = "data that uses dictionary".data(using: .utf8)!
        let iterations = 50
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressor = Compressor()
                        try compressor.initialize(level: .defaultCompression)
                        try compressor.setDictionary(dictionary)
                        let compressed = try compressor.compress(testData)
                        let final = try compressor.finish()
                        var fullCompressed = compressed
                        fullCompressed.append(final)

                        await results.append(fullCompressed)
                    } catch {
                        XCTFail("Concurrent dictionary compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed with dictionary
        for compressed in allResults {
            let decompressor = Decompressor()
            try decompressor.initialize()
            let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStringOperations() async throws {
        let testString = "Concurrent string operations test string"
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try testString.compressed()
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent string compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed to original string
        for compressed in allResults {
            let decompressedString = try String.decompressed(from: compressed)
            XCTAssertEqual(decompressedString, testString)
        }
    }

    func testConcurrentDataExtensions() async throws {
        let testData = "Concurrent data extensions test data".data(using: .utf8)!
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try testData.compressed()
                        await results.append(compressed)
                    } catch {
                        XCTFail("Concurrent data extension compression failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try compressed.decompressed()
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentErrorHandling() async throws {
        let invalidData = Data([0x78, 0x9C, 0x01, 0x00, 0x00, 0xFF, 0xFF]) // Incomplete zlib data
        let iterations = 50
        let results = ResultsBox<Error>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        _ = try ZLib.decompress(invalidData)
                        XCTFail("Expected error for invalid data")
                    } catch {
                        await results.append(error)
                    }
                }
            }
        }

        let allErrors = await results.getAll()
        XCTAssertEqual(allErrors.count, iterations)
    }

    func testConcurrentMemoryPressure() async throws {
        let testData = "Concurrent memory pressure test data".data(using: .utf8)!
        let iterations = 100
        let results = ResultsBox<Data>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        // Create large temporary data to simulate memory pressure
                        let largeData = String(repeating: "large data for memory pressure test ", count: 1000).data(using: .utf8)!
                        let compressed = try ZLib.compress(largeData)
                        let decompressed = try ZLib.decompress(compressed)
                        XCTAssertEqual(decompressed, largeData)

                        // Now compress the actual test data
                        let testCompressed = try ZLib.compress(testData)
                        await results.append(testCompressed)
                    } catch {
                        XCTFail("Concurrent memory pressure test failed: \(error)")
                    }
                }
            }
        }

        let allResults = await results.getAll()
        XCTAssertEqual(allResults.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in allResults {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStressTest() async throws {
        let testData = "Concurrent stress test data".data(using: .utf8)!
        let iterations = 200
        let compressionResults = ResultsBox<Data>()
        let decompressionResults = ResultsBox<Data>()

        // Concurrent compression
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let compressed = try ZLib.compress(testData)
                        await compressionResults.append(compressed)
                    } catch {
                        XCTFail("Concurrent stress compression failed: \(error)")
                    }
                }
            }
        }

        let allCompressionResults = await compressionResults.getAll()
        XCTAssertEqual(allCompressionResults.count, iterations)

        // Concurrent decompression
        await withTaskGroup(of: Void.self) { group in
            for compressed in allCompressionResults {
                group.addTask {
                    do {
                        let decompressed = try ZLib.decompress(compressed)
                        await decompressionResults.append(decompressed)
                    } catch {
                        XCTFail("Concurrent stress decompression failed: \(error)")
                    }
                }
            }
        }

        let allDecompressionResults = await decompressionResults.getAll()
        XCTAssertEqual(allDecompressionResults.count, iterations)

        // Verify all results match original data
        for decompressed in allDecompressionResults {
            XCTAssertEqual(decompressed, testData)
        }
    }
}
