#!/usr/bin/env swift

import Foundation
import SwiftZlib

// MARK: - Command Line Interface

print("🚀 SwiftZlib Command Line Tool")
print("================================")

// Parse command line arguments
let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    printUsage()
    exit(1)
}

let command = arguments[1]
let remainingArgs = Array(arguments.dropFirst(2))

switch command {
case "compress":
    handleCompress(remainingArgs)
case "decompress":
    handleDecompress(remainingArgs)
case "benchmark":
    handleBenchmark(remainingArgs)
case "checksum":
    handleChecksum(remainingArgs)
case "info":
    handleInfo(remainingArgs)
case "stream":
    handleStream(remainingArgs)
case "gzip":
    handleGzip(remainingArgs)
case "large":
    handleLargeFile(remainingArgs)
case "memory":
    handleMemoryInfo(remainingArgs)
case "help", "--help", "-h":
    printUsage()
default:
    print("❌ Unknown command: \(command)")
    printUsage()
    exit(1)
}

// MARK: - Command Handlers

func handleCompress(_ args: [String]) {
    guard args.count >= 2 else {
        print("❌ Usage: compress <input> <output> [level]")
        exit(1)
    }
    
    let inputPath = args[0]
    let outputPath = args[1]
    let level = args.count > 2 ? CompressionLevel(rawValue: Int32(args[2]) ?? 6) ?? .defaultCompression : .defaultCompression
    
    do {
        print("📦 Compressing \(inputPath) -> \(outputPath) (level: \(level))")
        
        if FileManager.default.fileExists(atPath: inputPath) {
            // File compression
            try ZLib.compressFile(from: inputPath, to: outputPath)
            print("✅ File compressed successfully")
        } else {
            // Data compression
            let data = inputPath.data(using: .utf8) ?? Data()
            let compressed = try data.compressed(level: level)
            try compressed.write(to: URL(fileURLWithPath: outputPath))
            print("✅ Data compressed successfully")
            print("📊 Compression ratio: \(String(format: "%.2f", Double(compressed.count) / Double(data.count)))")
        }
    } catch {
        print("❌ Compression failed: \(error)")
        exit(1)
    }
}

func handleDecompress(_ args: [String]) {
    guard args.count >= 2 else {
        print("❌ Usage: decompress <input> <output>")
        exit(1)
    }
    
    let inputPath = args[0]
    let outputPath = args[1]
    
    do {
        print("📦 Decompressing \(inputPath) -> \(outputPath)")
        
        if FileManager.default.fileExists(atPath: inputPath) {
            // File decompression
            try ZLib.decompressFile(from: inputPath, to: outputPath)
            print("✅ File decompressed successfully")
        } else {
            // Data decompression
            let data = inputPath.data(using: .utf8) ?? Data()
            let decompressed = try data.decompressed()
            try decompressed.write(to: URL(fileURLWithPath: outputPath))
            print("✅ Data decompressed successfully")
        }
    } catch {
        print("❌ Decompression failed: \(error)")
        exit(1)
    }
}

func handleBenchmark(_ args: [String]) {
    guard args.count >= 1 else {
        print("❌ Usage: benchmark <input_file>")
        exit(1)
    }
    
    let inputPath = args[0]
    
    do {
        print("🏃 Benchmarking compression levels for: \(inputPath)")
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) else {
            print("❌ Could not read file: \(inputPath)")
            exit(1)
        }
        
        let levels: [CompressionLevel] = [.noCompression, .bestSpeed, .defaultCompression, .bestCompression]
        
        print("\n📊 Compression Benchmark Results:")
        print("Level\t\tSize\t\tRatio\t\tTime (ms)")
        print("-----\t\t----\t\t-----\t\t--------")
        
        for level in levels {
            let startTime = CFAbsoluteTimeGetCurrent()
            let compressed = try data.compressed(level: level)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let ratio = Double(compressed.count) / Double(data.count)
            let timeMs = (endTime - startTime) * 1000
            
            print("\(level)\t\t\(compressed.count)\t\t\(String(format: "%.2f", ratio))\t\t\(String(format: "%.1f", timeMs))")
        }
        
        // Show performance profiles
        print("\n📈 Performance Profiles:")
        let profiles = ZLib.getPerformanceProfiles(for: data.count)
        for profile in profiles {
            print("\(profile.level): ~\(String(format: "%.1f", profile.estimatedTime))s, ratio: \(String(format: "%.2f", profile.estimatedRatio))")
        }
        
    } catch {
        print("❌ Benchmark failed: \(error)")
        exit(1)
    }
}

func handleChecksum(_ args: [String]) {
    guard args.count >= 1 else {
        print("❌ Usage: checksum <input_file>")
        exit(1)
    }
    
    let inputPath = args[0]
    
    print("🔍 Calculating checksums for: \(inputPath)")
    
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) else {
        print("❌ Could not read file: \(inputPath)")
        exit(1)
    }
    
    let adler32 = data.adler32()
    let crc32 = data.crc32()
    
    print("📊 Checksum Results:")
    print("Adler-32: \(String(format: "%08X", adler32))")
    print("CRC-32:   \(String(format: "%08X", crc32))")
}

func handleInfo(_ args: [String]) {
    print("📋 SwiftZlib Information")
    print("========================")
    
    print("ZLib Version: \(ZLib.version)")
    print("Compile Flags: \(String(format: "0x%016X", ZLib.compileFlags))")
    
    let flags = ZLib.compileFlagsInfo
    print("\n📊 Compile Flags Breakdown:")
    print("Size of unsigned int: \(flags.sizeOfUInt) bytes")
    print("Size of unsigned long: \(flags.sizeOfULong) bytes")
    print("Size of pointer: \(flags.sizeOfPointer) bytes")
    print("Size of z_off_t: \(flags.sizeOfZOffT) bytes")
    print("Compiler flags: \(String(format: "0x%04X", flags.compilerFlags))")
    print("Library flags: \(String(format: "0x%04X", flags.libraryFlags))")
    print("Debug build: \(flags.isDebug)")
    print("Optimized build: \(flags.isOptimized)")
    
    // Buffer recommendations
    let (inputBuffer, outputBuffer) = Data.getRecommendedBufferSizes()
    print("\n📦 Buffer Recommendations:")
    print("Input buffer size: \(inputBuffer) bytes")
    print("Output buffer size: \(outputBuffer) bytes")
    
    // Memory usage
    let memoryUsage = Data.estimateMemoryUsage()
    print("Estimated memory usage: \(memoryUsage) bytes")
    
    // Optimal parameters for different data sizes
    print("\n⚙️ Optimal Parameters:")
    let sizes = [1024, 1024*1024, 10*1024*1024]
    for size in sizes {
        let params = ZLib.getOptimalParameters(for: size)
        let formatter = ByteCountFormatter()
        print("\(formatter.string(fromByteCount: Int64(size))): \(params.level), \(params.windowBits), \(params.memoryLevel), \(params.strategy)")
    }
}

func handleStream(_ args: [String]) {
    guard args.count >= 2 else {
        print("❌ Usage: stream <input> <output>")
        exit(1)
    }
    
    let inputPath = args[0]
    let outputPath = args[1]
    
    do {
        print("🌊 Streaming compression: \(inputPath) -> \(outputPath)")
        
        // Use streaming configuration
        let config = StreamingConfig(
            bufferSize: 4096,
            compressionLevel: 6
        )
        
        try ZLib.compressFile(from: inputPath, to: outputPath, config: config)
        print("✅ Streaming compression completed")
        
    } catch {
        print("❌ Streaming failed: \(error)")
        exit(1)
    }
}

func handleGzip(_ args: [String]) {
    guard args.count >= 2 else {
        print("❌ Usage: gzip <input> <output>")
        exit(1)
    }
    
    let inputPath = args[0]
    let outputPath = args[1]
    
    do {
        print("🗜️ Gzip compression: \(inputPath) -> \(outputPath)")
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) else {
            print("❌ Could not read file: \(inputPath)")
            exit(1)
        }
        
        // Create gzip header
        var header = GzipHeader()
        header.name = URL(fileURLWithPath: inputPath).lastPathComponent
        header.comment = "Compressed with SwiftZlib"
        header.time = UInt32(Date().timeIntervalSince1970)
        
        let compressed = try data.compressedWithGzipHeader(level: .defaultCompression, header: header)
        try compressed.write(to: URL(fileURLWithPath: outputPath))
        
        print("✅ Gzip compression completed")
        print("📊 Compression ratio: \(String(format: "%.2f", Double(compressed.count) / Double(data.count)))")
        
    } catch {
        print("❌ Gzip compression failed: \(error)")
        exit(1)
    }
}

func handleLargeFile(_ args: [String]) {
    guard args.count >= 2 else {
        print("❌ Usage: large <input> <output> [level]")
        print("   This command is designed for large files (>100MB) with progress tracking")
        exit(1)
    }
    
    let inputPath = args[0]
    let outputPath = args[1]
    let level = args.count > 2 ? Int(args[2]) ?? 6 : 6
    
    do {
        print("🗜️ Large file compression: \(inputPath) -> \(outputPath)")
        print("📊 Using streaming compression with progress tracking...")
        
        // Check file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: inputPath)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        let fileSizeMB = Double(fileSize) / (1024 * 1024)
        
        print("📁 File size: \(String(format: "%.1f", fileSizeMB)) MB")
        
        // Create compressor with appropriate buffer size for large files
        let bufferSize = 128 * 1024 // 128KB buffer for large files
        let compressor = FileChunkedCompressor(
            bufferSize: bufferSize,
            compressionLevel: CompressionLevel(rawValue: Int32(level)) ?? .defaultCompression,
            windowBits: .deflate
        )
        
        // Start compression with progress tracking
        let startTime = Date()
        try compressor.compressFile(
            from: inputPath,
            to: outputPath
        ) { processed, total in
            let percentage = Double(processed) / Double(total) * 100
            let elapsed = Date().timeIntervalSince(startTime)
            let speed = elapsed > 0 ? Double(processed) / elapsed : 0
            let eta = speed > 0 ? Double(total - processed) / speed : 0
            
            // Update progress bar
            updateProgressBar(
                percentage: percentage,
                processed: processed,
                total: total,
                speed: speed,
                eta: eta
            )
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("\n✅ Large file compression completed!")
        print("⏱️ Total time: \(String(format: "%.1f", totalTime)) seconds")
        print("📊 Average speed: \(String(format: "%.1f", Double(fileSize) / totalTime / (1024 * 1024))) MB/s")
        
        // Show compression ratio
        let compressedAttributes = try FileManager.default.attributesOfItem(atPath: outputPath)
        let compressedSize = compressedAttributes[.size] as? Int64 ?? 0
        let ratio = Double(compressedSize) / Double(fileSize)
        print("📦 Compression ratio: \(String(format: "%.2f", ratio)) (\(String(format: "%.1f", (1 - ratio) * 100))% reduction)")
        
    } catch {
        print("\n❌ Large file compression failed: \(error)")
        exit(1)
    }
}

func handleMemoryInfo(_ args: [String]) {
    print("🧠 Memory Level Information")
    print("==========================")
    print()
    
    let levels: [MemoryLevel] = [
        .minimum, .level2, .level3, .level4, .level5, .level6, .level7, .level8, .maximum
    ]
    
    print("Level | Memory Usage | Performance | Use Case")
    print("------|-------------|------------|---------")
    
    for level in levels {
        let memoryUsage = level.memoryUsageDescription
        let performance = level.performanceDescription
        let useCase: String
        
        switch level {
        case .minimum:
            useCase = "Memory-constrained systems"
        case .level2, .level3:
            useCase = "Limited memory environments"
        case .level4, .level5:
            useCase = "General purpose applications"
        case .level6, .level7:
            useCase = "Modern systems with good memory"
        case .level8, .maximum:
            useCase = "High-performance servers"
        }
        
        print("\(level.rawValue)     | \(memoryUsage.padding(toLength: 11, withPad: " ", startingAt: 0)) | \(performance.padding(toLength: 11, withPad: " ", startingAt: 0)) | \(useCase)")
    }
    
    print()
    print("📊 Memory Usage Formula: 2^(memLevel + 6) bytes")
    print("💡 Higher levels use more memory but provide better compression speed")
    print("🔧 Choose based on your system's memory constraints and performance needs")
}

// MARK: - Helper Functions

func printUsage() {
    print("""
    SwiftZlib Command Line Tool
    
    Usage: swift run SwiftZlibCLI <command> [options]
    
    Commands:
        compress <input> <output> [level]    Compress file or data
        decompress <input> <output>          Decompress file or data
        benchmark <input_file>               Benchmark compression levels
        checksum <input_file>                Calculate Adler-32 and CRC-32
        info                                 Show library information
        stream <input> <output>              Streaming compression
        gzip <input> <output>               Gzip compression with headers
        large <input> <output> [level]      Large file compression with progress
        memory                               Show memory level information
        help                                 Show this help message
    
    Examples:
        swift run SwiftZlibCLI compress input.txt output.zlib 6
        swift run SwiftZlibCLI decompress output.zlib result.txt
        swift run SwiftZlibCLI benchmark large_file.dat
        swift run SwiftZlibCLI checksum important_file.txt
        swift run SwiftZlibCLI info
        swift run SwiftZlibCLI stream big_file.dat compressed.zlib
        swift run SwiftZlibCLI gzip document.txt document.gz
        swift run SwiftZlibCLI large huge_file.dat compressed.zlib 9
        swift run SwiftZlibCLI memory
    
    Compression Levels:
        0 - No compression
        1 - Best speed
        6 - Default compression
        9 - Best compression
    """)
}

func updateProgressBar(percentage: Double, processed: Int, total: Int, speed: Double, eta: Double) {
    let barWidth = 50
    let filledWidth = Int(percentage / 100.0 * Double(barWidth))
    let bar = String(repeating: "█", count: filledWidth) + String(repeating: "░", count: barWidth - filledWidth)
    
    let processedMB = Double(processed) / (1024 * 1024)
    let totalMB = Double(total) / (1024 * 1024)
    let speedMB = speed / (1024 * 1024)
    
    let etaString = eta > 0 ? String(format: "%.0fs", eta) : "∞"
    
    print("\r📦 [\(bar)] \(String(format: "%.1f", percentage))% (\(String(format: "%.1f", processedMB))/\(String(format: "%.1f", totalMB)) MB) \(String(format: "%.1f", speedMB)) MB/s ETA: \(etaString)", terminator: "")
    fflush(stdout)
} 