# Advanced Features

This document covers advanced features and techniques for using SwiftZlib effectively.

## Fluent Builder Pattern

SwiftZlib provides fluent builder APIs for creating and configuring compression/decompression streams with a clean, chainable interface.

### ZLibStreamBuilder

The `ZLibStreamBuilder` allows you to configure and create zlib streams using a fluent interface.

```swift
// Create a compressor with custom configuration
let compressor = ZLib.stream()
    .compression(level: .best)
    .strategy(.huffman)
    .windowBits(.gzip)
    .memoryLevel(.maximum)
    .chunkSize(128 * 1024)
    .buildCompressor()

// Create a decompressor with custom configuration
let decompressor = ZLib.stream()
    .decompression()
    .windowBits(.gzip)
    .memoryLevel(.minimum)
    .chunkSize(64 * 1024)
    .buildDecompressor()

// Create a complete stream for both operations
let stream = ZLib.stream()
    .compression(level: .best, strategy: .huffman)
    .windowBits(.gzip)
    .build()
```

### AsyncZLibStreamBuilder

For asynchronous operations, use the `AsyncZLibStreamBuilder`:

```swift
// Create an async compressor
let asyncCompressor = ZLib.asyncStream()
    .compression(level: .best)
    .strategy(.huffman)
    .windowBits(.gzip)
    .buildCompressor()

// Create an async decompressor
let asyncDecompressor = ZLib.asyncStream()
    .decompression()
    .windowBits(.gzip)
    .buildDecompressor()

// Create an async stream
let asyncStream = ZLib.asyncStream()
    .compression(level: .best, strategy: .huffman)
    .windowBits(.gzip)
    .build()
```

### Builder Configuration Options

#### Compression Configuration

```swift
// Basic compression
.compression(level: .best)

// Compression with strategy
.compression(level: .best, strategy: .huffman)

// Compression with custom window bits
.compression(level: .best, strategy: .huffman)
.windowBits(.gzip)
```

#### Decompression Configuration

```swift
// Basic decompression
.decompression()

// Decompression with custom window bits
.decompression()
.windowBits(.gzip)
```

#### Memory and Performance Configuration

```swift
// Memory usage level
.memoryLevel(.maximum)  // For best performance
.memoryLevel(.minimum)  // For memory-constrained environments

// Chunk size for streaming
.chunkSize(128 * 1024)  // 128KB chunks
.chunkSize(64 * 1024)   // 64KB chunks
```

## Chunked File Operations

For processing large files efficiently without loading them entirely into memory, SwiftZlib provides specialized chunked file operations.

### FileChunkedCompressor

The `FileChunkedCompressor` processes files in chunks with constant memory usage:

```swift
// Create a chunked compressor
let compressor = FileChunkedCompressor(
    level: .best,
    chunkSize: 64 * 1024  // 64KB chunks
)

// Compress a large file with progress reporting
try compressor.compressFile(
    at: "large-input.txt",
    to: "compressed.gz",
    progress: { processed, total in
        let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
        print("Compression progress: \(percentage)%")
    }
)

// Compress with custom strategy
let compressorWithStrategy = FileChunkedCompressor(
    level: .best,
    strategy: .huffman,
    windowBits: .gzip,
    chunkSize: 128 * 1024
)

try compressorWithStrategy.compressFile(
    at: "image-data.bin",
    to: "compressed-image.gz"
)
```

### FileChunkedDecompressor

The `FileChunkedDecompressor` handles large compressed files efficiently:

```swift
// Create a chunked decompressor
let decompressor = FileChunkedDecompressor(
    windowBits: .gzip,
    chunkSize: 64 * 1024
)

// Decompress a large file with progress reporting
try decompressor.decompressFile(
    at: "compressed.gz",
    to: "decompressed.txt",
    progress: { processed, total in
        let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
        print("Decompression progress: \(percentage)%")
    }
)

// Decompress with custom window bits
let customDecompressor = FileChunkedDecompressor(
    windowBits: .raw,
    chunkSize: 128 * 1024
)

try customDecompressor.decompressFile(
    at: "raw-compressed.bin",
    to: "decompressed.txt"
)
```

### Memory Efficiency

Chunked operations use constant memory regardless of file size:

```swift
// Process a 1GB file with only 64KB memory usage
let compressor = FileChunkedCompressor(chunkSize: 64 * 1024)

try compressor.compressFile(
    at: "1gb-file.txt",
    to: "compressed.gz"
)
```

## Enhanced Decompressors

SwiftZlib provides enhanced decompressor classes with additional features for specialized use cases.

### EnhancedInflateBackDecompressor

The `EnhancedInflateBackDecompressor` provides advanced features for processing data in reverse order with custom callbacks:

```swift
// Create an enhanced decompressor
let decompressor = EnhancedInflateBackDecompressor(windowBits: .default)

// Process data with custom input/output callbacks
try decompressor.processWithCallbacks(
    input: compressedData,
    inputCallback: { chunk in
        // Custom input processing
        return chunk.reversed()  // Process in reverse
    },
    outputCallback: { output in
        // Custom output processing
        print("Processed: \(output.count) bytes")
        // Store or process output as needed
    }
)

// Get stream information
let info = try decompressor.getStreamInfo()
print("Total input: \(info.totalIn), Total output: \(info.totalOut), Active: \(info.isActive)")
```

### InflateBackDecompressor

The standard `InflateBackDecompressor` for reverse-order processing:

```swift
// Create a standard inflate back decompressor
let decompressor = InflateBackDecompressor(windowBits: .gzip)

// Process data in chunks
let result = try decompressor.decompress(compressedData, flush: .finish)
```

## Progress Stream APIs

SwiftZlib provides comprehensive progress reporting for all file operations, allowing you to monitor operation progress and provide user feedback.

### Progress Callbacks

All file operations support optional progress callbacks:

```swift
// Compression with progress
try compressor.compressFile(
    at: "input.txt",
    to: "output.gz",
    progress: { processed, total in
        if total > 0 {
            let percentage = Double(processed) / Double(total) * 100
            print("Compression: \(percentage)%")
        } else {
            print("Processed: \(processed) bytes")
        }
    }
)

// Decompression with progress
try decompressor.decompressFile(
    at: "compressed.gz",
    to: "decompressed.txt",
    progress: { processed, total in
        if total > 0 {
            let percentage = Double(processed) / Double(total) * 100
            print("Decompression: \(percentage)%")
        } else {
            print("Processed: \(processed) bytes")
        }
    }
)
```

### Progress Integration with UI

For iOS/macOS applications, you can integrate progress reporting with UI components:

```swift
// SwiftUI progress view integration
struct CompressionView: View {
    @State private var progress: Double = 0
    @State private var isCompressing = false

    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            Text("\(Int(progress * 100))%")
        }
        .onAppear {
            compressFile()
        }
    }

    private func compressFile() {
        isCompressing = true
        let compressor = FileChunkedCompressor()

        try? compressor.compressFile(
            at: "input.txt",
            to: "output.gz",
            progress: { processed, total in
                DispatchQueue.main.async {
                    if total > 0 {
                        self.progress = Double(processed) / Double(total)
                    }
                }
            }
        )
        isCompressing = false
    }
}
```

### Progress with Combine

For reactive programming, you can create publishers that emit progress updates:

```swift
// Create a progress publisher
class CompressionProgress {
    private let compressor = FileChunkedCompressor()

    func compressWithProgress(input: String, output: String) -> AnyPublisher<Double, ZLibError> {
        return Future { promise in
            do {
                try self.compressor.compressFile(
                    at: input,
                    to: output,
                    progress: { processed, total in
                        if total > 0 {
                            let progress = Double(processed) / Double(total)
                            promise(.success(progress))
                        }
                    }
                )
                promise(.success(1.0))
            } catch {
                promise(.failure(error as! ZLibError))
            }
        }
        .eraseToAnyPublisher()
    }
}

// Usage
let progress = CompressionProgress()
progress.compressWithProgress(input: "input.txt", output: "output.gz")
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Compression failed: \(error)")
            }
        },
        receiveValue: { progress in
            print("Progress: \(Int(progress * 100))%")
        }
    )
    .store(in: &cancellables)
```

## Advanced Streaming

### Custom Stream Processing

Create custom stream processing with the builder pattern:

```swift
// Custom stream with specific configuration
let customStream = ZLib.stream()
    .compression(level: .best, strategy: .huffman)
    .windowBits(.gzip)
    .memoryLevel(.maximum)
    .chunkSize(256 * 1024)
    .build()

// Process data in chunks
let inputData = "Hello, World!".data(using: .utf8)!
let compressed = try customStream.compress(inputData)
let final = try customStream.finish()
```

### Async Stream Processing

For asynchronous processing with progress reporting:

```swift
// Create async stream
let asyncStream = ZLib.asyncStream()
    .compression(level: .best)
    .windowBits(.gzip)
    .build()

// Process data asynchronously
Task {
    let result = try await asyncStream.process(inputData)
    let final = try await asyncStream.finish()
    print("Async compression completed")
}
```

## Memory Management

### Memory Level Configuration

Configure memory usage based on your application's needs:

```swift
// Minimum memory usage (good for embedded systems)
let lowMemoryCompressor = ZLib.stream()
    .compression(level: .default)
    .memoryLevel(.minimum)
    .buildCompressor()

// Maximum memory usage (best performance)
let highMemoryCompressor = ZLib.stream()
    .compression(level: .best)
    .memoryLevel(.maximum)
    .buildCompressor()

// Default memory usage (balanced)
let balancedCompressor = ZLib.stream()
    .compression(level: .default)
    .memoryLevel(.default)
    .buildCompressor()
```

### Chunk Size Optimization

Optimize chunk sizes for your specific use case:

```swift
// Small chunks for memory-constrained environments
let smallChunkCompressor = FileChunkedCompressor(
    level: .default,
    chunkSize: 16 * 1024  // 16KB chunks
)

// Large chunks for high-performance systems
let largeChunkCompressor = FileChunkedCompressor(
    level: .best,
    chunkSize: 512 * 1024  // 512KB chunks
)

// Balanced chunks for most applications
let balancedChunkCompressor = FileChunkedCompressor(
    level: .default,
    chunkSize: 64 * 1024  // 64KB chunks
)
```

## Error Handling

### Advanced Error Recovery

Handle specific error cases with detailed error information:

```swift
do {
    let compressor = FileChunkedCompressor()
    try compressor.compressFile(at: "input.txt", to: "output.gz")
} catch ZLibError.invalidParameter {
    print("Invalid parameters provided")
} catch ZLibError.bufferError {
    print("Buffer error occurred")
} catch ZLibError.dataError {
    print("Data corruption detected")
} catch ZLibError.memoryError {
    print("Memory allocation failed")
} catch ZLibError.streamError {
    print("Stream processing error")
} catch {
    print("Unknown error: \(error)")
}
```

### Error Recovery Strategies

Implement recovery strategies for different error types:

```swift
func compressWithRetry(input: String, output: String, maxRetries: Int = 3) throws {
    var lastError: ZLibError?

    for attempt in 1...maxRetries {
        do {
            let compressor = FileChunkedCompressor()
            try compressor.compressFile(at: input, to: output)
            return  // Success
        } catch let error as ZLibError {
            lastError = error

            switch error {
            case .memoryError:
                // Try with lower memory usage
                let lowMemoryCompressor = FileChunkedCompressor(
                    level: .default,
                    chunkSize: 16 * 1024
                )
                try lowMemoryCompressor.compressFile(at: input, to: output)
                return
            case .dataError:
                // Data corruption, cannot recover
                throw error
            default:
                // Other errors, retry
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 1.0)  // Wait before retry
                    continue
                }
            }
        }
    }

    throw lastError ?? ZLibError.unknownError(-1)
}
```

## Performance Optimization

### Compression Strategy Selection

Choose the right compression strategy for your data type:

```swift
// Text data - use default strategy
let textCompressor = ZLib.stream()
    .compression(level: .best, strategy: .default)
    .buildCompressor()

// Image data - use filtered strategy
let imageCompressor = ZLib.stream()
    .compression(level: .best, strategy: .filtered)
    .buildCompressor()

// Pre-filtered data - use huffman strategy
let filteredCompressor = ZLib.stream()
    .compression(level: .best, strategy: .huffman)
    .buildCompressor()

// Data with runs - use RLE strategy
let runCompressor = ZLib.stream()
    .compression(level: .best, strategy: .rle)
    .buildCompressor()

// Small data - use fixed strategy
let smallDataCompressor = ZLib.stream()
    .compression(level: .best, strategy: .fixed)
    .buildCompressor()
```

### Window Bits Optimization

Optimize window bits for your specific format requirements:

```swift
// Standard zlib format
let zlibCompressor = ZLib.stream()
    .compression(level: .best)
    .windowBits(.default)  // 32KB window
    .buildCompressor()

// Gzip format
let gzipCompressor = ZLib.stream()
    .compression(level: .best)
    .windowBits(.gzip)  // 32KB window with gzip header
    .buildCompressor()

// Raw deflate format
let rawCompressor = ZLib.stream()
    .compression(level: .best)
    .windowBits(.raw)  // No header/trailer
    .buildCompressor()

// Custom window size
let customCompressor = ZLib.stream()
    .compression(level: .best)
    .windowBits(.custom(12))  // 4KB window
    .buildCompressor()
```

## Integration Examples

### Combine Integration

Integrate with Combine for reactive programming:

```swift
import Combine

class CompressionService {
    private var cancellables = Set<AnyCancellable>()

    func compressWithProgress(input: String, output: String) -> AnyPublisher<Double, ZLibError> {
        return Future { promise in
            let compressor = FileChunkedCompressor()

            do {
                try compressor.compressFile(
                    at: input,
                    to: output,
                    progress: { processed, total in
                        if total > 0 {
                            let progress = Double(processed) / Double(total)
                            promise(.success(progress))
                        }
                    }
                )
                promise(.success(1.0))
            } catch {
                promise(.failure(error as! ZLibError))
            }
        }
        .eraseToAnyPublisher()
    }
}

// Usage
let service = CompressionService()
service.compressWithProgress(input: "input.txt", output: "output.gz")
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Compression failed: \(error)")
            }
        },
        receiveValue: { progress in
            print("Progress: \(Int(progress * 100))%")
        }
    )
    .store(in: &cancellables)
```

### Async/Await Integration

Use with modern Swift concurrency:

```swift
@MainActor
class CompressionViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var isCompressing = false

    func compressFile(input: String, output: String) async throws {
        isCompressing = true
        progress = 0

        let compressor = FileChunkedCompressor()

        try await withCheckedThrowingContinuation { continuation in
            do {
                try compressor.compressFile(
                    at: input,
                    to: output,
                    progress: { processed, total in
                        Task { @MainActor in
                            if total > 0 {
                                self.progress = Double(processed) / Double(total)
                            }
                        }
                    }
                )
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        isCompressing = false
        progress = 1.0
    }
}
```

This advanced features guide covers the most powerful capabilities of SwiftZlib, enabling you to build efficient, scalable compression solutions for your applications.

#### Chunked File Operations and Cancellation

Both `FileChunkedCompressor` and `FileChunkedDecompressor` now support cancellation when using their streaming APIs. If you cancel the consuming task of an `AsyncThrowingStream`, the operation will stop as soon as possible and release resources. This is ideal for user-driven cancellation in UI or server environments.

```swift
let stream = compressor.compressFileProgressStream(from: ..., to: ...)
let task = Task {
    for try await progress in stream {
        // handle progress
    }
}
// To cancel:
task.cancel()
```
