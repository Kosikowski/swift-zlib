# Error Handling Guide

SwiftZlib provides comprehensive error handling with detailed error types, recovery strategies, and debugging information.

## Error Types

### ZLibError

The main error type for zlib-related errors:

```swift
enum ZLibError: Error, LocalizedError {
    case invalidData
    case insufficientMemory
    case streamError(ZLibStatus)
    case fileError(String)
    case unsupportedOperation(String)
}
```

### ZLibStatus

Detailed status codes from the underlying zlib library:

```swift
enum ZLibStatus: Int32 {
    case ok = 0
    case streamEnd = 1
    case needDict = 2
    case errNo = -1
    case streamError = -2
    case dataError = -3
    case memoryError = -4
    case bufferError = -5
    case incompatibleVersion = -6
}
```

## Error Scenarios

### Invalid Data Errors

```swift
func handleInvalidData() {
    let invalidData = "This is not compressed data".data(using: .utf8)!

    do {
        let decompressed = try invalidData.decompress()
    } catch ZLibError.invalidData {
        print("Data is not valid compressed data")
    } catch {
        print("Other error: \(error)")
    }
}
```

### Memory Errors

```swift
func handleMemoryError() {
    let largeData = generateVeryLargeData() // 1GB+

    do {
        let compressed = try largeData.compress(level: .best)
    } catch ZLibError.insufficientMemory {
        print("Not enough memory for compression")
        // Try with lower memory level
        try compressWithLowerMemory(largeData)
    } catch {
        print("Other error: \(error)")
    }
}

func compressWithLowerMemory(_ data: Data) throws -> Data {
    let config = StreamingConfig(
        chunkSize: 16 * 1024,  // Smaller chunks
        memoryLevel: .min       // Minimal memory
    )

    let stream = ZLibStream(config: config)
    return try stream.compress(data)
}
```

### Stream Errors

```swift
func handleStreamError() {
    do {
        let compressed = try data.compress()
    } catch ZLibError.streamError(let status) {
        switch status {
        case .dataError:
            print("Data corruption detected")
        case .memoryError:
            print("Memory allocation failed")
        case .streamError:
            print("Stream state error")
        case .bufferError:
            print("Buffer overflow")
        default:
            print("Unknown stream error: \(status)")
        }
    } catch {
        print("Other error: \(error)")
    }
}
```

### File Operation Errors

```swift
func handleFileErrors() {
    do {
        try ZLib.compressFile(from: "nonexistent.txt", to: "output.gz")
    } catch ZLibError.fileError(let message) {
        print("File operation failed: \(message)")

        // Check if file exists
        if !FileManager.default.fileExists(atPath: "nonexistent.txt") {
            print("Source file does not exist")
        }

        // Check permissions
        if !FileManager.default.isReadableFile(atPath: "nonexistent.txt") {
            print("Cannot read source file")
        }
    } catch {
        print("Other error: \(error)")
    }
}
```

## Recovery Strategies

### Fallback Compression

```swift
func compressWithFallback(_ data: Data) -> Data {
    // Try best compression first
    do {
        return try data.compress(level: .best)
    } catch ZLibError.insufficientMemory {
        // Fall back to faster compression
        do {
            return try data.compress(level: .bestSpeed)
        } catch {
            // Fall back to no compression
            return data
        }
    } catch {
        // For other errors, return original data
        return data
    }
}
```

### Progressive Memory Reduction

```swift
func compressWithProgressiveFallback(_ data: Data) throws -> Data {
    let memoryLevels: [MemoryLevel] = [.max, .default, .min]

    for memoryLevel in memoryLevels {
        do {
            let config = StreamingConfig(
                chunkSize: 64 * 1024,
                memoryLevel: memoryLevel
            )
            let stream = ZLibStream(config: config)
            return try stream.compress(data)
        } catch ZLibError.insufficientMemory {
            continue // Try next memory level
        }
    }

    throw ZLibError.insufficientMemory
}
```

### Chunked Processing for Large Data

```swift
func compressLargeData(_ data: Data) throws -> Data {
    let chunkSize = 1024 * 1024 // 1MB chunks
    var compressedData = Data()

    for i in stride(from: 0, to: data.count, by: chunkSize) {
        let endIndex = min(i + chunkSize, data.count)
        let chunk = data[i..<endIndex]

        do {
            let compressed = try chunk.compress(level: .best)
            compressedData.append(compressed)
        } catch ZLibError.insufficientMemory {
            // Try with smaller chunk
            let smallerChunk = data[i..<min(i + chunkSize/2, data.count)]
            let compressed = try smallerChunk.compress(level: .bestSpeed)
            compressedData.append(compressed)
        }
    }

    return compressedData
}
```

### Error Recovery with Retry

```swift
func compressWithRetry(_ data: Data, maxRetries: Int = 3) throws -> Data {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try data.compress(level: .best)
        } catch ZLibError.insufficientMemory {
            lastError = ZLibError.insufficientMemory
            // Wait before retry
            Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
            continue
        } catch {
            lastError = error
            break
        }
    }

    throw lastError ?? ZLibError.unsupportedOperation("Unknown error")
}
```

## Debugging Techniques

### Error Logging

```swift
func debugCompression(_ data: Data) {
    print("Input data size: \(data.count) bytes")

    do {
        let compressed = try data.compress(level: .best)
        print("Compression successful")
        print("Compressed size: \(compressed.count) bytes")
        print("Compression ratio: \(Double(compressed.count) / Double(data.count))")

        let decompressed = try compressed.decompress()
        print("Decompression successful")
        print("Round-trip verification: \(data == decompressed ? "PASS" : "FAIL")")

    } catch ZLibError.invalidData {
        print("ERROR: Invalid input data")
        print("Data preview: \(data.prefix(100))")

    } catch ZLibError.insufficientMemory {
        print("ERROR: Insufficient memory")
        print("Available memory: \(ProcessInfo.processInfo.physicalMemory)")
        print("Data size: \(data.count)")

    } catch ZLibError.streamError(let status) {
        print("ERROR: Stream error - \(status)")
        print("Status code: \(status.rawValue)")

    } catch {
        print("ERROR: \(error)")
        print("Error type: \(type(of: error))")
    }
}
```

### Memory Usage Monitoring

```swift
func monitorMemoryUsage<T>(_ operation: () throws -> T) throws -> T {
    let startMemory = getMemoryUsage()
    print("Memory before operation: \(startMemory) MB")

    let result = try operation()

    let endMemory = getMemoryUsage()
    print("Memory after operation: \(endMemory) MB")
    print("Memory delta: \(endMemory - startMemory) MB")

    return result
}

func getMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }

    if kerr == KERN_SUCCESS {
        return Double(info.resident_size) / 1024.0 / 1024.0
    } else {
        return 0.0
    }
}
```

### Stream State Debugging

```swift
func debugStreamState(_ stream: ZLibStream) {
    // This would require adding debug methods to ZLibStream
    print("Stream configuration:")
    print("  Chunk size: \(stream.config.chunkSize)")
    print("  Memory level: \(stream.config.memoryLevel)")
    print("  Compression level: \(stream.config.compressionLevel)")

    // Check stream health
    do {
        let testData = "test".data(using: .utf8)!
        let compressed = try stream.compress(testData)
        print("Stream is healthy")
    } catch {
        print("Stream error: \(error)")
    }
}
```

## Best Practices

### 1. Always Handle Errors

```swift
// ❌ Bad - ignoring errors
let compressed = try! data.compress()

// ✅ Good - proper error handling
do {
    let compressed = try data.compress()
    return compressed
} catch {
    print("Compression failed: \(error)")
    return data // Return original data as fallback
}
```

### 2. Use Specific Error Types

```swift
// ❌ Bad - generic error handling
do {
    let compressed = try data.compress()
} catch {
    print("Error: \(error)")
}

// ✅ Good - specific error handling
do {
    let compressed = try data.compress()
} catch ZLibError.invalidData {
    print("Invalid input data")
} catch ZLibError.insufficientMemory {
    print("Not enough memory")
} catch ZLibError.streamError(let status) {
    print("Stream error: \(status)")
} catch {
    print("Unknown error: \(error)")
}
```

### 3. Provide Meaningful Error Messages

```swift
func compressWithContext(_ data: Data, context: String) throws -> Data {
    do {
        return try data.compress()
    } catch ZLibError.invalidData {
        throw ZLibError.fileError("Invalid data in context: \(context)")
    } catch ZLibError.insufficientMemory {
        throw ZLibError.fileError("Insufficient memory for \(context), data size: \(data.count)")
    } catch {
        throw ZLibError.fileError("Compression failed for \(context): \(error)")
    }
}
```

### 4. Implement Graceful Degradation

```swift
func compressWithDegradation(_ data: Data) -> Data {
    // Try multiple approaches with graceful degradation
    let approaches: [(CompressionLevel, String)] = [
        (.best, "Best compression"),
        (.bestSpeed, "Fast compression"),
        (.default, "Default compression"),
        (.noCompression, "No compression")
    ]

    for (level, description) in approaches {
        do {
            let compressed = try data.compress(level: level)
            print("Success with \(description)")
            return compressed
        } catch {
            print("Failed with \(description): \(error)")
            continue
        }
    }

    // If all approaches fail, return original data
    print("All compression approaches failed, returning original data")
    return data
}
```

### 5. Log Errors for Debugging

```swift
func logCompressionError(_ error: Error, data: Data, context: String) {
    let errorInfo = """
    Compression Error:
    Context: \(context)
    Data size: \(data.count) bytes
    Error type: \(type(of: error))
    Error description: \(error.localizedDescription)
    Timestamp: \(Date())
    """

    print(errorInfo)

    // Optionally save to log file
    if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let logFile = documentsPath.appendingPathComponent("compression_errors.log")
        try? errorInfo.appendLineToURL(fileURL: logFile)
    }
}
```

## Error Prevention

### Input Validation

```swift
func validateInput(_ data: Data) throws {
    guard !data.isEmpty else {
        throw ZLibError.invalidData
    }

    guard data.count <= 100 * 1024 * 1024 else { // 100MB limit
        throw ZLibError.unsupportedOperation("Data too large: \(data.count) bytes")
    }

    // Check for common invalid patterns
    if data.count > 0 && data.allSatisfy({ $0 == 0 }) {
        throw ZLibError.invalidData
    }
}
```

### Resource Management

```swift
func compressWithResourceManagement(_ data: Data) throws -> Data {
    // Check available memory
    let availableMemory = ProcessInfo.processInfo.physicalMemory
    let requiredMemory = UInt64(data.count * 10) // Estimate 10x for compression

    guard availableMemory > requiredMemory else {
        throw ZLibError.insufficientMemory
    }

    // Use autorelease pool for memory management
    return try autoreleasepool {
        try data.compress(level: .best)
    }
}
```

### Configuration Validation

```swift
func validateStreamConfig(_ config: StreamingConfig) throws {
    guard config.chunkSize > 0 else {
        throw ZLibError.unsupportedOperation("Invalid chunk size: \(config.chunkSize)")
    }

    guard config.chunkSize <= 100 * 1024 * 1024 else { // 100MB limit
        throw ZLibError.unsupportedOperation("Chunk size too large: \(config.chunkSize)")
    }

    // Validate memory level
    switch config.memoryLevel {
    case .min, .default, .max:
        break
    default:
        throw ZLibError.unsupportedOperation("Invalid memory level")
    }
}
```

This error handling guide provides comprehensive coverage of error scenarios, recovery strategies, debugging techniques, and best practices for robust error handling in SwiftZlib applications.
