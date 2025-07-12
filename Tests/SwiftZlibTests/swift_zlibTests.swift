import XCTest
@testable import SwiftZlib

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
        XCTAssertLessThan(compressedData.count, originalData.count)
        
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
    ]
}
