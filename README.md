# SwiftZlib

A Swift wrapper for the ZLib compression library, providing both high-level convenience methods and low-level stream-based compression for macOS and Linux.

## Features

- **High-level API**: Simple compression/decompression with one-line calls
- **Stream-based API**: For large files or streaming scenarios
- **Swift-native error handling**: Proper Swift errors with descriptive messages
- **Memory efficient**: Handles large datasets without loading everything into memory
- **Cross-platform**: Works on macOS and Linux
- **Convenience extensions**: Direct methods on `Data` and `String` types

## Installation

### Swift Package Manager

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-zlib.git", from: "1.0.0")
]
```

### System Requirements

- **macOS**: ZLib is included with the system
- **Linux**: Install `zlib1g-dev` package:
  ```bash
  sudo apt-get install zlib1g-dev
  ```

## Quick Start

```swift
import SwiftZlib

// Basic compression
let originalData = "Hello, World!".data(using: .utf8)!
let compressedData = try ZLib.compress(originalData)
let decompressedData = try ZLib.decompress(compressedData)

// String compression
let originalString = "This is a test string"
let compressedData = try originalString.compressed()
let decompressedString = try String.decompressed(from: compressedData)
```

## API Reference

### High-Level API

#### `ZLib.compress(_:level:)`
Compress data with the specified compression level.

```swift
let compressedData = try ZLib.compress(originalData, level: .bestCompression)
```

**Parameters:**
- `data`: The data to compress
- `level`: Compression level (default: `.defaultCompression`)

**Returns:** Compressed data

#### `ZLib.decompress(_:)`
Decompress previously compressed data.

```swift
let decompressedData = try ZLib.decompress(compressedData)
```

**Parameters:**
- `data`: The compressed data to decompress

**Returns:** Decompressed data

### Compression Levels

- `.noCompression`: No compression (fastest)
- `.bestSpeed`: Best speed compression
- `.defaultCompression`: Default compression level
- `.bestCompression`: Best compression (slowest)

### Stream-Based API

For large files or streaming scenarios, use the `Compressor` and `Decompressor` classes:

```swift
// Compression
let compressor = Compressor()
try compressor.initialize(level: .bestCompression)

let chunk1 = try compressor.compress(data1)
let chunk2 = try compressor.compress(data2)
let finalChunk = try compressor.finish()

// Decompression
let decompressor = Decompressor()
try decompressor.initialize()

let decompressed1 = try decompressor.decompress(compressedChunk1)
let decompressed2 = try decompressor.decompress(compressedChunk2)
let finalDecompressed = try decompressor.finish()
```

### Convenience Extensions

#### Data Extensions

```swift
let originalData = "Test data".data(using: .utf8)!
let compressedData = try originalData.compressed(level: .bestCompression)
let decompressedData = try compressedData.decompressed()
```

#### String Extensions

```swift
let originalString = "Test string"
let compressedData = try originalString.compressed()
let decompressedString = try String.decompressed(from: compressedData)
```

### Error Handling

The library provides comprehensive error handling with `ZLibError`:

```swift
do {
    let compressedData = try ZLib.compress(originalData)
    let decompressedData = try ZLib.decompress(compressedData)
} catch ZLibError.compressionFailed(let code) {
    print("Compression failed with code: \(code)")
} catch ZLibError.decompressionFailed(let code) {
    print("Decompression failed with code: \(code)")
} catch {
    print("Other error: \(error)")
}
```

### Error Types

- `.compressionFailed(Int32)`: Compression operation failed
- `.decompressionFailed(Int32)`: Decompression operation failed
- `.invalidData`: Invalid data provided
- `.memoryError`: Memory allocation error
- `.streamError(Int32)`: Stream operation failed
- `.versionMismatch`: ZLib version mismatch

## Examples

### Compressing a Large File

```swift
import Foundation
import SwiftZlib

func compressFile(at path: String) throws -> Data {
    let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
    return try ZLib.compress(fileData, level: .bestCompression)
}

func decompressFile(_ compressedData: Data) throws -> Data {
    return try ZLib.decompress(compressedData)
}
```

### Streaming Compression

```swift
func compressLargeFile(at path: String) throws -> Data {
    let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
    defer { try? fileHandle.close() }
    
    let compressor = Compressor()
    try compressor.initialize(level: .bestCompression)
    
    var compressedData = Data()
    let chunkSize = 64 * 1024 // 64KB chunks
    
    while let chunk = try fileHandle.read(upToCount: chunkSize) {
        let compressedChunk = try compressor.compress(chunk)
        compressedData.append(compressedChunk)
    }
    
    let finalChunk = try compressor.finish()
    compressedData.append(finalChunk)
    
    return compressedData
}
```

### Network Compression

```swift
func sendCompressedData(_ data: Data, over connection: NetworkConnection) throws {
    let compressedData = try data.compressed(level: .bestSpeed)
    try connection.send(compressedData)
}

func receiveCompressedData(from connection: NetworkConnection) throws -> Data {
    let compressedData = try connection.receive()
    return try compressedData.decompressed()
}
```

## Performance Considerations

- **Compression Level**: Use `.bestSpeed` for real-time applications, `.bestCompression` for storage
- **Memory Usage**: For large files, use the stream-based API to avoid loading everything into memory
- **Chunk Size**: When streaming, use 1-64KB chunks for optimal performance

## Testing

Run the test suite:

```bash
swift test
```

The test suite covers:
- Basic compression/decompression
- All compression levels
- Stream-based operations
- Error handling
- Edge cases (empty data, single bytes, binary data)
- Large dataset performance

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## Dependencies

- **ZLib**: System compression library
- **Swift**: 5.10 or later
- **Platforms**: macOS 12.0+, Linux 