# SwiftZlib

A comprehensive Swift library for zlib compression and decompression with support for streaming, async operations, Combine publishers, and file operations.

## Features

- **Core Compression/Decompression**: In-memory data compression and decompression
- **Streaming Support**: Process large data streams efficiently
- **Async/Await**: Modern Swift concurrency support
- **Combine Integration**: Reactive programming with publishers
- **File Operations**: Direct file compression and decompression
- **Progress Reporting**: Real-time progress updates for long operations
- **Gzip Support**: Full gzip header and footer handling
- **Dictionary Compression**: Custom dictionary support
- **Error Handling**: Comprehensive error types and recovery
- **Performance Optimized**: Multiple compression levels and strategies

## Installation

### Swift Package Manager

Add SwiftZlib to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/swift-zlib.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/your-username/swift-zlib.git`
3. Select version and add to your target

### Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.5+
- Xcode 13.0+

## Quick Start

### Basic Compression

```swift
import SwiftZlib

// Compress data
let data = "Hello, World!".data(using: .utf8)!
let compressed = try data.compress()

// Decompress data
let decompressed = try compressed.decompress()
```

### File Operations

```swift
// Compress a file
try await ZLib.compressFile(
    from: "input.txt",
    to: "output.gz",
    level: .best,
    progress: { progress in
        print("Compression: \(Int(progress * 100))%")
    }
)

// Decompress a file
try await ZLib.decompressFile(
    from: "output.gz",
    to: "decompressed.txt"
)
```

### Combine Integration

```swift
import Combine

// Compress with Combine
ZLib.compressPublisher(data: data)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { compressed in
            print("Compressed size: \(compressed.count)")
        }
    )
    .store(in: &cancellables)
```

## API Reference

### Core Methods

#### Data Compression
- `Data.compress(level:strategy:)` - Compress data with specified level and strategy
- `Data.decompress()` - Decompress data
- `Data.compressAsync(level:strategy:)` - Async compression
- `Data.compressPublisher(level:strategy:)` - Combine publisher for compression

#### String Compression
- `String.compress(level:strategy:)` - Compress string data
- `String.decompress()` - Decompress string data
- `String.compressAsync(level:strategy:)` - Async string compression
- `String.compressPublisher(level:strategy:)` - Combine publisher for string compression

#### File Operations
- `ZLib.compressFile(from:to:level:progress:)` - Compress file with progress
- `ZLib.decompressFile(from:to:progress:)` - Decompress file with progress
- `ZLib.compressFileAsync(from:to:level:progress:)` - Async file compression
- `ZLib.decompressFileAsync(from:to:progress:)` - Async file decompression
- `ZLib.compressFilePublisher(from:to:level:)` - Combine publisher for file compression
- `ZLib.decompressFilePublisher(from:to:)` - Combine publisher for file decompression

### Compression Levels

- `.noCompression` - No compression (fastest)
- `.bestSpeed` - Fast compression
- `.best` - Best compression ratio
- `.default` - Default compression (level 6)

### Compression Strategies

- `.default` - Default strategy
- `.filtered` - Filtered data
- `.huffman` - Huffman-only
- `.rle` - Run-length encoding
- `.fixed` - Fixed Huffman codes

## Examples

### Streaming Large Files

```swift
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    compressionLevel: .best,
    compressionStrategy: .default
)

let stream = ZLibStream(config: config)
try stream.compressFile(from: "large-input.txt", to: "compressed.gz")
```

### Dictionary Compression

```swift
let dictionary = "common prefix".data(using: .utf8)!
let compressed = try data.compress(
    level: .best,
    dictionary: dictionary
)
```

### Error Handling

```swift
do {
    let compressed = try data.compress()
} catch ZLibError.invalidData {
    print("Invalid input data")
} catch ZLibError.insufficientMemory {
    print("Not enough memory")
} catch {
    print("Other error: \(error)")
}
```

### Progress Monitoring

```swift
try await ZLib.compressFile(
    from: "input.txt",
    to: "output.gz",
    progress: { progress in
        DispatchQueue.main.async {
            progressView.progress = Float(progress)
        }
    }
)
```

## Troubleshooting

### Common Issues

**Build Errors**
- Ensure you're using Swift 5.5+ and Xcode 13.0+
- Check that the package is properly added to your target
- Clean build folder (Cmd+Shift+K) and rebuild

**Runtime Errors**
- `ZLibError.invalidData`: Input data is corrupted or not compressed
- `ZLibError.insufficientMemory`: System memory is insufficient
- `ZLibError.streamError`: Internal zlib stream error

**Performance Issues**
- Use `.bestSpeed` for faster compression
- Increase chunk size for streaming operations
- Consider using async operations for large files

**File Operation Errors**
- Ensure source file exists and is readable
- Check destination directory permissions
- Verify sufficient disk space

### Getting Help

1. Check the [documentation](doc/) for detailed guides
2. Review [error handling guide](doc/ERROR_HANDLING.md)
3. See [testing guide](doc/TESTING.md) for debugging
4. Open an issue with reproduction steps

## Command Line Tool

SwiftZlib includes a comprehensive command-line tool for compression tasks:

### Installation

```bash
swift build -c release
.build/release/swift-zlib
```

### Usage

```bash
# Basic compression
swift-zlib compress input.txt output.gz

# Decompression
swift-zlib decompress output.gz decompressed.txt

# Benchmark different levels
swift-zlib benchmark input.txt

# Large file with progress
swift-zlib large input.txt output.gz

# Memory level info
swift-zlib memory
```

See [CLI README](CLI_README.md) for complete documentation.

## Testing

Run the test suite:

```bash
swift test
```

Quick verification:

```bash
swift test --filter CoreTests
swift test --filter ExtensionsTests
swift test --filter FileOperationsTests
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and [ARCHITECTURE.md](ARCHITECTURE.md) for technical details.

## Technical Documentation

For detailed technical information about zlib API coverage and C function mappings, see [API Coverage](doc/API_COVERAGE.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.