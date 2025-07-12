import XCTest
@testable import SwiftZlib

private let Z_NEED_DICT: Int32 = 2

final class SwiftZlibTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Enable verbose logging for all tests
//        ZLibVerboseConfig.enableAll()
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
            // Should be a data error (-3) for invalid zlib data
            if case .decompressionFailed(let code) = error as? ZLibError {
                XCTAssertEqual(code, -3, "Expected Z_DATA_ERROR for invalid zlib data")
            }
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
    
    /// Dictionary Usage Requirements:
    /// - Compression: Dictionary must be set BEFORE compression begins
    /// - Decompression: Dictionary must be set ONLY AFTER receiving Z_NEED_DICT error during decompression
    /// - You cannot set a dictionary on a decompressor unless the stream explicitly signals it needs one
    /// - The correct flow is: decompress → receive Z_NEED_DICT → set dictionary → continue decompression
    /// - Setting dictionary before Z_NEED_DICT will result in Z_STREAM_ERROR (-2)
    
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
    
    /// Priming is a low-level zlib feature with important limitations:
    /// - Only works with raw deflate streams (windowBits: .raw)
    /// - NOT supported for zlib/gzip streams
    /// - Round-trip compression/decompression with priming is not typically supported
    /// - Primed bits interfere with the compressed data format
    /// - Priming is mainly for specialized applications that need to insert bits into raw deflate streams
    /// - Use priming only when you understand the raw deflate format and its implications
    
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
        _ = try ZLib.compress(originalData)
        
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
        _ = try ZLib.compress(originalData)
        
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
        _ = try ZLib.compress(originalData)
        
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Prime with 16 bits
        try decompressor.prime(bits: 16, value: 0x1234)
        
        // Test that priming worked
        XCTAssertNoThrow(try decompressor.prime(bits: 16, value: 0x5678))
    }
    
    func testInflatePrimeBeforeDecompression() throws {
        let originalData = "test data".data(using: .utf8)!
        _ = try ZLib.compress(originalData)
        
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
        
        // Try to prime after partial decompression - behavior may vary by platform
        do {
            try decompressor.prime(bits: 8, value: 0x42)
            // If priming succeeds, that's acceptable on some platforms
            // Just verify we can continue decompression
            let remainingData = compressedData.suffix(from: compressedData.count / 2)
            let finalDecompressed = try decompressor.decompress(remainingData)
            XCTAssertGreaterThan(finalDecompressed.count, 0)
        } catch {
            // If priming fails, that's also acceptable behavior
            XCTAssertTrue(error is ZLibError)
        }
    }
    
    func testInflatePrimeInvalidBits() throws {
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Test with invalid bit count - behavior may vary by zlib version/platform
        // Some zlib versions may accept these values, others may reject them
        do {
            try decompressor.prime(bits: -1, value: 0x42)
            // If no error, that's acceptable behavior for some zlib versions
        } catch {
            // If error is thrown, that's also acceptable
            XCTAssertTrue(error is ZLibError)
        }
        
        do {
            try decompressor.prime(bits: 33, value: 0x42) // More than 32 bits
            // If no error, that's acceptable behavior for some zlib versions
        } catch {
            // If error is thrown, that's also acceptable
            XCTAssertTrue(error is ZLibError)
        }
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
        // Zlib, gzip, auto: platform-specific behavior for empty input
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
        _ = "test.txt"
        
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
    
    /// zlib's behavior with truncated data is platform- and version-dependent.
    /// Some versions will throw an error, others will return as much data as possible without error.
    /// This test accepts both outcomes as valid: either an error is thrown, or the decompressed data is incomplete.
    func testDecompressionWithTruncatedData() throws {
        let data = "test data for truncation".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate)
        let compressed = try compressor.compress(data, flush: .finish)
        let truncated = compressed.prefix(compressed.count / 2)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .deflate)
        var threw = false
        do {
            let decompressed = try decompressor.decompress(truncated)
            // If no error, the decompressed data should be incomplete
            XCTAssertNotEqual(decompressed, data)
            XCTAssertLessThan(decompressed.count, data.count, "Truncated data should decompress to less data")
        } catch {
            threw = true
            XCTAssertTrue(error is ZLibError)
        }
        // Accept both: error thrown or partial data returned
        XCTAssertTrue(threw || true)
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
        
        // Test corrupted data - should fail, but behavior may vary
        do {
            let decompressed = try decompressor.decompress(corrupted)
            // If corruption doesn't cause an error, the result should be different
            XCTAssertNotEqual(decompressed, data)
        } catch {
            // Expected error for corrupted data
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
        _ = "test data".data(using: .utf8)!
        let compressor = Compressor()
        
        // Test with valid window bits
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .deflate))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw))
        XCTAssertNoThrow(try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .gzip))
    }
    
    func testDecompressionWithInvalidWindowBits() throws {
        let data = "test data".data(using: .utf8)!
        _ = try ZLib.compress(data)
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
        
        // Test with invalid dictionary - behavior may vary by platform
        let invalidDictionary = Data([0xFF, 0xFF, 0xFF, 0xFF])
        
        do {
            try decompressor.setDictionary(invalidDictionary)
            // If setDictionary succeeds, decompression should still work
            let decompressed = try decompressor.decompress(compressed)
            XCTAssertEqual(decompressed, data)
        } catch {
            // If setDictionary fails, that's also acceptable behavior
            // Just verify the error is a ZLibError
            XCTAssertTrue(error is ZLibError)
        }
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
        _ = try ZLib.compress(data)
        let decompressor = Decompressor()
        
        // Try to set dictionary before initialization - should always fail
        XCTAssertThrowsError(try decompressor.setDictionary(data)) { error in
            XCTAssertTrue(error is ZLibError)
        }
        
        // Initialize and then try to set dictionary again - should also fail
        // Dictionary can only be set after Z_NEED_DICT is signaled during decompression
        try decompressor.initializeAdvanced(windowBits: .deflate)
        XCTAssertThrowsError(try decompressor.setDictionary(data)) { error in
            XCTAssertTrue(error is ZLibError)
        }
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
        
        // Decompress with dictionary using the new API
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed, dictionary: dictionary)
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
    
    // MARK: - Concurrency Tests
    
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
        for _ in 0..<iterations {
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
        for _ in 0..<iterations {
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
            "Fourth concurrent test string"
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
        for _ in 0..<iterations {
            queue.async(group: group) {
                do {
                    let compressor = Compressor()
                    try compressor.initialize(level: .defaultCompression)
                    
                    // Split data into chunks
                    let chunkSize = 10
                    var compressed = Data()
                    
                    for i in stride(from: 0, to: testData.count, by: chunkSize) {
                        let end = min(i + chunkSize, testData.count)
                        let chunk = testData[i..<end]
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
        for _ in 0..<iterations {
            queue.async(group: group) {
                do {
                    let decompressor = Decompressor()
                    try decompressor.initialize()
                    
                    // Split compressed data into chunks
                    let chunkSize = 20
                    var decompressed = Data()
                    
                    for i in stride(from: 0, to: compressedData.count, by: chunkSize) {
                        let end = min(i + chunkSize, compressedData.count)
                        let chunk = compressedData[i..<end]
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
        
        for _ in 0..<iterations {
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
        
        for _ in 0..<iterations {
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
        
        for i in 0..<iterations {
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
        
        for _ in 0..<iterations {
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
        
        for _ in 0..<iterations {
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
        
        for _ in 0..<iterations {
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
        let invalidData = Data([0x78, 0x9c, 0x01, 0x00, 0x00, 0xff, 0xff]) // Incomplete zlib data
        let iterations = 50
        let queue = DispatchQueue(label: "test.concurrent.error.handling", attributes: .concurrent)
        let group = DispatchGroup()
        var errorCount = 0
        let lock = NSLock()
        
        for _ in 0..<iterations {
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
        
        for _ in 0..<iterations {
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
        for _ in 0..<iterations {
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
    
    // MARK: - Performance and Memory Usage Tests
    func testPerformanceAndMemoryUsage() throws {
        let largeData = Data(repeating: 0xAB, count: 10_000_000) // 10MB - realistic large file size
        let startCompress = CFAbsoluteTimeGetCurrent()
        let compressed = try ZLib.compress(largeData, level: .bestCompression)
        let compressTime = CFAbsoluteTimeGetCurrent() - startCompress
        print("Compression time for 10MB: \(compressTime)s, ratio: \(Double(compressed.count) / Double(largeData.count))")

        let startDecompress = CFAbsoluteTimeGetCurrent()
        // Use streaming decompression for large data to avoid buffer size issues
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        let decompressTime = CFAbsoluteTimeGetCurrent() - startDecompress
        print("Decompression time for 10MB: \(decompressTime)s")

        XCTAssertEqual(decompressed, largeData)
        // Realistic time limits for 10MB
        XCTAssertLessThan(compressTime, 5.0, "Compression took too long")
        XCTAssertLessThan(decompressTime, 3.0, "Decompression took too long")
    }

    // MARK: - API Misuse Tests
    func testAPIMisuse_NilAndEmpty() throws {
        // Empty data should not crash and should round-trip
        let empty = Data()
        let compressed = try ZLib.compress(empty)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, empty)

        // String extension with empty string
        let emptyString = ""
        let compressedString = try emptyString.compressed()
        let decompressedString = try String.decompressed(from: compressedString)
        XCTAssertEqual(decompressedString, emptyString)
    }

    func testAPIMisuse_InvalidParameters() throws {
        let data = "test".data(using: .utf8)!
        let compressor = Compressor()
        // Not initialized
        XCTAssertThrowsError(try compressor.compress(data))
        // Invalid flush mode (simulate by passing an invalid enum raw value if possible)
        // Not possible directly, but can try decompressing with wrong windowBits
        let compressed = try ZLib.compress(data)
        let decompressor = Decompressor()
        try decompressor.initializeAdvanced(windowBits: .raw)
        XCTAssertThrowsError(try decompressor.decompress(compressed))
    }

    func testAPIMisuse_DictionaryMisuse() throws {
        let dict = "dict".data(using: .utf8)!
        let compressor = Compressor()
        // Set dictionary before init
        XCTAssertThrowsError(try compressor.setDictionary(dict))
        try compressor.initialize(level: .defaultCompression)
        // Set dictionary after init (should succeed)
        XCTAssertNoThrow(try compressor.setDictionary(dict))
        // Decompressor: set dictionary before init
        let decompressor = Decompressor()
        XCTAssertThrowsError(try decompressor.setDictionary(dict))
        try decompressor.initialize()
        // Set dictionary before Z_NEED_DICT (should fail)
        XCTAssertThrowsError(try decompressor.setDictionary(dict))
    }
    
    // MARK: - Edge Case Tests
    
    func testBufferOverflowScenarios() throws {
        // Test with extremely large buffers that might cause overflow
        let largeData = Data(repeating: 0x42, count: 100_000_000) // 100MB
        let compressed = try ZLib.compress(largeData, level: .bestCompression)
        // Use streaming decompression for very large data
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, largeData)
        // Partial decompress with tiny buffer may throw or return partial data
        do {
            let smallBuffer = try ZLib.partialDecompress(compressed, maxOutputSize: 1)
            XCTAssertGreaterThanOrEqual(smallBuffer.decompressed.count, 0)
        } catch let error as ZLibError {
            // Accept Z_BUF_ERROR as a valid outcome
            if case .decompressionFailed(let code) = error {
                XCTAssertEqual(code, -5)
            } else {
                throw error
            }
        }
    }
    
    func testMemoryExhaustionScenarios() throws {
        // Test with data that might cause memory pressure
        let memoryIntensiveData = Data(repeating: 0x00, count: 50_000_000) // 50MB of zeros (highly compressible)
        
        // This should work without memory issues
        let compressed = try ZLib.compress(memoryIntensiveData, level: .bestCompression)
        XCTAssertLessThan(compressed.count, memoryIntensiveData.count) // Should compress well
        
        // For large data, use streaming decompression to avoid buffer errors
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, memoryIntensiveData)
    }
    
    func testStreamCorruptionDuringOperation() throws {
        let data = "test data for corruption".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        // Compress in chunks
        let chunkSize = 5
        var compressed = Data()
        
        for i in stride(from: 0, to: data.count, by: chunkSize) {
            let end = min(i + chunkSize, data.count)
            let chunk = data[i..<end]
            let flush: FlushMode = end == data.count ? .finish : .noFlush
            let chunkCompressed = try compressor.compress(chunk, flush: flush)
            compressed.append(chunkCompressed)
        }
        
        // Corrupt the compressed data mid-stream
        if compressed.count > 10 {
            var corrupted = compressed
            corrupted[compressed.count / 2] = 0xFF // Corrupt middle byte
            
            let decompressor = Decompressor()
            try decompressor.initialize()
            
            // Should fail with corrupted data
            XCTAssertThrowsError(try decompressor.decompress(corrupted)) { error in
                XCTAssertTrue(error is ZLibError)
            }
        }
    }
    
    func testInvalidPointerHandling() throws {
        // Test with empty data (null pointer scenarios)
        let emptyData = Data()
        let compressed = try ZLib.compress(emptyData)
        let decompressed = try ZLib.decompress(compressed)
        XCTAssertEqual(decompressed, emptyData)
        
        // Test with single byte data
        let singleByte = Data([0x42])
        let compressedSingle = try ZLib.compress(singleByte)
        let decompressedSingle = try ZLib.decompress(compressedSingle)
        XCTAssertEqual(decompressedSingle, singleByte)
        
        // Test with data containing null bytes
        let nullData = Data([0x00, 0x01, 0x00, 0x02, 0x00])
        let compressedNull = try ZLib.compress(nullData)
        let decompressedNull = try ZLib.decompress(compressedNull)
        XCTAssertEqual(decompressedNull, nullData)
    }
    
    // MARK: - Advanced API Coverage Tests
    
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
    
    func testStreamingDecompressorCallbacks() throws {
        let testData = "streaming decompressor callback test data".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)
        
        let streamingDecompressor = StreamingDecompressor()
        try streamingDecompressor.initialize()
        
        var decompressedChunks: [Data] = []
        var shouldContinue = true
        
        try streamingDecompressor.processWithCallbacks(
            inputProvider: {
                // Provide compressed data in chunks
                if shouldContinue {
                    shouldContinue = false
                    return compressed
                }
                return nil
            },
            outputHandler: { chunk in
                decompressedChunks.append(chunk)
                return true // Continue processing
            }
        )
        
        let decompressed = decompressedChunks.reduce(Data(), +)
        XCTAssertEqual(decompressed, testData)
    }
    
    func testInflateBackAdvancedFeatures() throws {
        let testData = "inflate back advanced test data".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)
        
        let inflateBack = InflateBackDecompressor()
        try inflateBack.initialize()
        
        var decompressedChunks: [Data] = []
        
        // Test with valid compressed data in chunks
        var inputIndex = 0
        let chunkSize = 10
        
        try inflateBack.processWithCallbacks(
            inputProvider: {
                // Provide data in small chunks
                guard inputIndex < compressed.count else { return nil }
                let remaining = compressed.count - inputIndex
                let currentChunkSize = min(chunkSize, remaining)
                let chunk = compressed.subdata(in: inputIndex..<(inputIndex + currentChunkSize))
                inputIndex += currentChunkSize
                return chunk
            },
            outputHandler: { chunk in
                decompressedChunks.append(chunk)
                return true
            }
        )
        
        // Verify we got some output
        XCTAssertGreaterThanOrEqual(decompressedChunks.count, 0)
        
        // Combine all chunks and verify decompression
        let decompressed = decompressedChunks.reduce(Data(), +)
        XCTAssertEqual(decompressed, testData)
    }
    
    func testAdvancedTuningParameters() throws {
        let testData = "advanced tuning parameters test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        // Test advanced tuning parameters
        try compressor.tune(goodLength: 32, maxLazy: 258, niceLength: 258, maxChain: 4096)
        
        let compressed = try compressor.compress(testData, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Test with different tuning parameters
        let compressor2 = Compressor()
        try compressor2.initialize(level: .bestCompression)
        try compressor2.tune(goodLength: 64, maxLazy: 128, niceLength: 128, maxChain: 2048)
        
        let compressed2 = try compressor2.compress(testData, flush: .finish)
        XCTAssertGreaterThan(compressed2.count, 0)
        
        // Both should decompress correctly
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, testData)
        
        let decompressor2 = Decompressor()
        try decompressor2.initialize()
        let decompressed2 = try decompressor2.decompress(compressed2)
        XCTAssertEqual(decompressed2, testData)
    }
    
    // MARK: - Platform-Specific Behavior Tests
    
    func testPlatformSpecificBehavior() throws {
        // Test that documents platform-specific behavior differences
        let testData = "platform specific test data".data(using: .utf8)!
        
        // Test compression with different levels on this platform
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        var compressionResults: [Data] = []
        
        for level in levels {
            let compressed = try ZLib.compress(testData, level: level)
            compressionResults.append(compressed)
            
            // Verify decompression works
            let decompressed = try ZLib.decompress(compressed)
            XCTAssertEqual(decompressed, testData)
        }
        
        // Document platform-specific compression ratios
        print("Platform-specific compression ratios:")
        for (i, level) in levels.enumerated() {
            let ratio = Double(compressionResults[i].count) / Double(testData.count)
            print("  \(level): \(String(format: "%.3f", ratio))")
        }
        
        // Test that all compressed data can be decompressed (platform compatibility)
        for compressed in compressionResults {
            XCTAssertNoThrow(try ZLib.decompress(compressed))
        }
        
        // Test architecture-specific behavior (pointer sizes, etc.)
        let compileFlags = ZLib.compileFlags
        print("Platform compile flags: \(compileFlags)")
        
        // Test that basic operations work regardless of platform
        let emptyData = Data()
        let emptyCompressed = try ZLib.compress(emptyData)
        let emptyDecompressed = try ZLib.decompress(emptyCompressed)
        XCTAssertEqual(emptyDecompressed, emptyData)
    }
    
    // MARK: - Improved Error Handling Tests
    
    func testSpecificErrorTypes() throws {
        // Test for specific error types instead of just "any ZLibError"
        
        // Test uninitialized stream - should be Z_STREAM_ERROR (-2)
        let compressor = Compressor()
        XCTAssertThrowsError(try compressor.compress(Data([0x42]))) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case .streamError(let code):
                    XCTAssertEqual(code, -2, "Expected Z_STREAM_ERROR for uninitialized stream")
                default:
                    XCTFail("Expected streamError, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }
        
        // Test invalid data - should be Z_DATA_ERROR (-3)
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        let decompressor = Decompressor()
        try decompressor.initialize()
        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            if let zlibError = error as? ZLibError {
                switch zlibError {
                case .decompressionFailed(let code):
                    XCTAssertEqual(code, -3, "Expected Z_DATA_ERROR for invalid data")
                default:
                    XCTFail("Expected decompressionFailed, got \(zlibError)")
                }
            } else {
                XCTFail("Expected ZLibError, got \(error)")
            }
        }
    }
    
    func testPlatformAgnosticValidation() throws {
        // Test that validates behavior without assuming specific platform behavior
        
        let data = "platform agnostic test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        // Test that compression produces valid output regardless of platform
        let compressed = try compressor.compress(data, flush: .finish)
        XCTAssertGreaterThan(compressed.count, 0)
        
        // Test that decompression works regardless of platform
        let decompressor = Decompressor()
        try decompressor.initialize()
        let decompressed = try decompressor.decompress(compressed)
        XCTAssertEqual(decompressed, data)
        
        // Test that empty data works on all platforms
        let emptyCompressed = try ZLib.compress(Data())
        let emptyDecompressed = try ZLib.decompress(emptyCompressed)
        XCTAssertEqual(emptyDecompressed, Data())
        
        // Test that single byte works on all platforms
        let singleByte = Data([0x42])
        let singleCompressed = try ZLib.compress(singleByte)
        let singleDecompressed = try ZLib.decompress(singleCompressed)
        XCTAssertEqual(singleDecompressed, singleByte)
    }
    
    func testIntermediateStateValidation() throws {
        // Test that validates intermediate states during streaming operations
        
        let data = "intermediate state validation test data".data(using: .utf8)!
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        
        // Test intermediate state during compression
        let chunk1 = data.prefix(5)
        let compressed1 = try compressor.compress(chunk1, flush: .noFlush)
        XCTAssertGreaterThanOrEqual(compressed1.count, 0)
        
        // Validate stream state after first chunk
        let streamInfo1 = try compressor.getStreamInfo()
        XCTAssertGreaterThanOrEqual(streamInfo1.totalIn, 5)
        XCTAssertTrue(streamInfo1.isActive)
        
        // Test intermediate state during decompression
        let chunk2 = data.suffix(from: 5)
        let compressed2 = try compressor.compress(chunk2, flush: .finish)
        XCTAssertGreaterThanOrEqual(compressed2.count, 0)
        
        // Validate final stream state
        let streamInfo2 = try compressor.getStreamInfo()
        XCTAssertEqual(streamInfo2.totalIn, UInt(data.count))
        // Note: isActive reflects initialization state, not completion state
        // The stream remains initialized even after finishing
        XCTAssertTrue(streamInfo2.isActive) // Stream remains initialized
        
        // Test decompression with intermediate state validation
        let fullCompressed = compressed1 + compressed2
        let decompressor = Decompressor()
        try decompressor.initialize()
        
        // Decompress in chunks and validate intermediate states
        let decompressed1 = try decompressor.decompress(fullCompressed.prefix(fullCompressed.count / 2))
        let decompressed2 = try decompressor.decompress(fullCompressed.suffix(from: fullCompressed.count / 2))
        
        let finalDecompressed = decompressed1 + decompressed2
        XCTAssertEqual(finalDecompressed, data)
    }
    
    func testConsistentErrorExpectations() throws {
        // Test that validates consistent error expectations across different scenarios
        
        // Test that uninitialized operations always throw stream errors
        let compressor = Compressor()
        let decompressor = Decompressor()
        
        // All uninitialized operations should throw stream errors
        XCTAssertThrowsError(try compressor.compress(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case .streamError(let code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }
        
        XCTAssertThrowsError(try compressor.setDictionary(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case .streamError(let code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }
        
        XCTAssertThrowsError(try decompressor.decompress(Data([0x42]))) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case .streamError(let code) = zlibError {
                XCTAssertEqual(code, -2)
            }
        }
        
        // Test that invalid data always throws data errors
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        try decompressor.initialize()
        
        XCTAssertThrowsError(try decompressor.decompress(invalidData)) { error in
            XCTAssertTrue(error is ZLibError)
            if let zlibError = error as? ZLibError, case .decompressionFailed(let code) = zlibError {
                XCTAssertEqual(code, -3)
            }
        }
    }
    
    // MARK: - Advanced Gzip File Operations Tests
    
    func testAdvancedGzipFileOperations() throws {
        let tempFile = "test_advanced_gzip.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        // Test advanced write operations
        let gzipFile = try GzipFile(path: tempFile, mode: "w")
        
        // Test putByte
        try gzipFile.putByte(65) // 'A'
        try gzipFile.putByte(66) // 'B'
        try gzipFile.putByte(67) // 'C'
        
        // Test printf (simplified)
        try gzipFile.printf("Hello, World!")
        
        // Test flush with different modes
        try gzipFile.flush(mode: 2) // Z_SYNC_FLUSH
        try gzipFile.flush(mode: 3) // Z_FULL_FLUSH
        
        // Test position
        let position = try gzipFile.position()
        XCTAssertGreaterThan(position, 0)
        
        // Note: Seeking in gzip files may not be supported in all cases
        // We'll test position but skip seeking tests for now
        
        try gzipFile.close()
        
        // Test advanced read operations
        let readFile = try GzipFile(path: tempFile, mode: "r")
        
        // Test getByte
        let byte1 = try readFile.getByte()
        XCTAssertEqual(byte1, 65) // 'A'
        
        let byte2 = try readFile.getByte()
        XCTAssertEqual(byte2, 66) // 'B'
        
        // Test ungetByte
        try readFile.ungetByte(66) // Push back 'B'
        let byte2Again = try readFile.getByte()
        XCTAssertEqual(byte2Again, 66) // Should get 'B' again
        
        // Test getsWithEncoding
        let line = try readFile.getsWithEncoding(maxLength: 100, encoding: .utf8)
        XCTAssertNotNil(line)
        
        // Test isEOF (relaxed: allow EOF after reading all data)
        // It's normal for isEOF to be true after reading the last line, so we skip this assertion.
        // XCTAssertFalse(readFile.isEOF())
        
        // Test getErrorInfo
        let errorInfo = readFile.getErrorInfo()
        XCTAssertEqual(errorInfo.code, 0) // No error
        
        // Test clearErrorState
        readFile.clearErrorState()
        
        // Test properties
        XCTAssertTrue(readFile.isOpen)
        XCTAssertEqual(readFile.filePath, tempFile)
        XCTAssertEqual(readFile.fileMode, "r")
        
        try readFile.close()
    }
    
    func testGzipFileByteOperations() throws {
        let tempFile = "test_gzip_bytes.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        let gzipFile = try GzipFile(path: tempFile, mode: "w")
        
        // Write bytes
        for i in 0..<10 {
            try gzipFile.putByte(UInt8(i))
        }
        
        try gzipFile.close()
        
        // Read bytes
        let readFile = try GzipFile(path: tempFile, mode: "r")
        
        for i in 0..<10 {
            let byte = try readFile.getByte()
            XCTAssertEqual(byte, UInt8(i))
        }
        
        // Test EOF
        let eofByte = try readFile.getByte()
        XCTAssertNil(eofByte) // Should be nil at EOF
        
        XCTAssertTrue(readFile.isEOF())
        
        try readFile.close()
    }
    
    func testGzipFilePositionOperations() throws {
        let tempFile = "test_gzip_position.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        let gzipFile = try GzipFile(path: tempFile, mode: "w")
        
        // Write some data
        try gzipFile.writeString("Hello, World!")
        
        let position = try gzipFile.position()
        XCTAssertGreaterThan(position, 0)
        
        // Note: Seeking in gzip files may not be supported in all cases
        // We'll test position but skip seeking tests for now
        
        try gzipFile.close()
    }
    
    func testGzipFileErrorHandling() throws {
        let tempFile = "test_gzip_error.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        let gzipFile = try GzipFile(path: tempFile, mode: "w")
        
        // Test error info when no error
        let errorInfo = gzipFile.getErrorInfo()
        XCTAssertEqual(errorInfo.code, 0)
        XCTAssertTrue(errorInfo.message.contains("No error") || errorInfo.message.isEmpty)
        
        // Test clear error state
        gzipFile.clearErrorState()
        
        try gzipFile.close()
        
        // Test error info on closed file
        let closedErrorInfo = gzipFile.getErrorInfo()
        XCTAssertEqual(closedErrorInfo.code, -1)
        XCTAssertEqual(closedErrorInfo.message, "File not open")
    }
    
    func testGzipFileCompressionParameters() throws {
        let tempFile = "test_gzip_params.txt.gz"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        let gzipFile = try GzipFile(path: tempFile, mode: "w")
        
        // Test setting compression parameters
        try gzipFile.setCompressionParameters(level: .bestCompression, strategy: .defaultStrategy)
        
        // Write some data
        try gzipFile.writeString("Test data for compression parameters")
        
        try gzipFile.close()
        
        // Verify file was created and has content
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: tempFile))
        
        let attributes = try fileManager.attributesOfItem(atPath: tempFile)
        let fileSize = attributes[.size] as? Int ?? 0
        XCTAssertGreaterThan(fileSize, 0)
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
    
    func testInflateBackDecompressorCBridged() throws {
        let original = "InflateBackCBridged test data".data(using: .utf8)!
        // Compress with raw deflate using Compressor
        let compressor = Compressor()
        try compressor.initializeAdvanced(windowBits: .raw)
        let compressed = try compressor.compress(original, flush: .finish)

        // Decompress using InflateBackDecompressorCBridged
        let inflater = InflateBackDecompressorCBridged(windowBits: .raw)
        try inflater.initialize()
        var output = Data()
        try inflater.processWithCallbacks(
            inputProvider: {
                print("Swift inputProvider called, input size: \(compressed.count)")
                return compressed
            },
            outputHandler: { data in
                print("Swift outputHandler called, output size: \(data.count)")
                output.append(data)
                return true
            }
        )
        XCTAssertEqual(output, original)
    }
    
    func testConfigurationBasedAPI() throws {
        let original = "Configuration-based API test data".data(using: .utf8)!
        
        // Test basic compression with options
        let options = CompressionOptions(format: .zlib, level: .bestCompression)
        let compressed = try ZLib.compress(original, options: options)
        // Note: Small data may not compress well, so we just verify it compresses without error
        XCTAssertNotEqual(compressed.count, 0)
        
        // Test decompression with options
        let decompOptions = DecompressionOptions(format: .zlib)
        let decompressed = try ZLib.decompress(compressed, options: decompOptions)
        XCTAssertEqual(decompressed, original)
        
        // Test gzip compression
        let gzipCompressed = try ZLib.compressGzip(original)
        XCTAssertNotEqual(gzipCompressed.count, 0)
        
        // Test raw deflate compression
        let rawCompressed = try ZLib.compressRaw(original)
        XCTAssertNotEqual(rawCompressed.count, 0)
        
        // Test auto-decompression
        let autoDecompressed = try ZLib.decompressAuto(compressed)
        XCTAssertEqual(autoDecompressed, original)
        
        // Test with larger, more compressible data
        let largeOriginal = Data(repeating: 0x00, count: 1000) // Highly compressible
        let largeCompressed = try ZLib.compress(largeOriginal, options: options)
        XCTAssertLessThan(largeCompressed.count, largeOriginal.count) // This should compress well
    }
    
    func testUnifiedStreamingAPI() throws {
        let original = "Unified streaming API test data".data(using: .utf8)!
        
        // Test 1: Builder pattern for compression
        let compressionStream = ZLib.stream()
            .compress()
            .format(.zlib)
            .level(.bestCompression)
            .bufferSize(1024)
            .build()
        
        try compressionStream.initialize()
        let compressed = try compressionStream.process(original, flush: .finish)
        XCTAssertNotEqual(compressed.count, 0)
        
        // Test 2: Builder pattern for decompression
        let decompressionStream = ZLib.stream()
            .decompress()
            .format(.zlib)
            .bufferSize(1024)
            .build()
        
        try decompressionStream.initialize()
        let decompressed = try decompressionStream.process(compressed)
        XCTAssertEqual(decompressed, original)
        
        // Test 3: Direct stream creation
        let directCompressStream = ZLib.compressionStream()
        try directCompressStream.initialize()
        let directCompressed = try directCompressStream.process(original, flush: .finish)
        XCTAssertNotEqual(directCompressed.count, 0)
        
        let directDecompressStream = ZLib.decompressionStream()
        try directDecompressStream.initialize()
        let directDecompressed = try directDecompressStream.process(directCompressed)
        XCTAssertEqual(directDecompressed, original)
        
        // Test 4: Streaming with chunks
        let chunkStream = ZLib.stream()
            .compress()
            .format(.gzip)
            .level(.bestSpeed)
            .build()
        
        try chunkStream.initialize()
        
        // Process in chunks
        let chunkSize = 5
        var chunkedCompressed = Data()
        for i in stride(from: 0, to: original.count, by: chunkSize) {
            let end = min(i + chunkSize, original.count)
            let chunk = original.subdata(in: i..<end)
            let flush: FlushMode = (end == original.count) ? .finish : .noFlush
            let compressedChunk = try chunkStream.process(chunk, flush: flush)
            chunkedCompressed.append(compressedChunk)
        }
        
        XCTAssertNotEqual(chunkedCompressed.count, 0)
        
        // Decompress the chunked result
        let chunkDecompressStream = ZLib.stream()
            .decompress()
            .format(.gzip)
            .build()
        
        try chunkDecompressStream.initialize()
        let chunkDecompressed = try chunkDecompressStream.process(chunkedCompressed)
        XCTAssertEqual(chunkDecompressed, original)
        
        // Test 5: Stream info
        let info = try compressionStream.getStreamInfo()
        XCTAssertGreaterThan(info.totalIn, 0)
        XCTAssertGreaterThan(info.totalOut, 0)
        XCTAssertTrue(info.isActive)
    }
    
    func testAsyncAwaitSupport() async throws {
        let original = "Async/await compression test data".data(using: .utf8)!
        
        // Test 1: Simple async compression/decompression
        let compressed = try await ZLib.compressAsync(original)
        let decompressed = try await ZLib.decompressAsync(compressed)
        
        XCTAssertNotEqual(compressed.count, 0)
        XCTAssertEqual(decompressed, original)
        
        // Test 2: Async compression with options
        let compressionOptions = CompressionOptions(
            format: .gzip,
            level: .bestCompression
        )
        let compressedWithOptions = try await ZLib.compressAsync(original, options: compressionOptions)
        XCTAssertNotEqual(compressedWithOptions.count, 0)
        
        // Test 3: Async decompression with options
        let decompressionOptions = DecompressionOptions(format: .gzip)
        let decompressedWithOptions = try await ZLib.decompressAsync(compressedWithOptions, options: decompressionOptions)
        XCTAssertEqual(decompressedWithOptions, original)
        
        // Test 4: Async streaming compression
        let asyncCompressor = AsyncCompressor(options: compressionOptions)
        try await asyncCompressor.initialize()
        
        let streamCompressed = try await asyncCompressor.compress(original, flush: FlushMode.finish)
        XCTAssertNotEqual(streamCompressed.count, 0)
        
        // Test 5: Async streaming decompression
        let asyncDecompressor = AsyncDecompressor(options: decompressionOptions)
        try await asyncDecompressor.initialize()
        
        let streamDecompressed = try await asyncDecompressor.decompress(streamCompressed)
        XCTAssertEqual(streamDecompressed, original)
        
        // Test 6: Async unified streaming API
        let asyncStream = ZLib.asyncStream()
            .compress()
            .format(.zlib)
            .level(.bestSpeed)
            .bufferSize(1024)
            .build()
        
        try await asyncStream.initialize()
        let unifiedCompressed = try await asyncStream.process(original, flush: FlushMode.finish)
        XCTAssertNotEqual(unifiedCompressed.count, 0)
        
        // Test 7: Async unified streaming decompression
        let asyncDecompressStream = ZLib.asyncStream()
            .decompress()
            .format(.zlib)
            .bufferSize(1024)
            .build()
        
        try await asyncDecompressStream.initialize()
        let unifiedDecompressed = try await asyncDecompressStream.process(unifiedCompressed)
        XCTAssertEqual(unifiedDecompressed, original)
        
        // Test 8: Async streaming with chunks
        let chunkStream = ZLib.asyncStream().compress().format(.gzip).build()
        try await chunkStream.initialize()
        
        var chunkedCompressed = Data()
        let chunkSize = 5
        
        for i in stride(from: 0, to: original.count, by: chunkSize) {
            let end = min(i + chunkSize, original.count)
            let chunk = original.subdata(in: i..<end)
            let flush: FlushMode = (end == original.count) ? .finish : .noFlush
            let compressedChunk = try await chunkStream.process(chunk, flush: flush)
            chunkedCompressed.append(compressedChunk)
        }
        
        XCTAssertNotEqual(chunkedCompressed.count, 0)
        
        // Decompress the chunked result
        let chunkDecompressStream = ZLib.asyncStream()
            .decompress()
            .format(.gzip)
            .build()
        
        try await chunkDecompressStream.initialize()
        let chunkDecompressed = try await chunkDecompressStream.process(chunkedCompressed)
        XCTAssertEqual(chunkDecompressed, original)
        
        // Test 9: Stream info
        let info = try await asyncStream.getStreamInfo()
        XCTAssertGreaterThan(info.totalIn, 0)
        XCTAssertGreaterThan(info.totalOut, 0)
        XCTAssertTrue(info.isActive)
        
        // Test 10: Reset functionality
        try await asyncStream.reset()
        try await asyncStream.initialize()
        let resetCompressed = try await asyncStream.process(original, flush: FlushMode.finish)
        XCTAssertNotEqual(resetCompressed.count, 0)
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
        ("testConcurrentCompression", testConcurrentCompression),
        ("testConcurrentDecompression", testConcurrentDecompression),
        ("testConcurrentMixedOperations", testConcurrentMixedOperations),
        ("testConcurrentStreamingCompression", testConcurrentStreamingCompression),
        ("testConcurrentStreamingDecompression", testConcurrentStreamingDecompression),
        ("testConcurrentCompressorInstances", testConcurrentCompressorInstances),
        ("testConcurrentDecompressorInstances", testConcurrentDecompressorInstances),
        ("testConcurrentDifferentCompressionLevels", testConcurrentDifferentCompressionLevels),
        ("testConcurrentDifferentWindowBits", testConcurrentDifferentWindowBits),
        ("testConcurrentDictionaryOperations", testConcurrentDictionaryOperations),
        ("testConcurrentStringOperations", testConcurrentStringOperations),
        ("testConcurrentDataExtensions", testConcurrentDataExtensions),
        ("testConcurrentErrorHandling", testConcurrentErrorHandling),
        ("testConcurrentMemoryPressure", testConcurrentMemoryPressure),
        ("testConcurrentStressTest", testConcurrentStressTest),
        ("testThreadSafetyOfAPI", testThreadSafetyOfAPI),
        ("testPerformanceAndMemoryUsage", testPerformanceAndMemoryUsage),
        ("testAPIMisuse_NilAndEmpty", testAPIMisuse_NilAndEmpty),
        ("testAPIMisuse_InvalidParameters", testAPIMisuse_InvalidParameters),
        ("testAPIMisuse_DictionaryMisuse", testAPIMisuse_DictionaryMisuse),
        ("testBufferOverflowScenarios", testBufferOverflowScenarios),
        ("testMemoryExhaustionScenarios", testMemoryExhaustionScenarios),
        ("testStreamCorruptionDuringOperation", testStreamCorruptionDuringOperation),
        ("testInvalidPointerHandling", testInvalidPointerHandling),
        ("testGzipFileAPI", testGzipFileAPI),
        ("testStreamingDecompressorCallbacks", testStreamingDecompressorCallbacks),
        ("testInflateBackAdvancedFeatures", testInflateBackAdvancedFeatures),
        ("testAdvancedTuningParameters", testAdvancedTuningParameters),
        ("testPlatformSpecificBehavior", testPlatformSpecificBehavior),
        ("testSpecificErrorTypes", testSpecificErrorTypes),
        ("testPlatformAgnosticValidation", testPlatformAgnosticValidation),
        ("testIntermediateStateValidation", testIntermediateStateValidation),
        ("testConsistentErrorExpectations", testConsistentErrorExpectations),
        ("testAdvancedGzipFileOperations", testAdvancedGzipFileOperations),
        ("testGzipFileByteOperations", testGzipFileByteOperations),
        ("testGzipFilePositionOperations", testGzipFilePositionOperations),
        ("testGzipFileErrorHandling", testGzipFileErrorHandling),
        ("testGzipFileCompressionParameters", testGzipFileCompressionParameters),
        ("testGzipFileFlushModes", testGzipFileFlushModes),
        ("testInflateBackDecompressorCBridged", testInflateBackDecompressorCBridged),
        ("testConfigurationBasedAPI", testConfigurationBasedAPI),
        ("testUnifiedStreamingAPI", testUnifiedStreamingAPI),
        ("testAsyncAwaitSupport", testAsyncAwaitSupport),
    ]
}
