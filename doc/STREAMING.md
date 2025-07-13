# Streaming Documentation

SwiftZlib provides powerful streaming capabilities for processing large data without loading everything into memory at once.

## Overview

Streaming compression and decompression allows you to process data in chunks, making it ideal for:

- Large files that don't fit in memory
- Real-time data processing
- Network streaming
- Memory-constrained environments

## Core Concepts

### StreamingConfig

The `StreamingConfig` struct controls how streaming operations behave:

```swift
let config = StreamingConfig(
    chunkSize: 64 * 1024,           // 64KB chunks
    compressionLevel: .best,         // Best compression
    compressionStrategy: .default,    // Default strategy
    memoryLevel: .default            // Default memory usage
)
```

### ZLibStream

The main streaming interface that handles both compression and decompression:

```swift
let stream = ZLibStream(config: config)
```

## Usage Patterns

### File-to-File Streaming

```swift
// Compress a large file
let config = StreamingConfig(
    chunkSize: 128 * 1024,
    compressionLevel: .best
)

let stream = ZLibStream(config: config)
try stream.compressFile(from: "large-input.txt", to: "compressed.gz")

// Decompress a large file
try stream.decompressFile(from: "compressed.gz", to: "decompressed.txt")
```

### Memory-to-Memory Streaming

```swift
let stream = ZLibStream(config: config)

// Process data in chunks
let inputData = largeDataArray
var compressedData = Data()

for chunk in inputData.chunked(into: 64 * 1024) {
    let compressed = try stream.compress(chunk)
    compressedData.append(compressed)
}

// Finalize compression
let final = try stream.finish()
compressedData.append(final)
```

### Custom Stream Processing

```swift
class CustomStreamProcessor {
    private let stream: ZLibStream
    private var outputBuffer = Data()

    init(config: StreamingConfig) {
        self.stream = ZLibStream(config: config)
    }

    func processChunk(_ data: Data) throws -> Data? {
        let compressed = try stream.compress(data)
        outputBuffer.append(compressed)

        // Return chunks when buffer is large enough
        if outputBuffer.count > 1024 * 1024 {
            let result = outputBuffer
            outputBuffer.removeAll()
            return result
        }
        return nil
    }

    func finish() throws -> Data {
        let final = try stream.finish()
        outputBuffer.append(final)
        return outputBuffer
    }
}
```

## Configuration Options

### Chunk Size

Choose chunk size based on your use case:

```swift
// Small chunks for real-time processing
let realtimeConfig = StreamingConfig(chunkSize: 4 * 1024)

// Large chunks for file processing
let fileConfig = StreamingConfig(chunkSize: 256 * 1024)

// Very large chunks for high-throughput
let throughputConfig = StreamingConfig(chunkSize: 1024 * 1024)
```

### Memory Level

Control memory usage vs performance trade-off:

```swift
// Minimal memory usage
let memoryEfficient = StreamingConfig(memoryLevel: .min)

// Balanced approach
let balanced = StreamingConfig(memoryLevel: .default)

// Maximum performance
let highPerformance = StreamingConfig(memoryLevel: .max)
```

### Compression Level

```swift
// Fast compression
let fastConfig = StreamingConfig(compressionLevel: .bestSpeed)

// Best compression ratio
let bestConfig = StreamingConfig(compressionLevel: .best)

// No compression (for testing)
let noCompression = StreamingConfig(compressionLevel: .noCompression)
```

## Advanced Patterns

### Progress Reporting

```swift
let stream = ZLibStream(config: config)

try stream.compressFile(
    from: "input.txt",
    to: "output.gz",
    progress: { progress in
        DispatchQueue.main.async {
            progressView.progress = Float(progress)
            statusLabel.text = "\(Int(progress * 100))%"
        }
    }
)
```

### Error Handling

```swift
do {
    try stream.compressFile(from: "input.txt", to: "output.gz")
} catch ZLibError.streamError(let status) {
    print("Stream error: \(status)")
} catch ZLibError.invalidData {
    print("Invalid input data")
} catch {
    print("Other error: \(error)")
}
```

### Dictionary Compression

```swift
let dictionary = "common prefix".data(using: .utf8)!
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    compressionLevel: .best
)

let stream = ZLibStream(config: config)
try stream.setDictionary(dictionary)
try stream.compressFile(from: "input.txt", to: "output.gz")
```

## Performance Considerations

### Memory Usage

- **Small chunks** (4-16KB): Lower memory usage, more CPU overhead
- **Medium chunks** (64-256KB): Balanced approach
- **Large chunks** (1MB+): Higher memory usage, better compression

### CPU Usage

- **Compression level**: Higher levels use more CPU
- **Strategy**: Different strategies have different CPU profiles
- **Chunk size**: Smaller chunks mean more function calls

### Throughput

```swift
// High throughput configuration
let highThroughput = StreamingConfig(
    chunkSize: 1024 * 1024,     // 1MB chunks
    compressionLevel: .bestSpeed, // Fast compression
    memoryLevel: .max            // Maximum memory for speed
)
```

## Best Practices

### 1. Choose Appropriate Chunk Sizes

```swift
// For network streaming
let networkConfig = StreamingConfig(chunkSize: 8 * 1024)

// For file processing
let fileConfig = StreamingConfig(chunkSize: 256 * 1024)

// For memory-constrained environments
let memoryConfig = StreamingConfig(chunkSize: 16 * 1024)
```

### 2. Handle Errors Gracefully

```swift
func safeCompress(input: String, output: String) throws {
    let stream = ZLibStream(config: .default)

    do {
        try stream.compressFile(from: input, to: output)
    } catch {
        // Clean up partial output
        try? FileManager.default.removeItem(atPath: output)
        throw error
    }
}
```

### 3. Use Progress Reporting for Long Operations

```swift
let stream = ZLibStream(config: .default)

try stream.compressFile(
    from: "large-file.txt",
    to: "compressed.gz",
    progress: { progress in
        // Update UI on main thread
        DispatchQueue.main.async {
            self.updateProgress(progress)
        }
    }
)
```

### 4. Consider Memory Constraints

```swift
// For mobile devices
let mobileConfig = StreamingConfig(
    chunkSize: 32 * 1024,
    memoryLevel: .min
)

// For desktop applications
let desktopConfig = StreamingConfig(
    chunkSize: 256 * 1024,
    memoryLevel: .max
)
```

## Troubleshooting

### Common Issues

**Memory Pressure**

- Reduce chunk size
- Use lower memory level
- Process smaller files

**Poor Performance**

- Increase chunk size
- Use higher memory level
- Choose appropriate compression level

**Stream Errors**

- Check input data validity
- Verify file permissions
- Ensure sufficient disk space

### Debugging

```swift
// Enable logging
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    enableLogging: true
)

let stream = ZLibStream(config: config)
// Logs will show compression progress and errors
```

## Examples

### Complete File Processing

```swift
func processLargeFile(input: String, output: String) async throws {
    let config = StreamingConfig(
        chunkSize: 128 * 1024,
        compressionLevel: .best,
        memoryLevel: .default
    )

    let stream = ZLibStream(config: config)

    try await withCheckedThrowingContinuation { continuation in
        do {
            try stream.compressFile(
                from: input,
                to: output,
                progress: { progress in
                    print("Progress: \(Int(progress * 100))%")
                }
            )
            continuation.resume()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
```

### Network Streaming

```swift
class NetworkStreamProcessor {
    private let stream: ZLibStream
    private let networkClient: NetworkClient

    init() {
        let config = StreamingConfig(
            chunkSize: 8 * 1024,
            compressionLevel: .bestSpeed
        )
        self.stream = ZLibStream(config: config)
        self.networkClient = NetworkClient()
    }

    func streamToNetwork(data: Data) async throws {
        for chunk in data.chunked(into: 8 * 1024) {
            let compressed = try stream.compress(chunk)
            try await networkClient.send(compressed)
        }

        let final = try stream.finish()
        try await networkClient.send(final)
    }
}
```

This streaming documentation provides comprehensive coverage of streaming capabilities, configuration options, best practices, and real-world usage patterns.
