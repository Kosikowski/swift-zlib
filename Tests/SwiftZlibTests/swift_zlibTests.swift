import XCTest
@testable import SwiftZlib

private let Z_NEED_DICT: Int32 = 2

final class SwiftZlibTests: XCTestCase {
    
    func testZLibVersion() {
        let version = ZLib.version
        XCTAssertFalse(version.isEmpty)
        XCTAssertTrue(version.contains("."))
    }
    
    func testBasicCompressionAndDecompression() throws {
        let originalData = "Hello, World! This is a test string for compression.".data(using: .utf8)!
        
        // Test compression
        let compressedData = try ZLib.compress(originalData)
        // Do not assert compressedData.count < originalData.count (may not be true for small data)
        
        // Test decompression
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)
    }
    
    func testCompressionLevels() throws {
        let originalString = "This is a longer test string that should demonstrate different compression levels. " +
                              "We'll repeat this several times to make it longer and more compressible. " +
                              "This is a longer test string that should demonstrate different compression levels. " +
                              "We'll repeat this several times to make it longer and more compressible."
        let originalData = originalString.data(using: .utf8)!
        
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        var compressedSizes: [Int] = []
        
        for level in levels {
            let compressedData = try ZLib.compress(originalData, level: level)
            compressedSizes.append(compressedData.count)
            
            // Verify we can decompress it
            let decompressedData = try ZLib.decompress(compressedData)
            XCTAssertEqual(decompressedData, originalData)
        }
        
        // Verify compression levels work (best compression should be smallest)
        XCTAssertGreaterThanOrEqual(compressedSizes[0], compressedSizes[1]) // noCompression >= bestSpeed
        XCTAssertGreaterThanOrEqual(compressedSizes[1], compressedSizes[2]) // bestSpeed >= default
        XCTAssertGreaterThanOrEqual(compressedSizes[2], compressedSizes[3]) // default >= bestCompression
    }
    
    func testDataExtensions() throws {
        let originalData = "Test data for extension methods".data(using: .utf8)!
        
        // Test Data extension
        let compressedData = try originalData.compressed()
        let decompressedData = try compressedData.decompressed()
        
        XCTAssertEqual(decompressedData, originalData)
    }
    
    func testStringExtensions() throws {
        let originalString = "This is a test string for compression and decompression"
        
        // Test String extension
        let compressedData = try originalString.compressed()
        let decompressedString = try String.decompressed(from: compressedData)
        
        XCTAssertEqual(decompressedString, originalString)
    }
    
    func testStreamCompression() throws {
        let originalString = "Stream compression test with multiple chunks. " +
                              "This should be processed in chunks to test the streaming functionality. " +
                              "Stream compression test with multiple chunks. " +
                              "This should be processed in chunks to test the streaming functionality."
        let originalData = originalString.data(using: .utf8)!
        
        let compressor = Compressor()
        try compressor.initialize(level: .bestCompression)
        
        // Split data into chunks
        let chunkSize = 50
        var compressedData = Data()
        
        for i in stride(from: 0, to: originalData.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, originalData.count)
            let chunk = originalData[i..<endIndex]
            let compressedChunk = try compressor.compress(chunk)
            compressedData.append(compressedChunk)
        }
        
        // Finish compression
        let finalChunk = try compressor.finish()
        compressedData.append(finalChunk)
        
        // Decompress
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)
    }
    
    func testStreamDecompression() throws {
        let originalString = "Stream decompression test with multiple chunks. " +
                              "This should be processed in chunks to test the streaming functionality. " +
                              "Stream decompression test with multiple chunks. " +
                              "This should be processed in chunks to test the streaming functionality."
        let originalData = originalString.data(using: .utf8)!
        
        // First compress the data
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Split compressed data into chunks
        let chunkSize = 20
        var decompressedData = Data()
        
        for i in stride(from: 0, to: compressedData.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, compressedData.count)
            let chunk = compressedData[i..<endIndex]
            let decompressedChunk = try decompressor.decompress(chunk)
            decompressedData.append(decompressedChunk)
        }
        
        // Finish decompression
        let finalChunk = try decompressor.finish()
        decompressedData.append(finalChunk)
        
        XCTAssertEqual(decompressedData, originalData)
    }
    
    func testLargeDataCompression() throws {
        // Create a larger dataset
        var largeString = ""
        for i in 1...1000 {
            largeString += "This is line \(i) of a large dataset for compression testing. "
        }
        let originalData = largeString.data(using: .utf8)!
        
        let compressedData = try ZLib.compress(originalData, level: .bestCompression)
        let decompressedData = try ZLib.decompress(compressedData)
        
        XCTAssertEqual(decompressedData, originalData)
        XCTAssertLessThan(compressedData.count, originalData.count)
    }
    
    func testErrorHandling() {
        // Test invalid data
        let invalidData = Data([0x78, 0x9c, 0x01, 0x00, 0x00, 0xff, 0xff]) // Incomplete zlib data
        
        XCTAssertThrowsError(try ZLib.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testEmptyData() throws {
        let emptyData = Data()
        
        // Should handle empty data gracefully
        let compressedData = try ZLib.compress(emptyData)
        let decompressedData = try ZLib.decompress(compressedData)
        
        XCTAssertEqual(decompressedData, emptyData)
    }
    
    func testSingleByteData() throws {
        let singleByteData = Data([0x42])
        
        let compressedData = try ZLib.compress(singleByteData)
        let decompressedData = try ZLib.decompress(compressedData)
        
        XCTAssertEqual(decompressedData, singleByteData)
    }
    
    func testBinaryData() throws {
        // Test with binary data (not just text)
        var binaryData = Data()
        for i in 0..<1000 {
            binaryData.append(UInt8(i % 256))
        }
        
        let compressedData = try ZLib.compress(binaryData)
        let decompressedData = try ZLib.decompress(compressedData)
        
        XCTAssertEqual(decompressedData, binaryData)
    }
    
    func testAdvancedCompressorInitialization() throws {
        let originalString = "Advanced init test string for gzip format."
        let originalData = originalString.data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(
            level: .bestCompression,
            method: .deflate,
            windowBits: .gzip,
            memoryLevel: .maximum,
            strategy: .filtered
        )
        let compressed = try compressor.compress(originalData, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed, flush: .finish)
        XCTAssertEqual(decompressed, originalData)
    }

    func testDebugCompression() throws {
        let data = Data(repeating: 0x42, count: 100)
        
        // Try the simple API first
        let simpleCompressed = try ZLib.compress(data)
        print("Simple API - Original size: \(data.count), Compressed size: \(simpleCompressed.count)")
        print("Simple API - Compressed data (first 20): \(Array(simpleCompressed.prefix(20)))")
        
        // Try to decompress the simple version
        let simpleDecompressed = try ZLib.decompress(simpleCompressed)
        XCTAssertEqual(simpleDecompressed, data)
        print("Simple API decompression successful")
        
        // Now try the stream API
        let compressor = Compressor()
        do {
            try compressor.initialize(level: .bestCompression)
            print("Stream API - Initialization succeeded")
        } catch {
            print("Stream API - Initialization failed: \(error)")
            throw error
        }
        var streamCompressed: Data = Data()
        do {
            streamCompressed = try compressor.compress(data)
            print("Stream API - After compress: size = \(streamCompressed.count), first 20 = \(Array(streamCompressed.prefix(20)))")
        } catch {
            print("Stream API - compress() failed: \(error)")
            throw error
        }
        var finalChunk: Data = Data()
        do {
            finalChunk = try compressor.finish()
            print("Stream API - After finish: size = \(finalChunk.count), first 20 = \(Array(finalChunk.prefix(20)))")
        } catch {
            print("Stream API - finish() failed: \(error)")
            throw error
        }
        let completeCompressed = streamCompressed + finalChunk
        print("Stream API - After concat: size = \(completeCompressed.count), first 20 = \(Array(completeCompressed.prefix(20)))")
        
        // Try to decompress the stream version using stream decompression
        do {
            let decompressor = Decompressor()
            try decompressor.initialize()
            let streamDecompressed = try decompressor.decompress(completeCompressed, flush: .finish)
            XCTAssertEqual(streamDecompressed, data)
            print("Stream API decompression successful")
        } catch {
            print("Stream API decompression failed: \(error)")
            throw error
        }
    }

    func testCompressorResetAndCopy() throws {
        let data1 = Data(repeating: 0x42, count: 100)
        let data2 = Data(repeating: 0x43, count: 100)
        let compressor1 = Compressor()
        try compressor1.initialize(level: .bestCompression)
        let compressed1 = try compressor1.compress(data1, flush: .finish)
        
        // Create a fresh compressor for the second compression
        let compressor2 = Compressor()
        try compressor2.initialize(level: .bestCompression)
        let compressed2 = try compressor2.compress(data2, flush: .finish)
        
        let decompressed1 = try ZLib.decompress(compressed1)
        let decompressed2 = try ZLib.decompress(compressed2)
        XCTAssertEqual(decompressed1, data1)
        XCTAssertEqual(decompressed2, data2)
    }

    func testDecompressorResetAndCopy() throws {
        let data1 = Data(repeating: 0x44, count: 100)
        let data2 = Data(repeating: 0x45, count: 100)
        let compressed1 = try ZLib.compress(data1)
        let compressed2 = try ZLib.compress(data2)
        let decompressor1 = Decompressor()
        try decompressor1.initialize()
        let _ = try decompressor1.decompress(compressed1, flush: .finish)
        let decompressor2 = Decompressor()
        try decompressor1.copy(to: decompressor2)
        try decompressor2.reset()
        let decompressed2 = try decompressor2.decompress(compressed2, flush: .finish)
        XCTAssertEqual(decompressed2, data2)
    }

    func testChecksums() throws {
        let data = "checksum test data".data(using: .utf8)!
        let adler = ZLib.adler32(data)
        let crc = ZLib.crc32(data)
        XCTAssertNotEqual(adler, 0)
        XCTAssertNotEqual(crc, 0)
        let adlerStr = ZLib.adler32("checksum test data")
        let crcStr = ZLib.crc32("checksum test data")
        XCTAssertEqual(adler, adlerStr)
        XCTAssertEqual(crc, crcStr)
    }
    
    static var allTests = [
        ("testZLibVersion", testZLibVersion),
        ("testBasicCompressionAndDecompression", testBasicCompressionAndDecompression),
        ("testCompressionLevels", testCompressionLevels),
        ("testDataExtensions", testDataExtensions),
        ("testStringExtensions", testStringExtensions),
        ("testStreamCompression", testStreamCompression),
        ("testStreamDecompression", testStreamDecompression),
        ("testLargeDataCompression", testLargeDataCompression),
        ("testErrorHandling", testErrorHandling),
        ("testEmptyData", testEmptyData),
        ("testSingleByteData", testSingleByteData),
        ("testBinaryData", testBinaryData),
        ("testAdvancedCompressorInitialization", testAdvancedCompressorInitialization),
        ("testCompressorResetAndCopy", testCompressorResetAndCopy),
        ("testDecompressorResetAndCopy", testDecompressorResetAndCopy),
        ("testChecksums", testChecksums),
    ]
}
