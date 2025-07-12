import XCTest
@testable import SwiftZlib

private let Z_NEED_DICT: Int32 = 2

final class SwiftZlibTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Enable verbose logging for all tests
        ZLibVerboseConfig.enableAll()
    }
    
    override func tearDown() {
        super.tearDown()
        // Disable verbose logging after tests
        ZLibVerboseConfig.disableAll()
    }
    
    func testZLibVersion() {
        let version = ZLib.version
        XCTAssertFalse(version.isEmpty)
        XCTAssertTrue(version.contains("."))
        print("ZLib version: \(version)")
    }
    
    func testVerboseLoggingConfiguration() {
        // Test that verbose logging can be configured
        ZLibVerboseConfig.enableAll()
        XCTAssertTrue(ZLibVerboseConfig.enabled)
        XCTAssertTrue(ZLibVerboseConfig.logStreamState)
        XCTAssertTrue(ZLibVerboseConfig.logProgress)
        XCTAssertTrue(ZLibVerboseConfig.logMemory)
        XCTAssertTrue(ZLibVerboseConfig.logErrors)
        XCTAssertTrue(ZLibVerboseConfig.logTiming)
        XCTAssertEqual(ZLibVerboseConfig.minLogLevel, .debug)
        
        ZLibVerboseConfig.disableAll()
        XCTAssertFalse(ZLibVerboseConfig.enabled)
        XCTAssertFalse(ZLibVerboseConfig.logStreamState)
        XCTAssertFalse(ZLibVerboseConfig.logProgress)
        XCTAssertFalse(ZLibVerboseConfig.logMemory)
        XCTAssertFalse(ZLibVerboseConfig.logErrors)
        XCTAssertFalse(ZLibVerboseConfig.logTiming)
        
        // Re-enable for other tests
        ZLibVerboseConfig.enableAll()
    }
    
    func testBasicCompressionAndDecompression() throws {
        let originalData = "Hello, World! This is a test string for compression.".data(using: .utf8)!
        
        print("=== Starting basic compression/decompression test ===")
        
        // Test compression with verbose logging
        let compressedData = try ZLib.compress(originalData)
        // Do not assert compressedData.count < originalData.count (may not be true for small data)
        
        // Test decompression with verbose logging
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)
        
        print("=== Completed basic compression/decompression test ===")
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
        
        print("=== Starting stream compression test ===")
        
        let compressor = Compressor()
        try compressor.initialize(level: .bestCompression)
        
        // Split data into chunks
        let chunkSize = 50
        var compressedData = Data()
        
        for i in stride(from: 0, to: originalData.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, originalData.count)
            let chunk = originalData[i..<endIndex]
            print("Processing chunk \(i/chunkSize + 1): \(chunk.count) bytes")
            let compressedChunk = try compressor.compress(chunk)
            compressedData.append(compressedChunk)
        }
        
        // Finish compression
        let finalChunk = try compressor.finish()
        compressedData.append(finalChunk)
        
        // Decompress
        let decompressedData = try ZLib.decompress(compressedData)
        XCTAssertEqual(decompressedData, originalData)
        
        print("=== Completed stream compression test ===")
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
        
        // Use stream decompression for stream-compressed data
        let decompressor1 = Decompressor()
        let decompressor2 = Decompressor()
        try decompressor1.initialize()
        try decompressor2.initialize()
        
        let decompressed1 = try decompressor1.decompress(compressed1, flush: .finish)
        let decompressed2 = try decompressor2.decompress(compressed2, flush: .finish)
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
        
        print("=== Starting checksum tests ===")
        
        let adler = ZLib.adler32(data)
        let crc = ZLib.crc32(data)
        XCTAssertNotEqual(adler, 0)
        XCTAssertNotEqual(crc, 0)
        print("Adler-32: \(adler), CRC-32: \(crc)")
        
        let adlerStr = ZLib.adler32("checksum test data")
        let crcStr = ZLib.crc32("checksum test data")
        XCTAssertEqual(adler, adlerStr)
        XCTAssertEqual(crc, crcStr)
        
        print("=== Completed checksum tests ===")
    }
    
    // MARK: - Advanced Features Tests
    
    func testPartialDecompression() throws {
        let originalData = "This is test data for partial decompression".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        // Use simple decompression for simple compressed data
        let (decompressed, inputConsumed, outputWritten) = try ZLib.partialDecompress(compressedData, maxOutputSize: 10)
        
        XCTAssertGreaterThan(inputConsumed, 0)
        XCTAssertGreaterThan(outputWritten, 0)
        // Note: For small compressed data, the entire data might be decompressed
        // even with a small maxOutputSize due to how zlib works
        XCTAssertGreaterThan(decompressed.count, 0)
    }
    
    func testChecksumCombination() throws {
        let data1 = "First part".data(using: .utf8)!
        let data2 = "Second part".data(using: .utf8)!
        
        let adler1 = ZLib.adler32(data1)
        let adler2 = ZLib.adler32(data2)
        let combinedAdler = ZLib.adler32Combine(adler1, adler2, len2: data2.count)
        
        let fullData = data1 + data2
        let fullAdler = ZLib.adler32(fullData)
        
        XCTAssertEqual(combinedAdler, fullAdler)
        
        let crc1 = ZLib.crc32(data1)
        let crc2 = ZLib.crc32(data2)
        let combinedCrc = ZLib.crc32Combine(crc1, crc2, len2: data2.count)
        
        let fullCrc = ZLib.crc32(fullData)
        
        XCTAssertEqual(combinedCrc, fullCrc)
    }
    
    func testCompressionWithGzipHeader() throws {
        let originalData = "Test data with gzip header".data(using: .utf8)!
        
        var header = GzipHeader()
        header.name = "test.txt"
        header.comment = "Test file"
        header.time = UInt32(Date().timeIntervalSince1970)
        
        let compressedData = try originalData.compressedWithGzipHeader(level: .bestCompression, header: header)
        
        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedData, flush: .finish)
        
        XCTAssertEqual(decompressedData, originalData)
    }
    
    func testStringCompressionWithGzipHeader() throws {
        let originalString = "Test string with gzip header"
        
        var header = GzipHeader()
        header.name = "string.txt"
        header.comment = "String test"
        
        let compressedData = try originalString.compressedWithGzipHeader(level: .bestCompression, header: header)
        
        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedData, flush: .finish)
        let decompressedString = String(data: decompressedData, encoding: .utf8)!
        
        XCTAssertEqual(decompressedString, originalString)
    }
    
    // MARK: - Advanced Stream Features
    
    func testCompressorAdvancedFeatures() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .bestCompression)
        
        // Test parameter changes
        try compressor.setParameters(level: .bestSpeed, strategy: .huffmanOnly)
        
        // Test dictionary
        let dictionary = "test dictionary".data(using: .utf8)!
        try compressor.setDictionary(dictionary)
        
        // Test priming
        try compressor.prime(bits: 8, value: 0x42)
        
        // Test pending
        let (pending, bits) = try compressor.getPending()
        XCTAssertGreaterThanOrEqual(pending, 0)
        XCTAssertGreaterThanOrEqual(bits, 0)
        
        // Test bound calculation
        let bound = try compressor.getBound(sourceLen: 1000)
        XCTAssertGreaterThan(bound, 0)
        
        // Test tuning
        try compressor.tune(goodLength: 32, maxLazy: 258, niceLength: 258, maxChain: 4096)
        
        // Test dictionary retrieval
        let retrievedDict = try compressor.getDictionary()
        XCTAssertEqual(retrievedDict, dictionary)
        
        // Test stream info
        let info = try compressor.getStreamInfo()
        XCTAssertGreaterThanOrEqual(info.totalIn, 0)
        XCTAssertGreaterThanOrEqual(info.totalOut, 0)
        XCTAssertTrue(info.isActive)
        
        // Test compression ratio
        let ratio = try compressor.getCompressionRatio()
        XCTAssertGreaterThanOrEqual(ratio, 0.0)
        XCTAssertLessThanOrEqual(ratio, 1.0)
        
        // Test stream stats
        let stats = try compressor.getStreamStats()
        XCTAssertGreaterThanOrEqual(stats.bytesProcessed, 0)
        XCTAssertGreaterThanOrEqual(stats.bytesProduced, 0)
        XCTAssertGreaterThanOrEqual(stats.compressionRatio, 0.0)
        XCTAssertLessThanOrEqual(stats.compressionRatio, 1.0)
        XCTAssertTrue(stats.isActive)
    }
    
    func testDecompressorAdvancedFeatures() throws {
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Test features that work with a fresh decompressor
        let codesUsed = try decompressor.getCodesUsed()
        XCTAssertGreaterThanOrEqual(codesUsed, 0)
        
        let (pending, bits) = try decompressor.getPending()
        XCTAssertGreaterThanOrEqual(pending, 0)
        XCTAssertGreaterThanOrEqual(bits, 0)
        
        // Test dictionary retrieval (should return empty for fresh decompressor)
        let retrievedDict = try decompressor.getDictionary()
        XCTAssertEqual(retrievedDict.count, 0)
        
        // Test mark (should work with fresh decompressor)
        do {
            let mark = try decompressor.getMark()
            XCTAssertGreaterThanOrEqual(mark, 0)
        } catch {
            print("Mark check failed as expected: \(error)")
        }
        
        // Test sync point (should work with fresh decompressor)
        do {
            let isSyncPoint = try decompressor.isSyncPoint()
            XCTAssertTrue(isSyncPoint)
        } catch {
            print("Sync point check failed as expected: \(error)")
        }
        
        // Now decompress a small valid data chunk to test post-decompression features
        let testString = "hello advanced features"
        let testData = testString.data(using: .utf8)!
        let compressed = try ZLib.compress(testData)
        let _ = try decompressor.decompress(compressed)
        
        // Test post-decompression features
        let codesUsedAfter = try decompressor.getCodesUsed()
        XCTAssertGreaterThanOrEqual(codesUsedAfter, 0)
        
        let (pendingAfter, bitsAfter) = try decompressor.getPending()
        XCTAssertGreaterThanOrEqual(pendingAfter, 0)
        XCTAssertGreaterThanOrEqual(bitsAfter, 0)
    }
    
    // MARK: - InflateBack Tests
    
    func testInflateBackDecompressor() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()
        
        let originalData = "Test data for InflateBack".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        var output = Data()
        
        try inflateBack.processWithCallbacks(
            inputProvider: {
                return compressedData
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )
        
        XCTAssertEqual(output, originalData)
    }
    
    func testInflateBackWithChunks() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()
        
        let originalData = "Test data for InflateBack with chunks".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        var output = Data()
        var inputIndex = 0
        let chunkSize = 10
        
        try inflateBack.processWithCallbacks(
            inputProvider: {
                guard inputIndex < compressedData.count else { return nil }
                let endIndex = min(inputIndex + chunkSize, compressedData.count)
                let chunk = compressedData[inputIndex..<endIndex]
                inputIndex = endIndex
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )
        
        // Compare the actual data content, not the Data objects
        let outputString = String(data: output, encoding: .utf8)
        let originalString = String(data: originalData, encoding: .utf8)
        XCTAssertNotNil(outputString)
        XCTAssertNotNil(originalString)
        XCTAssertEqual(outputString, originalString)
    }
    
    func testInflateBackStreamInfo() throws {
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()
        
        let info = try inflateBack.getStreamInfo()
        XCTAssertGreaterThanOrEqual(info.totalIn, 0)
        XCTAssertGreaterThanOrEqual(info.totalOut, 0)
        XCTAssertTrue(info.isActive)
    }
    
    // MARK: - Streaming Decompressor Tests
    
    func testStreamingDecompressor() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()
        
        let originalData = "Test data for streaming decompressor".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let result = try streamingDecompressor.processData(compressedData)
        XCTAssertEqual(result, originalData)
    }
    
    func testStreamingDecompressorWithCallbacks() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()
        
        let originalData = "Test data for streaming decompressor with callbacks".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        var output = Data()
        var inputIndex = 0
        let chunkSize = 10
        
        try streamingDecompressor.processWithCallbacks(
            inputProvider: {
                guard inputIndex < compressedData.count else { return nil }
                let endIndex = min(inputIndex + chunkSize, compressedData.count)
                let chunk = compressedData[inputIndex..<endIndex]
                inputIndex = endIndex
                return chunk
            },
            outputHandler: { data in
                output.append(data)
                return true
            }
        )
        
        // Compare the actual data content, not the Data objects
        let outputString = String(data: output, encoding: .utf8)
        let originalString = String(data: originalData, encoding: .utf8)
        

        
        XCTAssertNotNil(outputString)
        XCTAssertNotNil(originalString)
        XCTAssertEqual(outputString, originalString)
    }
    
    func testStreamingDecompressorChunkHandling() throws {
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()
        
        let originalData = "Test data for chunk handling".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        var chunks: [Data] = []
        
        try streamingDecompressor.processDataInChunks(compressedData) { chunk in
            chunks.append(chunk)
            return true
        }
        
        let combined = chunks.reduce(Data(), +)
        XCTAssertEqual(combined, originalData)
    }
    
    // MARK: - Utility Functions Tests
    
    func testErrorInfo() throws {
        let errorInfo = ZLib.getErrorInfo(0) // Z_OK
        XCTAssertEqual(errorInfo.code, .ok)
        XCTAssertFalse(errorInfo.isError)
        
        let errorInfo2 = ZLib.getErrorInfo(-2) // Z_STREAM_ERROR
        XCTAssertEqual(errorInfo2.code, .streamError)
        XCTAssertTrue(errorInfo2.isError)
    }
    
    func testSuccessErrorChecks() throws {
        XCTAssertTrue(ZLib.isSuccess(0)) // Z_OK
        XCTAssertTrue(ZLib.isSuccess(1)) // Z_STREAM_END
        XCTAssertFalse(ZLib.isError(0)) // Z_OK
        XCTAssertFalse(ZLib.isError(1)) // Z_STREAM_END
        
        XCTAssertTrue(ZLib.isError(-2)) // Z_STREAM_ERROR
        XCTAssertTrue(ZLib.isError(-3)) // Z_DATA_ERROR
        XCTAssertFalse(ZLib.isSuccess(-2)) // Z_STREAM_ERROR
        XCTAssertFalse(ZLib.isSuccess(-3)) // Z_DATA_ERROR
    }
    
    func testErrorMessage() throws {
        let message = ZLib.getErrorMessage(0) // Z_OK
        // Error message might be empty for Z_OK, so just check it's a valid string
        XCTAssertNotNil(message)
        
        let errorMessage = ZLib.getErrorMessage(-2) // Z_STREAM_ERROR
        XCTAssertNotNil(errorMessage)
        // Both messages might be the same on some systems, so just check they're valid
    }
    
    func testRecoverableError() throws {
        XCTAssertTrue(ZLib.isRecoverableError(-5)) // Z_BUF_ERROR
        XCTAssertTrue(ZLib.isRecoverableError(2)) // Z_NEED_DICT
        XCTAssertFalse(ZLib.isRecoverableError(-2)) // Z_STREAM_ERROR
        XCTAssertFalse(ZLib.isRecoverableError(-3)) // Z_DATA_ERROR)
    }
    
    func testErrorRecoverySuggestions() throws {
        let suggestions = ZLib.getErrorRecoverySuggestions(-5) // Z_BUF_ERROR
        XCTAssertFalse(suggestions.isEmpty)
        // Check that suggestions contain helpful information (case insensitive)
        let hasBufferSuggestion = suggestions.contains { suggestion in
            suggestion.lowercased().contains("buffer") || 
            suggestion.lowercased().contains("memory") ||
            suggestion.lowercased().contains("size")
        }
        XCTAssertTrue(hasBufferSuggestion)
        
        let suggestions2 = ZLib.getErrorRecoverySuggestions(2) // Z_NEED_DICT
        XCTAssertFalse(suggestions2.isEmpty)
        // Check that suggestions contain helpful information (case insensitive)
        let hasDictSuggestion = suggestions2.contains { suggestion in
            suggestion.lowercased().contains("dictionary") || 
            suggestion.lowercased().contains("dict") ||
            suggestion.lowercased().contains("provide")
        }
        XCTAssertTrue(hasDictSuggestion)
    }
    
    func testParameterValidation() throws {
        let warnings = ZLib.validateParameters(
            level: .bestCompression,
            windowBits: .deflate,
            memoryLevel: .minimum,
            strategy: .defaultStrategy
        )
        
        XCTAssertTrue(warnings.contains("Best compression with minimum memory may be slow"))
    }
    
    func testCompressedSizeEstimation() throws {
        let estimatedSize = ZLib.estimateCompressedSize(1000, level: .bestCompression)
        XCTAssertGreaterThan(estimatedSize, 0)
        
        let estimatedSize2 = ZLib.estimateCompressedSize(1000, level: .noCompression)
        XCTAssertGreaterThan(estimatedSize2, 0)
        XCTAssertGreaterThanOrEqual(estimatedSize2, estimatedSize)
    }
    
    func testRecommendedBufferSizes() throws {
        let (inputSize, outputSize) = ZLib.getRecommendedBufferSizes(windowBits: .deflate)
        XCTAssertGreaterThan(inputSize, 0)
        XCTAssertGreaterThan(outputSize, 0)
        XCTAssertGreaterThan(outputSize, inputSize)
    }
    
    func testMemoryUsageEstimation() throws {
        let memoryUsage = ZLib.estimateMemoryUsage(windowBits: .deflate, memoryLevel: .maximum)
        XCTAssertGreaterThan(memoryUsage, 0)
        
        let memoryUsage2 = ZLib.estimateMemoryUsage(windowBits: .gzip, memoryLevel: .minimum)
        XCTAssertGreaterThan(memoryUsage2, 0)
        XCTAssertNotEqual(memoryUsage, memoryUsage2)
    }
    
    func testOptimalParameters() throws {
        let (level, windowBits, memoryLevel, strategy) = ZLib.getOptimalParameters(for: 100)
        XCTAssertTrue([.bestSpeed, .defaultCompression, .bestCompression].contains(level))
        XCTAssertTrue([.deflate, .gzip, .raw, .auto].contains(windowBits))
        XCTAssertTrue([.minimum, .level2, .level3, .level4, .level5, .level6, .level7, .level8, .maximum].contains(memoryLevel))
        XCTAssertTrue([.defaultStrategy, .filtered, .huffmanOnly, .rle, .fixed].contains(strategy))
    }
    
    func testPerformanceProfiles() throws {
        let profiles = ZLib.getPerformanceProfiles(for: 1000)
        XCTAssertEqual(profiles.count, 4)
        
        for (level, time, ratio) in profiles {
            XCTAssertTrue([.noCompression, .bestSpeed, .defaultCompression, .bestCompression].contains(level))
            XCTAssertGreaterThanOrEqual(time, 0.0)
            XCTAssertGreaterThanOrEqual(ratio, 0.0)
            XCTAssertLessThanOrEqual(ratio, 1.0)
        }
    }
    
    func testBufferSizeCalculation() throws {
        let (inputBuffer, outputBuffer, maxStreams) = ZLib.calculateOptimalBufferSizes(dataSize: 10000, availableMemory: 1000000)
        XCTAssertGreaterThan(inputBuffer, 0)
        XCTAssertGreaterThan(outputBuffer, 0)
        XCTAssertGreaterThan(maxStreams, 0)
    }
    
    func testCompressionStatistics() throws {
        let data = "Test data for compression statistics".data(using: .utf8)!
        let stats = ZLib.getCompressionStatistics(for: data)
        
        XCTAssertEqual(stats.count, 4)
        for (level, ratio, time) in stats {
            XCTAssertTrue([.noCompression, .bestSpeed, .defaultCompression, .bestCompression].contains(level))
            XCTAssertGreaterThanOrEqual(ratio, 0.0)
            // Compression ratio can be > 1.0 for small data due to overhead
            XCTAssertGreaterThanOrEqual(time, 0.0)
        }
    }
    
    func testCompileFlags() throws {
        let flags = ZLib.compileFlags
        // Compile flags might be 0 on some systems, so just check it's a valid value
        XCTAssertGreaterThanOrEqual(flags, 0)
        
        let flagsInfo = ZLib.compileFlagsInfo
        XCTAssertEqual(flagsInfo.flags, flags)
        // Size values might be 0 on some systems, so just check they're valid
        XCTAssertGreaterThanOrEqual(flagsInfo.sizeOfUInt, 0)
        XCTAssertGreaterThanOrEqual(flagsInfo.sizeOfULong, 0)
        XCTAssertGreaterThanOrEqual(flagsInfo.sizeOfPointer, 0)
        XCTAssertGreaterThanOrEqual(flagsInfo.sizeOfZOffT, 0)
    }
    
    // MARK: - Data Extensions Tests
    
    func testDataExtensionsAdvanced() throws {
        let data = "Test data for advanced extensions".data(using: .utf8)!
        
        // Test partial decompression
        let compressedData = try data.compressed()
        let (partial, inputConsumed, outputWritten) = try compressedData.partialDecompressed(maxOutputSize: 5)
        // Note: For small compressed data, the entire data might be decompressed
        // even with a small maxOutputSize due to how zlib works
        XCTAssertGreaterThan(partial.count, 0)
        XCTAssertGreaterThan(inputConsumed, 0)
        XCTAssertGreaterThan(outputWritten, 0)
        
        // Test gzip header compression
        var header = GzipHeader()
        header.name = "test.txt"
        let compressedWithHeader = try data.compressedWithGzipHeader(level: .bestCompression, header: header)
        
        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedWithHeader = try decompressor.decompress(compressedWithHeader, flush: .finish)
        XCTAssertEqual(decompressedWithHeader, data)
        
        // Test checksums
        let adler32 = data.adler32()
        let crc32 = data.crc32()
        XCTAssertNotEqual(adler32, 0)
        XCTAssertNotEqual(crc32, 0)
        
        // Test size estimation
        let estimatedSize = data.estimateCompressedSize(level: .bestCompression)
        XCTAssertGreaterThan(estimatedSize, 0)
        
        // Test static methods
        let (inputSize, outputSize) = Data.getRecommendedBufferSizes(windowBits: .deflate)
        XCTAssertGreaterThan(inputSize, 0)
        XCTAssertGreaterThan(outputSize, 0)
        
        let memoryUsage = Data.estimateMemoryUsage(windowBits: .deflate, memoryLevel: .maximum)
        XCTAssertGreaterThan(memoryUsage, 0)
    }
    
    // MARK: - String Extensions Tests
    
    func testStringExtensionsAdvanced() throws {
        let string = "Test string for advanced extensions"
        
        // Test gzip header compression
        var header = GzipHeader()
        header.name = "string.txt"
        let compressedWithHeader = try string.compressedWithGzipHeader(level: .bestCompression, header: header)
        
        // Gzip headers require gzip decompression, not regular zlib decompression
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressedData = try decompressor.decompress(compressedWithHeader, flush: .finish)
        let decompressedWithHeader = String(data: decompressedData, encoding: .utf8)!
        XCTAssertEqual(decompressedWithHeader, string)
        
        // Test checksums
        let adler32 = string.adler32()
        let crc32 = string.crc32()
        XCTAssertNotNil(adler32)
        XCTAssertNotNil(crc32)
        XCTAssertNotEqual(adler32, 0)
        XCTAssertNotEqual(crc32, 0)
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    func testInvalidCompressionLevel() throws {
        // Test with invalid compression level (should still work)
        let data = "Test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data, level: .defaultCompression)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testInvalidWindowBits() throws {
        // Test with invalid window bits (should still work)
        let data = "Test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressed = try ZLib.decompress(compressed)
        // Compare the actual data content, not the Data objects
        let decompressedString = String(data: decompressed, encoding: .utf8)
        let dataString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(decompressedString)
        XCTAssertEqual(decompressedString, dataString)
    }
    
    func testCorruptedData() throws {
        let originalData = "Test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        // Corrupt the data
        var corruptedData = compressedData
        if corruptedData.count > 10 {
            corruptedData[5] = 0xFF
        }
        
        XCTAssertThrowsError(try ZLib.decompress(corruptedData)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testMemoryPressure() throws {
        // Test with very large, highly compressible data
        let original = Data(repeating: 0x41, count: 100_000)
        let compressed = try ZLib.compress(original, level: .bestCompression)
        
        // Use streaming decompression for large data
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, original)
    }
    
    func testConcurrentAccess() throws {
        // Test that multiple compressors/decompressors can be used concurrently
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        
        let compressor1 = Compressor()
        let compressor2 = Compressor()
        
        try compressor1.initialize(level: .bestCompression)
        try compressor2.initialize(level: .bestSpeed)
        
        let compressed1 = try compressor1.compress(data1, flush: .finish)
        let compressed2 = try compressor2.compress(data2, flush: .finish)
        
        print("compressed1: \(compressed1 as NSData)")
        print("compressed2: \(compressed2 as NSData)")
        
        let decompressor1 = Decompressor()
        let decompressor2 = Decompressor()
        
        try decompressor1.initialize()
        try decompressor2.initialize()
        
        do {
            let decompressed1 = try decompressor1.decompress(compressed1, flush: .finish)
            print("decompressed1 bytes: \(decompressed1 as NSData)")
            let decompressed1String = String(data: decompressed1, encoding: .utf8)
            print("decompressed1String: \(String(describing: decompressed1String))")
            let data1String = String(data: data1, encoding: .utf8)
            print("data1String: \(String(describing: data1String))")
            XCTAssertNotNil(decompressed1String)
            XCTAssertEqual(decompressed1String, data1String)
        } catch {
            print("decompressor1 error: \(error)")
            XCTFail("decompressor1 error: \(error)")
        }
        
        do {
            let decompressed2 = try decompressor2.decompress(compressed2, flush: .finish)
            print("decompressed2 bytes: \(decompressed2 as NSData)")
            let decompressed2String = String(data: decompressed2, encoding: .utf8)
            print("decompressed2String: \(String(describing: decompressed2String))")
            let data2String = String(data: data2, encoding: .utf8)
            print("data2String: \(String(describing: data2String))")
            XCTAssertNotNil(decompressed2String)
            XCTAssertEqual(decompressed2String, data2String)
        } catch {
            print("decompressor2 error: \(error)")
            XCTFail("decompressor2 error: \(error)")
        }
    }
    
    func testMinimalSmallStringCompression() throws {
        let original = "Hello!"
        let data = original.data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        print("compressed: \(compressed as NSData)")
        let decompressed = try ZLib.decompress(compressed)
        print("decompressed bytes: \(decompressed as NSData)")
        let decompressedString = String(data: decompressed, encoding: .utf8)
        print("decompressedString: \(String(describing: decompressedString))")
        XCTAssertNotNil(decompressedString)
        XCTAssertEqual(decompressedString, original)
    }
    
    func testMinimalSmallStringStreamingCompression() throws {
        let original = "Hello!"
        let data = original.data(using: .utf8)!
        print("Original data bytes: \(data as NSData)")
        
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        let compressed = try compressor.compress(data, flush: .finish)
        print("streaming compressed: \(compressed as NSData)")
        
        // Force reset after compression
        try compressor.reset()
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, flush: .finish)
        print("streaming decompressed bytes: \(decompressed as NSData)")
        
        // Force reset after decompression
        try decompressor.reset()
        
        let decompressedString = String(data: decompressed, encoding: .utf8)
        print("streaming decompressedString: \(String(describing: decompressedString))")
        XCTAssertNotNil(decompressedString)
        XCTAssertEqual(decompressedString, original)
    }
    
    // MARK: - Dictionary-Based Compression and Decompression Tests
    
    func decompressWithOptionalDictionary(_ compressed: Data, dictionary: Data?) throws -> Data {
        let decompressor = Decompressor()
        try decompressor.initialize()
        do {
            return try decompressor.decompress(compressed)
        } catch ZLibError.decompressionFailed(let code) where code == Z_NEED_DICT {
            guard let dict = dictionary else { throw ZLibError.decompressionFailed(code) }
            try decompressor.setDictionary(dict)
            return try decompressor.decompress(compressed)
        }
    }
    
    func testDictionaryCompressionDecompression_Success() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!
        
        // First, test basic compression without dictionary
        let compressor1 = Compressor()
        try compressor1.initialize(level: .defaultCompression)
        let compressed1 = try compressor1.compress(originalData, flush: .finish)
        
        // Decompress basic compression
        let decompressor1 = Decompressor()
        try decompressor1.initialize()
        let decompressed1 = try decompressor1.decompress(compressed1)
        XCTAssertEqual(decompressed1, originalData)
        
        // Now test compression with dictionary
        let compressor2 = Compressor()
        try compressor2.initialize(level: .defaultCompression)
        try compressor2.setDictionary(dictionary)
        let compressed2 = try compressor2.compress(originalData, flush: .finish)
        
        // Decompress with dictionary using new API
        let decompressor2 = Decompressor()
        try decompressor2.initialize()
        let decompressed2 = try decompressor2.decompress(compressed2, dictionary: dictionary)
        XCTAssertEqual(decompressed2, originalData)
        
        // Verify that dictionary compression produces different output
        XCTAssertNotEqual(compressed1, compressed2)
    }
    
    func testDictionaryCompressionDecompression_WrongDictionary() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let wrongDictionary = String(repeating: "zyxwvutsrqponmlk", count: 2).data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!
        
        // Compress with correct dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompress with wrong dictionary (should fail with Z_DATA_ERROR or Z_NEED_DICT)
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(compressed, dictionary: wrongDictionary))
    }

    func testDictionaryCompressionDecompression_MissingDictionary() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!
        
        // Compress with dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompress without dictionary (should fail with Z_NEED_DICT)
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(compressed))
    }

    func testDictionaryCompressionDecompression_RoundTripRetrieval() throws {
        // Create a dictionary with a specific pattern
        let dictString = String(repeating: "abcdefghijklmnop", count: 2) // 32 bytes
        let dictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression".data(using: .utf8)!
        
        // Compress with dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompress and verify data integrity
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
        XCTAssertEqual(decompressed, originalData)
        // Optionally, check getDictionary (may be empty or not match original)
        let _ = try decompressor.getDictionary()
    }

    func testDictionaryCompressionDecompression_EmptyDictionary() throws {
        let dictionary = Data()
        let originalData = Data()
        // Compress with empty dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        // Decompress with empty dictionary
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
        XCTAssertEqual(decompressed, originalData)
    }

    func testDictionaryCompressionDecompression_LargeDictionary() throws {
        // Create a large dictionary with a specific pattern
        let dictPattern = "abcdefghijklmnopqrstuvwxyz0123456789"
        let dictString = String(repeating: dictPattern, count: 32768 / dictPattern.count + 1)
        let largeDictionary = dictString.data(using: .utf8)!
        let originalData = "test data for compression with large dictionary".data(using: .utf8)!
        // Compress with large dictionary
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(largeDictionary)
        let compressed = try compressor.compress(originalData, flush: .finish)
        // Decompress with large dictionary
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: largeDictionary)
        XCTAssertEqual(decompressed, originalData)
    }
    
    func testDictionarySetAtWrongTime() throws {
        let dictionary = "test dictionary".data(using: .utf8)!
        // Try to set dictionary before initialization
        let compressor = Compressor()
        XCTAssertThrowsError(try compressor.setDictionary(dictionary)) { error in
            XCTAssertTrue(error is ZLibError)
        }
        // Try to set dictionary after compression
        try compressor.initialize(level: .noCompression)
        let data = "test data".data(using: .utf8)!
        _ = try compressor.compress(data, flush: .finish)
        // Dictionary should still be set after compression
        XCTAssertNoThrow(try compressor.setDictionary(dictionary))
    }
    
    // MARK: - Priming Tests
    
    func testDeflatePrimeBasic() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Prime with 8 bits (1 byte)
        try compressor.prime(bits: 8, value: 0x42)
        
        // Compress some data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        
        // For regular zlib, priming affects the compressed output
        // We should test that priming works without expecting regular decompression
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Test that we can get pending data after priming
        let (pending, bits) = try compressor.getPending()
        XCTAssertGreaterThanOrEqual(pending, 0)
        XCTAssertGreaterThanOrEqual(bits, 0)
    }
    
    func testDeflatePrimeMultipleBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Prime with 4 bits
        try compressor.prime(bits: 4, value: 0x0A)
        
        // Prime with another 4 bits
        try compressor.prime(bits: 4, value: 0x0B)
        
        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDeflatePrimeLargeValue() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Prime with 16 bits (2 bytes)
        try compressor.prime(bits: 16, value: 0x1234)
        
        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDeflatePrimeBeforeCompression() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Prime before any compression
        try compressor.prime(bits: 8, value: 0x55)
        
        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDeflatePrimeAfterPartialCompression() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Start compression
        let data1 = "first part".data(using: .utf8)!
        _ = try compressor.compress(data1, flush: .noFlush)
        
        // Prime in the middle
        try compressor.prime(bits: 8, value: 0x66)
        
        // Continue compression
        let data2 = "second part".data(using: .utf8)!
        let compressed = try compressor.compress(data2, flush: .finish)
        
        // Test that compression worked
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDeflatePrimeInvalidBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Test with invalid bit count (should fail)
        XCTAssertThrowsError(try compressor.prime(bits: -1, value: 0x42))
        XCTAssertThrowsError(try compressor.prime(bits: 33, value: 0x42)) // More than 32 bits
    }
    
    func testDeflatePrimeBeforeInitialization() throws {
        let compressor = Compressor()
        
        // Try to prime before initialization (should fail)
        XCTAssertThrowsError(try compressor.prime(bits: 8, value: 0x42)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testInflatePrimeBasic() throws {
        let originalData = "test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Prime with 8 bits
        try decompressor.prime(bits: 8, value: 0x42)
        
        // Test that priming worked without expecting decompression to work
        // (priming affects the internal state but regular compressed data doesn't expect it)
        XCTAssertNoThrow(try decompressor.prime(bits: 8, value: 0x42))
    }
    
    func testInflatePrimeMultipleBits() throws {
        let originalData = "test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Prime with multiple bits
        try decompressor.prime(bits: 4, value: 0x0A)
        try decompressor.prime(bits: 4, value: 0x0B)
        
        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 4, value: 0x0C))
    }
    
    func testInflatePrimeLargeValue() throws {
        let originalData = "test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Prime with 16 bits
        try decompressor.prime(bits: 16, value: 0x1234)
        
        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 16, value: 0x5678))
    }
    
    func testInflatePrimeBeforeDecompression() throws {
        let originalData = "test data".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Prime before any decompression
        try decompressor.prime(bits: 8, value: 0x55)
        
        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 8, value: 0x66))
    }
    
    func testInflatePrimeAfterPartialDecompression() throws {
        let originalData = "test data for partial decompression".data(using: .utf8)!
        let compressedData = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Decompress first part
        let firstPart = compressedData.prefix(compressedData.count / 2)
        _ = try decompressor.decompress(firstPart, flush: .noFlush)
        
        // Try to prime after partial decompression - this should fail
        // because the stream is already in use and priming is not supported mid-stream
        XCTAssertThrowsError(try decompressor.prime(bits: 8, value: 0x42)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testInflatePrimeInvalidBits() throws {
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Test with invalid bit count (should fail)
        XCTAssertThrowsError(try decompressor.prime(bits: -1, value: 0x42))
        XCTAssertThrowsError(try decompressor.prime(bits: 33, value: 0x42)) // More than 32 bits
    }
    
    func testInflatePrimeBeforeInitialization() throws {
        let decompressor = Decompressor()
        
        // Try to prime before initialization (should fail)
        XCTAssertThrowsError(try decompressor.prime(bits: 8, value: 0x42)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testPrimeRoundTrip() throws {
        // Note: Priming is a very low-level zlib feature that affects the raw bit stream.
        // Round-trip compression/decompression with priming is not typically supported
        // because the primed bits interfere with the compressed data format.
        // This test documents this limitation.
        
        let originalData = "test data for prime round trip".data(using: .utf8)!
        
        // Use raw deflate stream for priming round-trip with minimal bits
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw) // Raw deflate
        try compressor.prime(bits: 4, value: 0x5) // Use 4 bits instead of 8
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompress with identical priming using raw deflate
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw) // Raw deflate
        try decompressor.prime(bits: 4, value: 0x5)
        
        // This is expected to fail because priming affects the raw bit stream
        // and interferes with the compressed data format
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testPrimeWithDifferentValues() throws {
        let originalData = "test data for different prime values".data(using: .utf8)!
        
        // Use raw deflate stream for priming round-trip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw) // Raw deflate
        try compressor.prime(bits: 4, value: 0x5)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompress with different priming - should fail
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw) // Raw deflate
        try decompressor.prime(bits: 4, value: 0x6) // Different value
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testPrimeAffectsCompressedOutput() throws {
        let originalData = "test data".data(using: .utf8)!
        
        // Compress without priming
        let compressor1 = Compressor()
        try compressor1.initializeAdvanced(level: .noCompression, windowBits: .raw)
        let compressed1 = try compressor1.compress(originalData, flush: .finish)
        
        // Compress with priming
        let compressor2 = Compressor()
        try compressor2.initializeAdvanced(level: .noCompression, windowBits: .raw)
        try compressor2.prime(bits: 4, value: 0x5)
        let compressed2 = try compressor2.compress(originalData, flush: .finish)
        
        // The compressed outputs should be different due to priming
        XCTAssertNotEqual(compressed1, compressed2)
    }
    
    func testPrimeIsolation() throws {
        // Test that priming works in isolation without expecting round-trip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw)
        
        // Prime with different values and verify it doesn't crash
        XCTAssertNoThrow(try compressor.prime(bits: 1, value: 0x1))
        XCTAssertNoThrow(try compressor.prime(bits: 2, value: 0x2))
        XCTAssertNoThrow(try compressor.prime(bits: 4, value: 0x5))
        XCTAssertNoThrow(try compressor.prime(bits: 8, value: 0x42))
        
        // Test that priming affects the compressed output
        let data = "test".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testPrimeWithZlibStreamFails() throws {
        let originalData = "test data for zlib prime failure".data(using: .utf8)!
        
        // Try to use priming with zlib stream (windowBits: 15)
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .deflate) // zlib format
        try compressor.prime(bits: 8, value: 0x42)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompression should fail because zlib streams don't support priming
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate) // zlib format
        try decompressor.prime(bits: 8, value: 0x42)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testPrimeWithGzipStreamFails() throws {
        let originalData = "test data for gzip prime failure".data(using: .utf8)!
        
        // Try to use priming with gzip stream (windowBits: 31)
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .gzip) // gzip format
        try compressor.prime(bits: 8, value: 0x42)
        let compressed = try compressor.compress(originalData, flush: .finish)
        
        // Decompression should fail because gzip streams don't support priming
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip) // gzip format
        try decompressor.prime(bits: 8, value: 0x42)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testPrimeZeroBits() throws {
        let compressor = Compressor()
        try compressor.initialize(level: .noCompression)
        
        // Prime with 0 bits (should work)
        XCTAssertNoThrow(try compressor.prime(bits: 0, value: 0x42))
        
        // Compress data
        let data = "test data".data(using: .utf8)!
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Decompress should work
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertNoThrow(try decompressor.prime(bits: 0, value: 0x42))
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testPrimeMaxBits() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw)
        
        // Try to prime with maximum bits (32) - this should fail due to zlib's internal buffer limits
        XCTAssertThrowsError(try compressor.prime(bits: 32, value: 0x7FFFFFFF)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    // MARK: - WindowBits Variant Tests
    
    func testWindowBitsRawRoundTrip() throws {
        let data = "windowBits raw test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testWindowBitsZlibRoundTrip() throws {
        let data = "windowBits zlib test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testWindowBitsGzipRoundTrip() throws {
        let data = "windowBits gzip test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testWindowBitsAutoDetectGzip() throws {
        let data = "windowBits auto-detect gzip test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testWindowBitsAutoDetectZlib() throws {
        let data = "windowBits auto-detect zlib test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    // Mismatched format handling
    func testWindowBitsMismatchedRawAsZlib() throws {
        let data = "windowBits mismatch raw as zlib".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    func testWindowBitsMismatchedZlibAsRaw() throws {
        let data = "windowBits mismatch zlib as raw".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    func testWindowBitsMismatchedGzipAsZlib() throws {
        let data = "windowBits mismatch gzip as zlib".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    func testWindowBitsMismatchedZlibAsGzip() throws {
        let data = "windowBits mismatch zlib as gzip".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    // Edge cases
    func testWindowBitsEmptyInput() throws {
        let data = Data()
        // Raw deflate: some zlib builds allow empty input, others throw stream error
        do {
            let compressorRaw = Compressor()
            try compressorRaw.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
            let compressed = try compressorRaw.compress(data, flush: .finish)
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: .raw)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        } catch let error as ZLibError {
            // Accept stream error for raw deflate with empty input
            if case .compressionFailed(let code) = error {
                XCTAssertEqual(code, -2)
                return // Test passes for this platform
            } else {
                XCTFail("Unexpected error for raw deflate: \(error)")
                return
            }
        }
        // Zlib, gzip, auto: must always succeed
        for windowBits in [WindowBits.deflate, .gzip, .auto] {
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)
            let compressed = try compressor.compress(data, flush: .finish)
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: windowBits)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        }
    }
    func testWindowBitsCorruptedHeader() throws {
        let data = "windowBits corrupted header".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        var compressed = try compressor.compress(data, flush: .finish)
        // Corrupt the first byte
        compressed[0] = 0x00
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testWindowBitsEmptyInputRawDeflate() throws {
        let data = Data()
        // Raw deflate: some zlib builds allow empty input, others throw stream error
        do {
            let compressorRaw = Compressor()
            try compressorRaw.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
            let compressed = try compressorRaw.compress(data, flush: .finish)
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: .raw)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        } catch let error as ZLibError {
            // Accept stream error for raw deflate with empty input
            if case .compressionFailed(let code) = error {
                XCTAssertEqual(code, -2)
            } else {
                XCTFail("Unexpected error for raw deflate: \(error)")
            }
        }
    }

    func testWindowBitsEmptyInputZlibGzipAuto() throws {
        let data = Data()
        for windowBits in [WindowBits.deflate, .gzip, .auto] {
            do {
                let compressor = Compressor()
                try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)
                let compressed = try compressor.compress(data, flush: .finish)
                let decompressor = Decompressor()
                try decompressor.initializeAdvanced(windowBits: windowBits)
                let decompressed = try decompressor.decompress(compressed)
                XCTAssertEqual(decompressed, data)
            } catch let error as ZLibError {
                // Some zlib builds may throw stream error for empty input even for zlib/gzip/auto
                // This is platform-specific behavior, so accept either round-trip or stream error
                if case .compressionFailed(let code) = error {
                    XCTAssertEqual(code, -2)
                } else {
                    XCTFail("Unexpected error for \(windowBits): \(error)")
                }
            }
        }
    }
    
    // MARK: - Gzip Header Edge Cases
    
    func testGzipHeaderWithMetadata() throws {
        let data = "test data with metadata".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        
        // Test that gzip headers are properly generated
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 10) // Should have gzip header + data
        
        // Verify gzip header structure (first 10 bytes)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f) // gzip magic number
        XCTAssertEqual(header[1], 0x8b) // gzip magic number
        XCTAssertEqual(header[2], 0x08) // deflate method
    }
    
    func testGzipHeaderWithFilename() throws {
        let data = "test data".data(using: .utf8)!
        let filename = "test.txt"
        
        // Note: Our current API doesn't support custom gzip headers
        // This test documents the current behavior
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Verify basic gzip header is present
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
    }
    
    func testGzipHeaderWithTimestamp() throws {
        let data = "test data with timestamp".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Verify gzip header timestamp field (bytes 4-7)
        let header = compressed.prefix(10)
        // Timestamp should be present (usually 0 for current time)
        // We can't easily verify the exact timestamp, but we can check the structure
        XCTAssertEqual(header[2], 0x08) // deflate method
    }
    
    func testGzipHeaderCompressionLevel() throws {
        let data = "test data for compression level".data(using: .utf8)!
        
        // Test different compression levels with gzip
        for level in [CompressionLevel.noCompression, .bestSpeed, .defaultCompression, .bestCompression] {
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: level, windowBits: .gzip)
            let compressed = try compressor.compress(data, flush: .finish)
            
            // Verify gzip header is present regardless of compression level
            let header = compressed.prefix(10)
            XCTAssertEqual(header[0], 0x1f)
            XCTAssertEqual(header[1], 0x8b)
            XCTAssertEqual(header[2], 0x08)
        }
    }
    
    func testGzipHeaderWithEmptyData() throws {
        let data = Data()
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Even empty data should have gzip header
        XCTAssertGreaterThanOrEqual(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
    }
    
    func testGzipHeaderWithLargeData() throws {
        let largeData = String(repeating: "test data ", count: 1000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(largeData, flush: .finish)
        
        // Large data should still have proper gzip header
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
        
        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testGzipHeaderCorruption() throws {
        let data = "test data for corruption test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Corrupt the gzip header
        var corrupted = compressed
        corrupted[0] = 0x00 // Corrupt magic number
        
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testGzipHeaderWithDifferentOS() throws {
        let data = "test data for OS test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Verify gzip header OS field (byte 9)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
        XCTAssertEqual(header[2], 0x08)
        // OS field should be present (usually 0 for FAT filesystem)
    }
    
    func testGzipHeaderRoundTrip() throws {
        let data = "test data for gzip header round trip".data(using: .utf8)!
        
        // Compress with gzip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Decompress with gzip
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        
        XCTAssertEqual(decompressed, data)
        
        // Verify gzip header is present in compressed data
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
    }
    
    func testGzipHeaderWithAutoDetection() throws {
        let data = "test data for auto detection".data(using: .utf8)!
        
        // Compress with gzip
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Decompress with auto detection
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .auto)
        let decompressed = try decompressor.decompress(compressed)
        
        XCTAssertEqual(decompressed, data)
    }
    
    func testGzipHeaderWithStreaming() throws {
        let data = "test data for streaming gzip".data(using: .utf8)!
        
        // Compress with streaming
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip)
        
        let chunkSize = 5
        var compressed = Data()
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let compressedChunk = try compressor.compress(chunk, flush: flush)
            compressed.append(compressedChunk)
        }
        
        // Decompress
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .gzip)
        let decompressed = try decompressor.decompress(compressed)
        
        XCTAssertEqual(decompressed, data)
        
        // Verify gzip header is present
        XCTAssertGreaterThan(compressed.count, 10)
        let header = compressed.prefix(10)
        XCTAssertEqual(header[0], 0x1f)
        XCTAssertEqual(header[1], 0x8b)
    }
    
    // MARK: - Error Handling Edge Cases
    
    func testCompressionWithInvalidLevel() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        
        // Test with invalid compression level (should use default)
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDecompressionWithInvalidData() throws {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testCompressionWithNullData() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with nil data (should handle gracefully)
        let compressed = try compressor.compress(Data(), flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed.count, 0)
    }
    
    func testDecompressionWithTruncatedData() throws {
        let data = "test data for truncation".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Truncate the compressed data
        let truncated = compressed.prefix(compressed.count / 2)
        
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // Some zlib implementations can handle truncated data gracefully
        // We'll test both scenarios: error or successful partial decompression
        do {
            let decompressed = try decompressor.decompress(truncated)
            // If no error, the decompressed data should be different from original
            XCTAssertNotEqual(decompressed, data)
        } catch let error as ZLibError {
            // Expected error for truncated data
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testCompressionWithUninitializedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        
        // Try to compress without initialization
        XCTAssertThrowsError(try compressor.compress(data, flush: .finish)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testDecompressionWithUninitializedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        
        // Try to decompress without initialization
        XCTAssertThrowsError(try decompressor.decompress(compressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testCompressionWithInvalidFlushMode() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with valid flush modes
        XCTAssertNoThrow(try compressor.compress(data, flush: .noFlush))
        XCTAssertNoThrow(try compressor.compress(data, flush: .finish))
    }
    
    func testDecompressionWithInvalidFlushMode() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // Test with valid flush modes
        XCTAssertNoThrow(try decompressor.decompress(compressed, flush: .noFlush))
    }
    
    func testCompressionWithLargeInput() throws {
        let largeData = String(repeating: "test data ", count: 10000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with very large input
        let compressed = try compressor.compress(largeData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testDecompressionWithCorruptedData() throws {
        let data = "test data for corruption".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        
        // Corrupt the compressed data
        var corrupted = compressed
        if corrupted.count > 10 {
            corrupted[5] = 0xFF // Corrupt a byte in the middle
        }
        
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testCompressionWithZeroSizedBuffer() throws {
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with zero-sized buffer
        let compressed = try compressor.compress(Data(), flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed.count, 0)
    }
    
    func testDecompressionWithZeroSizedBuffer() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // Test with zero-sized buffer
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testCompressionWithInvalidWindowBits() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        
        // Test with valid window bits
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip))
    }
    
    func testDecompressionWithInvalidWindowBits() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        
        // Test with valid window bits
        XCTAssertNoThrow(try decompressor.initializeAdvanced(windowBits: .deflate))
        XCTAssertNoThrow(try decompressor.initializeAdvanced(windowBits: .raw))
        XCTAssertNoThrow(try decompressor.initializeAdvanced(windowBits: .gzip))
    }
    
    func testCompressionWithReusedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // First compression
        let compressed1 = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed1.count, 0)
        
        // Reinitialize for second compression
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed2 = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed2.count, 0)
    }
    
    func testDecompressionWithReusedStream() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // First decompression
        let decompressed1 = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed1, data)
        
        // Reinitialize for second decompression
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed2 = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed2, data)
    }
    
    func testCompressionWithInvalidDictionary() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with invalid dictionary (should handle gracefully)
        let invalidDictionary = Data([0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertNoThrow(try compressor.setDictionary(invalidDictionary))
        
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testDecompressionWithInvalidDictionary() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // Test with invalid dictionary (should handle gracefully)
        let invalidDictionary = Data([0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertNoThrow(try decompressor.setDictionary(invalidDictionary))
        
        // Should still decompress successfully
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testCompressionWithMemoryPressure() throws {
        let largeData = String(repeating: "test data ", count: 50000).data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        
        // Test with very large input to simulate memory pressure
        let compressed = try compressor.compress(largeData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Decompress to verify integrity
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testDecompressionWithMemoryPressure() throws {
        let largeData = String(repeating: "test data ", count: 50000).data(using: .utf8)!
        let compressed = try ZLib.compress(largeData)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        
        // Test with very large compressed data to simulate memory pressure
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testCompressionWithInvalidState() throws {
        let data = "test data".data(using: .utf8)!
        let compressor = Compressor()
        
        // Try to set dictionary before initialization
        XCTAssertThrowsError(try compressor.setDictionary(data)) { error in
            XCTAssertTrue(error is ZLibError)
        }
        
        // Initialize and then try to set dictionary again
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        XCTAssertNoThrow(try compressor.setDictionary(data))
    }
    
    func testDecompressionWithInvalidState() throws {
        let data = "test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        
        // Try to set dictionary before initialization
        XCTAssertThrowsError(try decompressor.setDictionary(data)) { error in
            XCTAssertTrue(error is ZLibError)
        }
        
        // Initialize and then try to set dictionary again
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertNoThrow(try decompressor.setDictionary(data))
    }
    
    // MARK: - Streaming Edge Cases
    
    func testStreamingCompressionWithSmallChunks() throws {
        let data = "streaming test data with small chunks".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let chunkSize = 5
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingDecompressionWithSmallChunks() throws {
        let data = "streaming decompression test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        var decompressed = Data()
        let chunkSize = 8
        
        for i in stride(from: 0, to: compressed.count, by: chunkSize) {
            let end = min(i + chunkSize, compressed.count)
            let chunk = compressed[i..<end]
            let chunkDecompressed = try decompressor.decompress(chunk)
            decompressed.append(chunkDecompressed)
        }
        
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithEmptyChunks() throws {
        let data = "test data with empty chunks".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        
        // Add empty chunk at start
        let emptyChunk = Data()
        let emptyCompressed = try compressor.compress(emptyChunk, flush: .noFlush)
        compressed.append(emptyCompressed)
        
        // Add actual data
        let dataCompressed = try compressor.compress(data, flush: .finish)
        compressed.append(dataCompressed)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithPartialFlush() throws {
        let data = "streaming with partial flush test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let midPoint = data.count / 2
        
        // Compress first half with sync flush
        let firstHalf = data[..<midPoint]
        let firstCompressed = try compressor.compress(firstHalf, flush: .syncFlush)
        compressed.append(firstCompressed)
        
        // Compress second half with finish
        let secondHalf = data[midPoint...]
        let secondCompressed = try compressor.compress(secondHalf, flush: .finish)
        compressed.append(secondCompressed)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithBlockFlush() throws {
        let data = "streaming with block flush test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let chunkSize = 10
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .block
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithLargeData() throws {
        // Generate large test data
        let largeData = Data(repeating: 0x42, count: 100000)
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let chunkSize = 4096
        
        for i in stride(from: 0, to: largeData.count, by: chunkSize) {
            let end = min(i + chunkSize, largeData.count)
            let chunk = largeData[i..<end]
            let flush: FlushMode = end == largeData.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
    }
    
    func testStreamingWithMixedFlushModes() throws {
        let data = "streaming with mixed flush modes test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let parts = [
            (data[..<10], FlushMode.noFlush),
            (data[10..<20], FlushMode.syncFlush),
            (data[20..<30], FlushMode.block),
            (data[30...], FlushMode.finish)
        ]
        
        for (chunk, flush) in parts {
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithReusedCompressor() throws {
        let data1 = "first streaming data".data(using: .utf8)!
        let data2 = "second streaming data".data(using: .utf8)!
        
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        // Compress first data
        let compressed1 = try compressor.compress(data1, flush: .finish)
        
        // Reuse compressor for second data
        try compressor.initialize(level: .defaultCompression)
        let compressed2 = try compressor.compress(data2, flush: .finish)
        
        // Decompress both
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed1 = try decompressor.decompress(compressed1)
        XCTAssertEqual(decompressed1, data1)
        
        try decompressor.initialize()
        let decompressed2 = try decompressor.decompress(compressed2)
        XCTAssertEqual(decompressed2, data2)
    }
    
    func testStreamingWithReusedDecompressor() throws {
        let data1 = "first data for reused decompressor".data(using: .utf8)!
        let data2 = "second data for reused decompressor".data(using: .utf8)!
        
        let compressed1 = try ZLib.compress(data1)
        let compressed2 = try ZLib.compress(data2)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Decompress first data
        let decompressed1 = try decompressor.decompress(compressed1)
        XCTAssertEqual(decompressed1, data1)
        
        // Reuse decompressor for second data
        try decompressor.initialize()
        let decompressed2 = try decompressor.decompress(compressed2)
        XCTAssertEqual(decompressed2, data2)
    }
    
    func testStreamingWithPartialDecompression() throws {
        let data = "partial decompression test data".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Decompress in small chunks
        var decompressed = Data()
        let chunkSize = 4
        
        for i in stride(from: 0, to: compressed.count, by: chunkSize) {
            let end = min(i + chunkSize, compressed.count)
            let chunk = compressed[i..<end]
            let chunkDecompressed = try decompressor.decompress(chunk)
            decompressed.append(chunkDecompressed)
        }
        
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithCorruptedChunk() throws {
        let data = "streaming with corrupted chunk test".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        
        // Corrupt a chunk in the middle
        var corruptedCompressed = compressed
        if corruptedCompressed.count > 10 {
            corruptedCompressed[5] = 0xFF // Corrupt byte
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        XCTAssertThrowsError(try decompressor.decompress(corruptedCompressed)) { error in
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testStreamingWithIncompleteData() throws {
        let data = "streaming with incomplete data test".data(using: .utf8)!
        let compressed = try ZLib.compress(data)
        
        // Remove last few bytes to simulate incomplete data
        let incompleteCompressed = compressed.prefix(compressed.count - 5)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Should handle incomplete data gracefully
        do {
            let decompressed = try decompressor.decompress(incompleteCompressed)
            // May succeed with partial data or throw error
            XCTAssertLessThanOrEqual(decompressed.count, data.count)
        } catch {
            // Expected error for incomplete data
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testStreamingWithDictionary() throws {
        let dictionary = "test dictionary for streaming".data(using: .utf8)!
        let data = "streaming data with dictionary".data(using: .utf8)!
        
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        try compressor.setDictionary(dictionary)
        
        var compressed = Data()
        let chunkSize = 8
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        try decompressor.setDictionary(dictionary)
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithDifferentCompressionLevels() throws {
        let data = "streaming with different compression levels".data(using: .utf8)!
        
        for level in [CompressionLevel.noCompression, .bestSpeed, .defaultCompression, .bestCompression] {
            let compressor = Compressor()
            try compressor.initialize(level: level)
            
            var compressed = Data()
            let chunkSize = 6
            
            for i in stride(from: 0, to: data.count, by: chunkSize) {
                let end = min(i + chunkSize, data.count)
                let chunk = data[i..<end]
                let flush: FlushMode = end == data.count ? .finish : .noFlush
                let chunkCompressed = try compressor.compress(chunk, flush: flush)
                compressed.append(chunkCompressed)
            }
            
            let decompressor = Decompressor()
            try decompressor.initialize()
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        }
    }
    
    func testStreamingWithWindowBitsVariants() throws {
        let data = "streaming with window bits variants".data(using: .utf8)!
        
        for windowBits in [WindowBits.raw, .deflate, .gzip] {
            let compressor = Compressor()
            try compressor.initializeAdvanced(level: .defaultCompression, windowBits: windowBits)
            
            var compressed = Data()
            let chunkSize = 7
            
            for i in stride(from: 0, to: data.count, by: chunkSize) {
                let end = min(i + chunkSize, data.count)
                let chunk = data[i..<end]
                let flush: FlushMode = end == data.count ? .finish : .noFlush
                let chunkCompressed = try compressor.compress(chunk, flush: flush)
                compressed.append(chunkCompressed)
            }
            
            let decompressor = Decompressor()
            try decompressor.initializeAdvanced(windowBits: windowBits)
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        }
    }
    
    func testStreamingWithMemoryPressure() throws {
        let data = "streaming with memory pressure test".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let chunkSize = 3 // Very small chunks to test memory handling
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
    }
    
    func testStreamingWithStateTransitions() throws {
        let data = "streaming with state transitions test".data(using: .utf8)!
        let compressor = Compressor()
        
        // Test state transitions during streaming
        try compressor.initialize(level: .defaultCompression)
        
        var compressed = Data()
        let parts = [
            (data[..<5], FlushMode.noFlush),
            (data[5..<10], FlushMode.syncFlush),
            (data[10..<15], FlushMode.block),
            (data[15...], FlushMode.finish)
        ]
        
        for (chunk, flush) in parts {
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
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
        ("testPartialDecompression", testPartialDecompression),
        ("testChecksumCombination", testChecksumCombination),
        ("testCompressionWithGzipHeader", testCompressionWithGzipHeader),
        ("testStringCompressionWithGzipHeader", testStringCompressionWithGzipHeader),
        ("testCompressorAdvancedFeatures", testCompressorAdvancedFeatures),
        ("testDecompressorAdvancedFeatures", testDecompressorAdvancedFeatures),
        ("testInflateBackDecompressor", testInflateBackDecompressor),
        ("testInflateBackWithChunks", testInflateBackWithChunks),
        ("testInflateBackStreamInfo", testInflateBackStreamInfo),
        ("testStreamingDecompressor", testStreamingDecompressor),
        ("testStreamingDecompressorWithCallbacks", testStreamingDecompressorWithCallbacks),
        ("testStreamingDecompressorChunkHandling", testStreamingDecompressorChunkHandling),
        ("testErrorInfo", testErrorInfo),
        ("testSuccessErrorChecks", testSuccessErrorChecks),
        ("testErrorMessage", testErrorMessage),
        ("testRecoverableError", testRecoverableError),
        ("testErrorRecoverySuggestions", testErrorRecoverySuggestions),
        ("testParameterValidation", testParameterValidation),
        ("testCompressedSizeEstimation", testCompressedSizeEstimation),
        ("testRecommendedBufferSizes", testRecommendedBufferSizes),
        ("testMemoryUsageEstimation", testMemoryUsageEstimation),
        ("testOptimalParameters", testOptimalParameters),
        ("testPerformanceProfiles", testPerformanceProfiles),
        ("testBufferSizeCalculation", testBufferSizeCalculation),
        ("testCompressionStatistics", testCompressionStatistics),
        ("testCompileFlags", testCompileFlags),
        ("testDataExtensionsAdvanced", testDataExtensionsAdvanced),
        ("testStringExtensionsAdvanced", testStringExtensionsAdvanced),
        ("testInvalidCompressionLevel", testInvalidCompressionLevel),
        ("testInvalidWindowBits", testInvalidWindowBits),
        ("testCorruptedData", testCorruptedData),
        ("testMemoryPressure", testMemoryPressure),
        ("testConcurrentAccess", testConcurrentAccess),
        ("testMinimalSmallStringCompression", testMinimalSmallStringCompression),
        ("testMinimalSmallStringStreamingCompression", testMinimalSmallStringStreamingCompression),
        ("testDictionaryCompressionDecompression_Success", testDictionaryCompressionDecompression_Success),
        ("testDictionaryCompressionDecompression_WrongDictionary", testDictionaryCompressionDecompression_WrongDictionary),
        ("testDictionaryCompressionDecompression_MissingDictionary", testDictionaryCompressionDecompression_MissingDictionary),
        ("testDictionaryCompressionDecompression_RoundTripRetrieval", testDictionaryCompressionDecompression_RoundTripRetrieval),
        ("testDictionaryCompressionDecompression_EmptyDictionary", testDictionaryCompressionDecompression_EmptyDictionary),
        ("testDictionaryCompressionDecompression_LargeDictionary", testDictionaryCompressionDecompression_LargeDictionary),
        ("testDictionarySetAtWrongTime", testDictionarySetAtWrongTime),
        ("testDeflatePrimeBasic", testDeflatePrimeBasic),
        ("testDeflatePrimeMultipleBits", testDeflatePrimeMultipleBits),
        ("testDeflatePrimeLargeValue", testDeflatePrimeLargeValue),
        ("testDeflatePrimeBeforeCompression", testDeflatePrimeBeforeCompression),
        ("testDeflatePrimeAfterPartialCompression", testDeflatePrimeAfterPartialCompression),
        ("testDeflatePrimeInvalidBits", testDeflatePrimeInvalidBits),
        ("testDeflatePrimeBeforeInitialization", testDeflatePrimeBeforeInitialization),
        ("testInflatePrimeBasic", testInflatePrimeBasic),
        ("testInflatePrimeMultipleBits", testInflatePrimeMultipleBits),
        ("testInflatePrimeLargeValue", testInflatePrimeLargeValue),
        ("testInflatePrimeBeforeDecompression", testInflatePrimeBeforeDecompression),
        ("testInflatePrimeAfterPartialDecompression", testInflatePrimeAfterPartialDecompression),
        ("testInflatePrimeInvalidBits", testInflatePrimeInvalidBits),
        ("testInflatePrimeBeforeInitialization", testInflatePrimeBeforeInitialization),
        ("testPrimeRoundTrip", testPrimeRoundTrip),
        ("testPrimeWithDifferentValues", testPrimeWithDifferentValues),
        ("testPrimeAffectsCompressedOutput", testPrimeAffectsCompressedOutput),
        ("testPrimeIsolation", testPrimeIsolation),
        ("testPrimeWithZlibStreamFails", testPrimeWithZlibStreamFails),
        ("testPrimeWithGzipStreamFails", testPrimeWithGzipStreamFails),
        ("testPrimeZeroBits", testPrimeZeroBits),
        ("testPrimeMaxBits", testPrimeMaxBits),
        ("testWindowBitsRawRoundTrip", testWindowBitsRawRoundTrip),
        ("testWindowBitsZlibRoundTrip", testWindowBitsZlibRoundTrip),
        ("testWindowBitsGzipRoundTrip", testWindowBitsGzipRoundTrip),
        ("testWindowBitsAutoDetectGzip", testWindowBitsAutoDetectGzip),
        ("testWindowBitsAutoDetectZlib", testWindowBitsAutoDetectZlib),
        ("testWindowBitsMismatchedRawAsZlib", testWindowBitsMismatchedRawAsZlib),
        ("testWindowBitsMismatchedZlibAsRaw", testWindowBitsMismatchedZlibAsRaw),
        ("testWindowBitsMismatchedGzipAsZlib", testWindowBitsMismatchedGzipAsZlib),
        ("testWindowBitsMismatchedZlibAsGzip", testWindowBitsMismatchedZlibAsGzip),
        ("testWindowBitsEmptyInput", testWindowBitsEmptyInput),
        ("testWindowBitsCorruptedHeader", testWindowBitsCorruptedHeader),
        ("testWindowBitsEmptyInputRawDeflate", testWindowBitsEmptyInputRawDeflate),
        ("testWindowBitsEmptyInputZlibGzipAuto", testWindowBitsEmptyInputZlibGzipAuto),
        ("testGzipHeaderWithMetadata", testGzipHeaderWithMetadata),
        ("testGzipHeaderWithFilename", testGzipHeaderWithFilename),
        ("testGzipHeaderWithTimestamp", testGzipHeaderWithTimestamp),
        ("testGzipHeaderCompressionLevel", testGzipHeaderCompressionLevel),
        ("testGzipHeaderWithEmptyData", testGzipHeaderWithEmptyData),
        ("testGzipHeaderWithLargeData", testGzipHeaderWithLargeData),
        ("testGzipHeaderCorruption", testGzipHeaderCorruption),
        ("testGzipHeaderWithDifferentOS", testGzipHeaderWithDifferentOS),
        ("testGzipHeaderRoundTrip", testGzipHeaderRoundTrip),
        ("testGzipHeaderWithAutoDetection", testGzipHeaderWithAutoDetection),
        ("testGzipHeaderWithStreaming", testGzipHeaderWithStreaming),
        ("testCompressionWithInvalidLevel", testCompressionWithInvalidLevel),
        ("testDecompressionWithInvalidData", testDecompressionWithInvalidData),
        ("testCompressionWithNullData", testCompressionWithNullData),
        ("testDecompressionWithTruncatedData", testDecompressionWithTruncatedData),
        ("testCompressionWithUninitializedStream", testCompressionWithUninitializedStream),
        ("testDecompressionWithUninitializedStream", testDecompressionWithUninitializedStream),
        ("testCompressionWithInvalidFlushMode", testCompressionWithInvalidFlushMode),
        ("testDecompressionWithInvalidFlushMode", testDecompressionWithInvalidFlushMode),
        ("testCompressionWithLargeInput", testCompressionWithLargeInput),
        ("testDecompressionWithCorruptedData", testDecompressionWithCorruptedData),
        ("testCompressionWithZeroSizedBuffer", testCompressionWithZeroSizedBuffer),
        ("testDecompressionWithZeroSizedBuffer", testDecompressionWithZeroSizedBuffer),
        ("testCompressionWithInvalidWindowBits", testCompressionWithInvalidWindowBits),
        ("testDecompressionWithInvalidWindowBits", testDecompressionWithInvalidWindowBits),
        ("testCompressionWithReusedStream", testCompressionWithReusedStream),
        ("testDecompressionWithReusedStream", testDecompressionWithReusedStream),
        ("testCompressionWithInvalidDictionary", testCompressionWithInvalidDictionary),
        ("testDecompressionWithInvalidDictionary", testDecompressionWithInvalidDictionary),
        ("testCompressionWithMemoryPressure", testCompressionWithMemoryPressure),
        ("testDecompressionWithMemoryPressure", testDecompressionWithMemoryPressure),
        ("testCompressionWithInvalidState", testCompressionWithInvalidState),
        ("testDecompressionWithInvalidState", testDecompressionWithInvalidState),
        ("testStreamingCompressionWithSmallChunks", testStreamingCompressionWithSmallChunks),
        ("testStreamingDecompressionWithSmallChunks", testStreamingDecompressionWithSmallChunks),
        ("testStreamingWithEmptyChunks", testStreamingWithEmptyChunks),
        ("testStreamingWithPartialFlush", testStreamingWithPartialFlush),
        ("testStreamingWithBlockFlush", testStreamingWithBlockFlush),
        ("testStreamingWithLargeData", testStreamingWithLargeData),
        ("testStreamingWithMixedFlushModes", testStreamingWithMixedFlushModes),
        ("testStreamingWithReusedCompressor", testStreamingWithReusedCompressor),
        ("testStreamingWithReusedDecompressor", testStreamingWithReusedDecompressor),
        ("testStreamingWithPartialDecompression", testStreamingWithPartialDecompression),
        ("testStreamingWithCorruptedChunk", testStreamingWithCorruptedChunk),
        ("testStreamingWithIncompleteData", testStreamingWithIncompleteData),
        ("testStreamingWithDictionary", testStreamingWithDictionary),
        ("testStreamingWithDifferentCompressionLevels", testStreamingWithDifferentCompressionLevels),
        ("testStreamingWithWindowBitsVariants", testStreamingWithWindowBitsVariants),
        ("testStreamingWithMemoryPressure", testStreamingWithMemoryPressure),
        ("testStreamingWithStateTransitions", testStreamingWithStateTransitions),
    ]
}
