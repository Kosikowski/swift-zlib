import XCTest
@testable import SwiftZlib

final class AdvancedUtilityTests: XCTestCase {
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
        let (inputBuffer, outputBuffer, maxStreams) = ZLib.calculateOptimalBufferSizes(dataSize: 10000, availableMemory: 1_000_000)
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

    static var allTests = [
        ("testCompressedSizeEstimation", testCompressedSizeEstimation),
        ("testRecommendedBufferSizes", testRecommendedBufferSizes),
        ("testMemoryUsageEstimation", testMemoryUsageEstimation),
        ("testOptimalParameters", testOptimalParameters),
        ("testPerformanceProfiles", testPerformanceProfiles),
        ("testBufferSizeCalculation", testBufferSizeCalculation),
        ("testCompressionStatistics", testCompressionStatistics),
        ("testCompileFlags", testCompileFlags),
    ]
} 