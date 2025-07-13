@testable import SwiftZlib
import XCTest

final class ConcurrencyTests: XCTestCase {
    
    //
    // Only per-instance concurrency is valid for zlib and this wrapper.
    // Each thread must use its own Compressor/Decompressor instance.
    // Sharing a single instance across threads is not supported and is undefined behavior.
    //
    // All concurrency tests below ensure that each thread uses its own instance.
    //

    func testConcurrentCompression() throws {
        let testData = "Concurrent compression test data".data(using: .utf8)!
        let iterations = 10
        let queue = DispatchQueue(label: "test.concurrent.compression", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        // Test that multiple threads can use separate ZLib instances concurrently
        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressed = try ZLib.compress(testData)
                    lock.lock()
                    results.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDecompression() throws {
        let testData = "Concurrent decompression test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 10
        let queue = DispatchQueue(label: "test.concurrent.decompression", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        // Test that multiple threads can use separate ZLib instances concurrently
        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let decompressed = try ZLib.decompress(compressedData)
                    lock.lock()
                    results.append(decompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent decompression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in results {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentMixedOperations() throws {
        let testStrings = [
            "First concurrent test string",
            "Second concurrent test string",
            "Third concurrent test string",
            "Fourth concurrent test string",
        ]
        let testData = testStrings.map { $0.data(using: .utf8)! }

        let queue = DispatchQueue(label: "test.concurrent.mixed", attributes: .concurrent)
        let group = DispatchGroup()
        var compressedResults: [(index: Int, data: Data)] = []
        var decompressedResults: [Data] = Array(repeating: Data(), count: testData.count)
        let lock = NSLock()
        var errors: [Error] = []

        // Compress all data concurrently with index tracking
        for (index, data) in testData.enumerated() {
            queue.async(group: group) {
                do {
                    let compressed = try ZLib.compress(data)
                    lock.lock()
                    compressedResults.append((index: index, data: compressed))
                    lock.unlock()
                } catch {
                    lock.lock()
                    errors.append(error)
                    lock.unlock()
                }
            }
        }

        group.wait()

        // Check for compression errors
        XCTAssertEqual(errors.count, 0, "Compression errors: \(errors)")
        XCTAssertEqual(compressedResults.count, testData.count)

        // Sort compressed results by index to maintain order
        compressedResults.sort { $0.index < $1.index }

        // Now decompress all compressed data concurrently
        errors.removeAll()
        for (index, compressed) in compressedResults {
            queue.async(group: group) {
                do {
                    let decompressed = try ZLib.decompress(compressed)
                    lock.lock()
                    decompressedResults[index] = decompressed
                    lock.unlock()
                } catch {
                    lock.lock()
                    errors.append(error)
                    lock.unlock()
                }
            }
        }

        group.wait()

        // Check for decompression errors
        XCTAssertEqual(errors.count, 0, "Decompression errors: \(errors)")

        // Verify results match original data
        for (i, decompressed) in decompressedResults.enumerated() {
            // Convert to strings for more reliable comparison
            let originalString = String(data: testData[i], encoding: .utf8) ?? ""
            let decompressedString = String(data: decompressed, encoding: .utf8) ?? ""
            XCTAssertEqual(decompressedString, originalString, "Decompressed data at index \(i) doesn't match original")

            // Also verify byte-by-byte comparison
            XCTAssertEqual(decompressed, testData[i], "Decompressed data at index \(i) doesn't match original bytes")
        }
    }

    func testConcurrentStreamingCompression() throws {
        let testData = "Concurrent streaming compression test data".data(using: .utf8)!
        let iterations = 5
        let queue = DispatchQueue(label: "test.concurrent.streaming.compression", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        // Test that multiple threads can use separate Compressor instances concurrently
        for _ in 0 ..< iterations {
            queue.async(group: group) {
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

                    lock.lock()
                    results.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent streaming compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStreamingDecompression() throws {
        let testData = "Concurrent streaming decompression test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 5
        let queue = DispatchQueue(label: "test.concurrent.streaming.decompression", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        // Test that multiple threads can use separate Decompressor instances concurrently
        for _ in 0 ..< iterations {
            queue.async(group: group) {
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

                    lock.lock()
                    results.append(decompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent streaming decompression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in results {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentCompressorInstances() throws {
        let testData = "Concurrent compressor instances test data".data(using: .utf8)!
        let iterations = 100
        let queue = DispatchQueue(label: "test.concurrent.compressor.instances", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressor = Compressor()
                    try compressor.initialize(level: .bestCompression)
                    let compressed = try compressor.compress(testData)
                    let final = try compressor.finish()
                    var fullCompressed = compressed
                    fullCompressed.append(final)

                    lock.lock()
                    results.append(fullCompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent compressor instances failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDecompressorInstances() throws {
        let testData = "Concurrent decompressor instances test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(testData)
        let iterations = 100
        let queue = DispatchQueue(label: "test.concurrent.decompressor.instances", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let decompressor = Decompressor()
                    try decompressor.initialize()
                    let decompressed = try decompressor.decompress(compressedData)
                    let final = try decompressor.finish()
                    var fullDecompressed = decompressed
                    fullDecompressed.append(final)

                    lock.lock()
                    results.append(fullDecompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent decompressor instances failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all decompressed data matches original
        for decompressed in results {
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDifferentCompressionLevels() throws {
        let testData = "Concurrent different compression levels test data".data(using: .utf8)!
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        let queue = DispatchQueue(label: "test.concurrent.compression.levels", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for level in levels {
            queue.async(group: group) {
                do {
                    let compressed = try ZLib.compress(testData, level: level)
                    lock.lock()
                    results.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent compression with level \(level) failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, levels.count)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testThreadSafetyOfAPI() throws {
        // This test verifies that our Swift API is thread-safe
        // by testing that multiple threads can use separate instances
        // without interfering with each other
        let testData = "Thread safety test data".data(using: .utf8)!
        let iterations = 10
        let queue = DispatchQueue(label: "test.thread.safety", attributes: .concurrent)
        let group = DispatchGroup()
        var compressionResults: [Data] = []
        var decompressionResults: [Data] = []
        let lock = NSLock()

        for i in 0 ..< iterations {
            queue.async(group: group) {
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

                    lock.lock()
                    compressionResults.append(compressed)
                    decompressionResults.append(decompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Thread safety test failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(compressionResults.count, iterations)
        XCTAssertEqual(decompressionResults.count, iterations)

        // Verify all results are correct
        for decompressed in decompressionResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

    /// Test concurrent compression and decompression with different windowBits values.
    ///
    /// Note: `.auto` is only valid for decompression (inflate), not for compression (deflate).
    /// Using `.auto` for compression will result in a stream error (Z_STREAM_ERROR).
    /// Only use `.raw`, `.deflate`, or `.gzip` for compression.
    func testConcurrentDifferentWindowBits() throws {
        let testData = "Concurrent different window bits test data".data(using: .utf8)!
        let windowBits: [WindowBits] = [.raw, .gzip, .deflate] // Only valid for compression
        let queue = DispatchQueue(label: "test.concurrent.window.bits", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [(windowBits: WindowBits, compressed: Data)] = []
        let lock = NSLock()

        for bits in windowBits {
            queue.async(group: group) {
                do {
                    let compressor = Compressor()
                    try compressor.initializeAdvanced(level: .defaultCompression, windowBits: bits)
                    let compressed = try compressor.compress(testData)
                    let final = try compressor.finish()
                    var fullCompressed = compressed
                    fullCompressed.append(final)

                    lock.lock()
                    results.append((bits, fullCompressed))
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent compression with windowBits \(bits) failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, windowBits.count)

        // Verify all compressed data can be decompressed with the correct windowBits
        for (bits, compressed) in results {
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: bits)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentDictionaryOperations() throws {
        let dictionary = "test dictionary".data(using: .utf8)!
        let testData = "data that uses dictionary".data(using: .utf8)!
        let iterations = 50
        let queue = DispatchQueue(label: "test.concurrent.dictionary", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressor = Compressor()
                    try compressor.initialize(level: .defaultCompression)
                    try compressor.setDictionary(dictionary)
                    let compressed = try compressor.compress(testData)
                    let final = try compressor.finish()
                    var fullCompressed = compressed
                    fullCompressed.append(final)

                    lock.lock()
                    results.append(fullCompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent dictionary compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed with dictionary
        for compressed in results {
            let decompressor = Decompressor()
            try decompressor.initialize()
            let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStringOperations() throws {
        let testString = "Concurrent string operations test string"
        let iterations = 100
        let queue = DispatchQueue(label: "test.concurrent.string", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressed = try testString.compressed()
                    lock.lock()
                    results.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent string compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed to original string
        for compressed in results {
            let decompressedString = try String.decompressed(from: compressed)
            XCTAssertEqual(decompressedString, testString)
        }
    }

    func testConcurrentDataExtensions() throws {
        let testData = "Concurrent data extensions test data".data(using: .utf8)!
        let iterations = 100
        let queue = DispatchQueue(label: "test.concurrent.data.extensions", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressed = try testData.compressed()
                    lock.lock()
                    results.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent data extension compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try compressed.decompressed()
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentErrorHandling() throws {
        let invalidData = Data([0x78, 0x9C, 0x01, 0x00, 0x00, 0xFF, 0xFF]) // Incomplete zlib data
        let iterations = 50
        let queue = DispatchQueue(label: "test.concurrent.error.handling", attributes: .concurrent)
        let group = DispatchGroup()
        var errorCount = 0
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    _ = try ZLib.decompress(invalidData)
                    XCTFail("Expected error for invalid data")
                } catch {
                    lock.lock()
                    errorCount += 1
                    lock.unlock()
                }
            }
        }

        group.wait()
        XCTAssertEqual(errorCount, iterations)
    }

    func testConcurrentMemoryPressure() throws {
        let testData = "Concurrent memory pressure test data".data(using: .utf8)!
        let iterations = 100
        let queue = DispatchQueue(label: "test.concurrent.memory.pressure", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [Data] = []
        let lock = NSLock()

        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    // Create large temporary data to simulate memory pressure
                    let largeData = String(repeating: "large data for memory pressure test ", count: 1000).data(using: .utf8)!
                    let compressed = try ZLib.compress(largeData)
                    let decompressed = try ZLib.decompress(compressed)
                    XCTAssertEqual(decompressed, largeData)

                    // Now compress the actual test data
                    let testCompressed = try ZLib.compress(testData)
                    lock.lock()
                    results.append(testCompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent memory pressure test failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(results.count, iterations)

        // Verify all compressed data can be decompressed
        for compressed in results {
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
    }

    func testConcurrentStressTest() throws {
        let testData = "Concurrent stress test data".data(using: .utf8)!
        let iterations = 200
        let queue = DispatchQueue(label: "test.concurrent.stress", attributes: .concurrent)
        let group = DispatchGroup()
        var compressionResults: [Data] = []
        var decompressionResults: [Data] = []
        let lock = NSLock()

        // Concurrent compression
        for _ in 0 ..< iterations {
            queue.async(group: group) {
                do {
                    let compressed = try ZLib.compress(testData)
                    lock.lock()
                    compressionResults.append(compressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent stress compression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(compressionResults.count, iterations)

        // Concurrent decompression
        for compressed in compressionResults {
            queue.async(group: group) {
                do {
                    let decompressed = try ZLib.decompress(compressed)
                    lock.lock()
                    decompressionResults.append(decompressed)
                    lock.unlock()
                } catch {
                    XCTFail("Concurrent stress decompression failed: \(error)")
                }
            }
        }

        group.wait()
        XCTAssertEqual(decompressionResults.count, iterations)

        // Verify all results match original data
        for decompressed in decompressionResults {
            XCTAssertEqual(decompressed, testData)
        }
    }

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
} 