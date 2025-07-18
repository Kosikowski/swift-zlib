[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKosikowski%2Fswift-zlib%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Kosikowski/swift-zlib)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKosikowski%2Fswift-zlib%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Kosikowski/swift-zlib)
[![GitHub license](https://badgen.net/github/license/Naereen/Strapdown.js)](https://github.com/Naereen/StrapDown.js/blob/master/LICENSE)

# SwiftZlib

A comprehensive Swift library for zlib compression and decompression, providing both simple APIs and advanced features for modern Swift applications.

## Features

- **Simple APIs**: Easy-to-use compression and decompression for Data and String
- **Streaming Support**: Process large data efficiently with streaming APIs
- **File Operations**: Direct file compression and decompression with progress reporting
- **Simple File Operations**: High-performance, non-cancellable file operations using GzipFile
- **Chunked Processing**: Memory-efficient chunked file operations for large files
- **Fluent Builder Pattern**: Chainable configuration for advanced use cases
- **Enhanced Decompressors**: Specialized decompressors with custom callbacks
- **Progress Stream APIs**: Real-time progress reporting for all operations
- **Async/Await Support**: Full modern Swift concurrency support
- **Combine Integration**: Reactive programming with Combine publishers
- **Cross-Platform**: Support for iOS, macOS, tvOS, watchOS, Linux, and Windows
- **Memory Efficient**: Configurable memory usage and chunked processing
- **Comprehensive Error Handling**: Detailed error types and recovery strategies

## Quick Start

### Basic Compression

```swift
import SwiftZlib

// Compress data
let data = "Hello, World!".data(using: .utf8)!
let compressed = try data.compressed(level: .best)

// Decompress data
let decompressed = try compressed.decompressed()
```

### File Operations

#### Chunked File Operations (Cancellable)

```swift
// Compress a file with progress
let compressor = FileChunkedCompressor()
try compressor.compressFile(
    at: "input.txt",
    to: "output.gz",
    progress: { processed, total in
        let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
        print("Progress: \(percentage)%")
    }
)

// Decompress a file
let decompressor = FileChunkedDecompressor()
try decompressor.decompressFile(
    at: "output.gz",
    to: "decompressed.txt"
)
```

#### Simple File Operations (Non-Cancellable, High Performance)

```swift
// Simple compression using GzipFile for optimal performance
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")

// Simple decompression
try ZLib.decompressFileSimple(from: "output.gz", to: "decompressed.txt")

// With progress tracking
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz") { processed, total in
    print("Progress: \(processed)/\(total)")
}

// Async versions
try await ZLib.compressFileSimpleAsync(from: "input.txt", to: "output.gz")
try await ZLib.decompressFileSimpleAsync(from: "output.gz", to: "decompressed.txt")
```

### Fluent Builder Pattern

```swift
// Create a compressor with fluent configuration
let compressor = ZLib.stream()
    .compression(level: .best)
    .strategy(.huffman)
    .windowBits(.gzip)
    .memoryLevel(.maximum)
    .chunkSize(128 * 1024)
    .buildCompressor()

// Use the configured compressor
let compressed = try compressor.compress(inputData)
let final = try compressor.finish()
```

### Async Operations

```swift
// Async compression
let asyncCompressor = ZLib.asyncStream()
    .compression(level: .best)
    .buildCompressor()

let compressed = try await asyncCompressor.compress(inputData)
let final = try await asyncCompressor.finish()
```

### Enhanced Decompressors

```swift
// Enhanced decompressor with custom callbacks
let decompressor = EnhancedInflateBackDecompressor()

try decompressor.processWithCallbacks(
    input: compressedData,
    inputCallback: { chunk in
        // Custom input processing
        return chunk.reversed()
    },
    outputCallback: { output in
        // Custom output processing
        print("Processed: \(output.count) bytes")
    }
)
```

## Installation

### Swift Package Manager

Add SwiftZlib to your project in Xcode:

1. File → Add Package Dependencies
2. Enter: `https://github.com/your-username/swift-zlib`
3. Select the package and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/swift-zlib", from: "1.0.0")
]
```

### iOS Compatibility

**✅ SwiftZlib works perfectly in iOS projects!**

The package is fully compatible with iOS and uses the system zlib library for optimal performance. While iOS automation is disabled in CI due to cross-compilation complexity, the package works correctly in real iOS projects because:

- **Native iOS toolchain**: iOS projects use the iOS SDK directly
- **System zlib integration**: Uses iOS's built-in zlib library
- **No cross-compilation issues**: Built specifically for iOS, not cross-compiled from macOS

For detailed information about iOS compatibility and why CI automation is disabled, see [Windows Build Issues](doc/WINDOWS_BUILD_ISSUES.md#ios-cross-compilation-issues).

## Documentation

### 📚 Complete Documentation

- **[API Reference](doc/API_REFERENCE.md)**: Comprehensive reference for all public APIs
- **[Advanced Features](doc/ADVANCED_FEATURES.md)**: Advanced usage patterns and techniques
- **[API Coverage](doc/API_COVERAGE.md)**: Complete overview of all available APIs
- **[Streaming Guide](doc/STREAMING.md)**: Streaming and chunked processing
- **[Error Handling](doc/ERROR_HANDLING.md)**: Error handling and recovery strategies
- **[Testing Guide](doc/TESTING.md)**: Testing and validation approaches
- **[Windows Build Issues](doc/WINDOWS_BUILD_ISSUES.md)**: Windows-specific build guidance
- **[Windows Testing](doc/WINDOWS_TESTING.md)**: Windows testing procedures
- **[CLI Tool](doc/CLI.md)**: Command-line interface documentation

### 🚀 Key Features Documentation

- **Fluent Builder APIs**: Chainable configuration for streams and compressors
- **Chunked File Operations**: Memory-efficient processing of large files
- **Simple File Operations**: High-performance, non-cancellable file operations
- **Enhanced Decompressors**: Specialized decompressors with custom callbacks
- **Progress Stream APIs**: Real-time progress reporting for all operations
- **Async/Await Integration**: Full modern Swift concurrency support
- **Combine Integration**: Reactive programming with Combine publishers
- **Cross-Platform Support**: iOS, macOS, tvOS, watchOS, Linux, and Windows

## Advanced Usage

### Memory-Efficient Chunked Processing

```swift
// Process large files with constant memory usage
let compressor = FileChunkedCompressor(
    level: .best,
    chunkSize: 64 * 1024  // 64KB chunks
)

try compressor.compressFile(
    at: "1gb-file.txt",
    to: "compressed.gz"
)
```

### Progress Reporting with UI

```swift
// SwiftUI progress integration
struct CompressionView: View {
    @State private var progress: Double = 0

    var body: some View {
        VStack {
            ProgressView(value: progress)
            Text("\(Int(progress * 100))%")
        }
        .onAppear {
            compressFile()
        }
    }

    private func compressFile() {
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
    }
}
```

### Combine Integration

```swift
import Combine

// Progress publisher
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

### Error Recovery

```swift
func compressWithRetry(input: String, output: String, maxRetries: Int = 3) throws {
    for attempt in 1...maxRetries {
        do {
            let compressor = FileChunkedCompressor()
            try compressor.compressFile(at: input, to: output)
            return  // Success
        } catch ZLibError.memoryError {
            // Try with lower memory usage
            let lowMemoryCompressor = FileChunkedCompressor(
                level: .default,
                chunkSize: 16 * 1024
            )
            try lowMemoryCompressor.compressFile(at: input, to: output)
            return
        } catch {
            if attempt < maxRetries {
                Thread.sleep(forTimeInterval: 1.0)
                continue
            }
            throw error
        }
    }
}
```

## Performance

SwiftZlib is optimized for performance with:

- **Configurable Memory Usage**: Choose memory levels based on your environment
- **Chunked Processing**: Process large files with constant memory usage
- **Strategy Selection**: Optimize compression for different data types
- **Window Size Tuning**: Configure window sizes for your specific use case
- **Async Processing**: Non-blocking operations for responsive applications

## Platform Support

- **iOS 13.0+** / **macOS 10.15+** / **tvOS 13.0+** / **watchOS 6.0+**
- **Linux** (Ubuntu 18.04+, CentOS 7+)
- **Windows** (Windows 10+ with Visual Studio 2019+)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Run `swift package resolve`
3. Run `swift test` to verify everything works
4. Make your changes and add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of the excellent zlib library
- Inspired by modern Swift patterns and best practices
- Thanks to all contributors and the Swift community
