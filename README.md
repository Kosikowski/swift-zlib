# SwiftZlib

A comprehensive Swift wrapper for the ZLib compression library, providing both high-level convenience methods and low-level stream-based compression for macOS and Linux. This wrapper covers **~98% of the zlib API** with modern, Swifty interfaces.

## Features

- **Complete zlib API coverage** (~98% of all zlib functions)
- **High-level API**: Simple compression/decompression with one-line calls
- **Stream-based API**: For large files or streaming scenarios
- **Advanced InflateBack support**: True C callback system with Swift bridging
- **Gzip file operations**: Complete gzip file reading/writing support
- **Header manipulation**: Full gzip header creation and parsing
- **Swift-native error handling**: Proper Swift errors with descriptive messages
- **Memory efficient**: Handles large datasets without loading everything into memory
- **Cross-platform**: Works on macOS and Linux
- **Convenience extensions**: Direct methods on `Data` and `String` types
- **Performance optimization**: Built-in utilities for optimal compression settings
- **Verbose logging system**: Comprehensive debugging and performance monitoring

## API Coverage

### ✅ **Core Compression/Decompression (100%)**
- `compress2()` → `ZLib.compress()`
- `uncompress()` → `ZLib.decompress()`
- `uncompress2()` → `ZLib.partialDecompress()`

### ✅ **Stream-Based Operations (100%)**
- `deflateInit()` → `Compressor.initialize()`
- `deflateInit2()` → `Compressor.initializeAdvanced()`
- `deflate()` → `Compressor.compress()`
- `deflateEnd()` → `Compressor` deinit
- `deflateReset()` → `Compressor.reset()`
- `deflateReset2()` → `Compressor.resetWithWindowBits()`
- `deflateCopy()` → `Compressor.copy()`
- `deflatePrime()` → `Compressor.prime()`
- `deflateParams()` → `Compressor.setParameters()`
- `deflateSetDictionary()` → `Compressor.setDictionary()`
- `deflateGetDictionary()` → `Compressor.getDictionary()`
- `deflatePending()` → `Compressor.getPending()`
- `deflateBound()` → `Compressor.getBound()`
- `deflateTune()` → `Compressor.tune()`

### ✅ **Decompression Stream Operations (100%)**
- `inflateInit()` → `Decompressor.initialize()`
- `inflateInit2()` → `Decompressor.initializeAdvanced()`
- `inflate()` → `Decompressor.decompress()`
- `inflateEnd()` → `Decompressor` deinit
- `inflateReset()` → `Decompressor.reset()`
- `inflateReset2()` → `Decompressor.resetWithWindowBits()`
- `inflateCopy()` → `Decompressor.copy()`
- `inflatePrime()` → `Decompressor.prime()`
- `inflateSetDictionary()` → `Decompressor.setDictionary()`
- `inflateGetDictionary()` → `Decompressor.getDictionary()`
- `inflateSync()` → `Decompressor.sync()`
- `inflateSyncPoint()` → `Decompressor.isSyncPoint()`
- `inflateMark()` → `Decompressor.getMark()`
- `inflateCodesUsed()` → `Decompressor.getCodesUsed()`
- `inflatePending()` → `Decompressor.getPending()`

### ✅ **Advanced InflateBack API (100%)**
- `inflateBackInit()` → `InflateBackDecompressor.initialize()`
- `inflateBack()` → `InflateBackDecompressor.processWithCallbacks()`
- `inflateBackEnd()` → `InflateBackDecompressor` deinit
- Custom window buffer management
- Swift-native callback system
- Memory-safe implementation

### ✅ **Gzip File Operations (100%)**
- `gzopen()` → `GzipFile.init()`
- `gzclose()` → `GzipFile.close()`
- `gzread()` → `GzipFile.readData()`
- `gzwrite()` → `GzipFile.writeData()`
- `gzseek()` → `GzipFile.seek()`
- `gztell()` → `GzipFile.tell()`
- `gzflush()` → `GzipFile.flush()`
- `gzrewind()` → `GzipFile.rewind()`
- `gzeof()` → `GzipFile.eof()`
- `gzsetparams()` → `GzipFile.setParams()`
- `gzerror()` → `GzipFile.errorMessage()`
- `gzprintf()` → `GzipFile.printfSimple()`
- `gzgets()` → `GzipFile.gets()`
- `gzputc()` → `GzipFile.putc()`
- `gzgetc()` → `GzipFile.getc()`
- `gzungetc()` → `GzipFile.ungetc()`
- `gzclearerr()` → `GzipFile.clearError()`

### ✅ **Header Manipulation (100%)**
- `deflateSetHeader()` → `Compressor.setGzipHeader()`
- `inflateGetHeader()` → `Decompressor.getGzipHeader()`
- `GzipHeader` struct for Swifty header representation

### ✅ **Checksum Functions (100%)**
- `adler32()` → `ZLib.adler32()`
- `crc32()` → `ZLib.crc32()`
- `adler32_combine()` → `ZLib.adler32Combine()`
- `crc32_combine()` → `ZLib.crc32Combine()`

### ✅ **Utility Functions (100%)**
- `compressBound()` → `ZLib.estimateCompressedSize()`
- `zlibVersion()` → `ZLib.version`
- `zError()` → `ZLib.getErrorMessage()`
- `zlibCompileFlags()` → `ZLib.compileFlags`

### ✅ **Advanced Features (100%)**
- Error handling with detailed error codes
- Performance optimization utilities
- Memory estimation functions
- Parameter validation
- Stream introspection and statistics
- Convenience extensions for `Data` and `String`
- Advanced streaming with `StreamingDecompressor`

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

## Verbose Logging

SwiftZlib includes a comprehensive verbose logging system for debugging and performance monitoring. The library provides two targets:

### SwiftZlib (Production)
- Minimal logging overhead
- Optimized for performance
- Verbose logging disabled by default

### SwiftZlibVerbose (Development)
- Full verbose logging enabled
- Detailed stream state tracking
- Performance timing information
- Memory allocation logging
- Error detailed logging

### Usage

```swift
import SwiftZlib

// Enable verbose logging (only available in SwiftZlibVerbose target)
ZLibVerboseConfig.enableAll()

// Or configure specific logging options
ZLibVerboseConfig.logStreamState = true
ZLibVerboseConfig.logProgress = true
ZLibVerboseConfig.logTiming = true

// Custom log handler
ZLibVerboseConfig.logHandler = { level, message in
    print("[\(level)] \(message)")
}

// Perform operations with verbose logging
let compressedData = try ZLib.compress(originalData)
```

### Log Levels

- **DEBUG**: Detailed internal state information
- **INFO**: General operation progress
- **WARNING**: Non-critical issues
- **ERROR**: Error conditions

### Log Categories

- **Stream State**: Detailed z_stream state tracking
- **Progress**: Compression/decompression progress
- **Memory**: Memory allocation and usage
- **Timing**: Performance timing information
- **Errors**: Detailed error information

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

// Advanced streaming
let compressor = Compressor()
try compressor.initialize(level: .bestCompression)
let compressed = try compressor.compress(data) + compressor.finish()
```

## API Overview

### Simple API
For basic compression and decompression:

```swift
// Simple compression
let compressed = try ZLib.compress(data)
let decompressed = try ZLib.decompress(compressed)

// With options
let compressed = try ZLib.compress(data, options: .init(level: .bestCompression))
let decompressed = try ZLib.decompress(compressed, options: .init())

// Dictionary compression (Simple API)
let dictionary = "common prefix".data(using: .utf8)!
let compressionOptions = CompressionOptions(
    format: .raw,  // Required for dictionary support
    level: .defaultCompression,
    dictionary: dictionary
)
let compressedWithDict = try ZLib.compress(data, options: compressionOptions)

let decompressionOptions = DecompressionOptions(
    format: .raw,  // Must match compression format
    dictionary: dictionary
)
let decompressed = try ZLib.decompress(compressedWithDict, options: decompressionOptions)
```

### Advanced API
For fine-grained control:

```swift
// Compression with advanced options
let compressor = Compressor()
try compressor.initializeAdvanced(
    level: .bestCompression,
    format: .gzip,
    memoryLevel: 8,
    strategy: .defaultStrategy
)
let compressed = try compressor.compress(data, flush: .finish)

// Decompression with advanced options
let decompressor = Decompressor()
try decompressor.initializeAdvanced(windowBits: .gzip)
let decompressed = try decompressor.decompress(compressed)
```

### Unified Streaming API
For ergonomic streaming with builder pattern:

```swift
// Builder pattern for compression
let compressionStream = ZLib.stream()
    .compress()
    .format(.zlib)
    .level(.bestCompression)
    .bufferSize(1024)
    .build()

try compressionStream.initialize()
let compressed = try compressionStream.process(data, flush: .finish)

// Builder pattern for decompression
let decompressionStream = ZLib.stream()
    .decompress()
    .format(.zlib)
    .bufferSize(1024)
    .build()

try decompressionStream.initialize()
let decompressed = try decompressionStream.process(compressed)

// Direct stream creation
let directCompressStream = ZLib.compressionStream()
let directDecompressStream = ZLib.decompressionStream()

// Streaming with chunks
let chunkStream = ZLib.stream().compress().format(.gzip).build()
try chunkStream.initialize()

var chunkedCompressed = Data()
for chunk in dataChunks {
    let compressedChunk = try chunkStream.process(chunk, flush: .noFlush)
    chunkedCompressed.append(compressedChunk)
}
let finalChunk = try chunkStream.process(Data(), flush: .finish)
chunkedCompressed.append(finalChunk)
```

### Configuration-Based API
For structured configuration:

```swift
// Compression configuration
let compressionConfig = CompressionOptions(
    level: .bestCompression,
    format: .gzip,
    memoryLevel: 8,
    strategy: .defaultStrategy,
    dictionary: dictionaryData
)

let compressed = try ZLib.compress(data, options: compressionConfig)

// Decompression configuration
let decompressionConfig = DecompressionOptions(
    format: .gzip,
    dictionary: dictionaryData
)

let decompressed = try ZLib.decompress(compressed, options: decompressionConfig)
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

#### `ZLib.compress(_:options:)`
Compress data with advanced options including dictionary support.

```swift
let dictionary = "common prefix".data(using: .utf8)!
let options = CompressionOptions(
    format: .raw,  // Required for dictionary support
    level: .defaultCompression,
    dictionary: dictionary
)
let compressedData = try ZLib.compress(originalData, options: options)
```

**Parameters:**
- `data`: The data to compress
- `options`: Compression configuration including dictionary

**Returns:** Compressed data

#### `ZLib.decompress(_:)`
Decompress previously compressed data.

```swift
let decompressedData = try ZLib.decompress(compressedData)
```

**Returns:** Decompressed data

#### `ZLib.decompress(_:options:)`
Decompress data with advanced options including dictionary support.

```swift
let dictionary = "common prefix".data(using: .utf8)!
let options = DecompressionOptions(
    format: .raw,  // Must match compression format
    dictionary: dictionary
)
let decompressedData = try ZLib.decompress(compressedData, options: options)
```

**Parameters:**
- `data`: The compressed data to decompress
- `options`: Decompression configuration including dictionary

**Returns:** Decompressed data

#### `ZLib.partialDecompress(_:maxOutputSize:)`
Partially decompress data with size limits.

```swift
let (decompressed, inputConsumed, outputWritten) = try ZLib.partialDecompress(data, maxOutputSize: 4096)
```

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

### Object Lifecycle and Reuse

**Important:** After completing a compression or decompression operation (i.e., after calling `.finish()` or completing a full decompression), you must call `.reset()` before reusing the same instance for a new operation.

```swift
// ✅ Correct: Reset before reuse
let compressor = Compressor()
try compressor.initialize(level: .bestCompression)

// First operation
let compressed1 = try compressor.compress(data1, flush: .finish)

// Reset before reuse
try compressor.reset()

// Second operation
let compressed2 = try compressor.compress(data2, flush: .finish)

// ❌ Incorrect: Reusing without reset (will hang or fail)
let compressor = Compressor()
try compressor.initialize(level: .bestCompression)

let compressed1 = try compressor.compress(data1, flush: .finish)
// Missing: try compressor.reset()
let compressed2 = try compressor.compress(data2, flush: .finish) // This will hang!
```

**When to call `.reset()`:**
- After completing a compression with `.finish()` flush
- After completing a full decompression operation
- Before starting a new compression/decompression cycle with the same instance

**Alternative: Use new instances**
If you don't want to manage reset calls, create new instances for each operation:

```swift
// Alternative approach: Use new instances
let compressor1 = Compressor()
try compressor1.initialize(level: .bestCompression)
let compressed1 = try compressor1.compress(data1, flush: .finish)

let compressor2 = Compressor()
try compressor2.initialize(level: .bestCompression)
let compressed2 = try compressor2.compress(data2, flush: .finish)
```

### Advanced InflateBack API

For advanced streaming with custom callbacks:

```swift
let inflateBack = InflateBackDecompressor()
try inflateBack.initialize()

try inflateBack.processWithCallbacks(
    inputProvider: {
        // Return input data chunks
        return someData
    },
    outputHandler: { outputData in
        // Process decompressed data
        processOutput(outputData)
        return true // Continue processing
    }
)
```

### Compressor Reset Semantics

**Note:** `Compressor.reset()` (maps to zlib's `deflateReset`) only resets the internal state for continued use with the same parameters. It does **not** re-emit headers or fully reinitialize the stream. If you need to start a new, unrelated compression (with a new header and fresh state), you must create a new `Compressor` instance or call `initialize` again. See the [zlib manual on deflateReset](https://zlib.net/manual.html#deflateReset) for details.

Example:

```swift
// Correct: Use a new Compressor for a new logical stream
let compressor1 = Compressor()
try compressor1.initialize(level: .defaultCompression)
let compressed1 = try compressor1.compress(data1, flush: .finish)

let compressor2 = Compressor()
try compressor2.initialize(level: .defaultCompression)
let compressed2 = try compressor2.compress(data2, flush: .finish)
```

### Compressor and Decompressor Lifecycle

#### Initialization
```swift
let compressor = Compressor()
try compressor.initialize(level: .bestCompression)
// or
try compressor.initializeAdvanced(level: .bestCompression, windowBits: .gzip)
```

#### Compression/Decompression
```swift
// Single operation
let compressed = try compressor.compress(data, flush: .finish)

// Multiple chunks
let chunk1 = try compressor.compress(data1, flush: .noFlush)
let chunk2 = try compressor.compress(data2, flush: .finish)
```

#### Reset for Reuse
```swift
// After completing an operation, reset for reuse
try compressor.reset()

// Now safe to use again
let compressed2 = try compressor.compress(newData, flush: .finish)
```

#### Cleanup
```swift
// Automatic cleanup in deinit, or manual cleanup
compressor = nil // Automatic cleanup
```

### Gzip File Operations

Complete gzip file support:

```swift
// Write gzip file
let gzipFile = try GzipFile(path: "output.gz", mode: "w")
try gzipFile.writeData(data)
try gzipFile.close()

// Read gzip file
let gzipFile = try GzipFile(path: "input.gz", mode: "r")
let data = try gzipFile.readData(count: 1024)
try gzipFile.close()
```

### Header Manipulation

Create and parse gzip headers:

```swift
// Create gzip header
var header = GzipHeader()
header.name = "example.txt"
header.comment = "Compressed with SwiftZlib"
header.time = UInt32(Date().timeIntervalSince1970)

// Use with compression
let compressor = Compressor()
try compressor.initializeAdvanced(level: .bestCompression, windowBits: .gzip)
try compressor.setGzipHeader(header)
let compressed = try compressor.compress(data) + compressor.finish()
```

### Convenience Extensions

#### Data Extensions

```swift
let originalData = "Test data".data(using: .utf8)!
let compressedData = try originalData.compressed(level: .bestCompression)
let decompressedData = try compressedData.decompressed()

// With gzip header
let header = GzipHeader()
header.name = "file.txt"
let compressedWithHeader = try originalData.compressedWithGzipHeader(level: .bestCompression, header: header)

// Checksums
let adler32 = originalData.adler32()
let crc32 = originalData.crc32()
```

#### String Extensions

```swift
let originalString = "Test string"
let compressedData = try originalString.compressed()
let decompressedString = try String.decompressed(from: compressedData)

// With gzip header
let header = GzipHeader()
header.name = "string.txt"
let compressedWithHeader = try originalString.compressedWithGzipHeader(level: .bestCompression, header: header)
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
- `.needDictionary`: Dictionary needed for decompression
- `.dataError`: Data error during operation
- `.bufferError`: Buffer error during operation

## Advanced Features

### Performance Optimization

```swift
// Get optimal parameters for data size
let (level, windowBits, memoryLevel, strategy) = ZLib.getOptimalParameters(for: dataSize)

// Estimate memory usage
let memoryUsage = ZLib.estimateMemoryUsage(windowBits: .deflate, memoryLevel: .maximum)

// Get performance profiles
let profiles = ZLib.getPerformanceProfiles(for: dataSize)
for (level, time, ratio) in profiles {
    print("Level \(level): \(time)s, ratio: \(ratio)")
}
```

### Error Recovery

```swift
// Check if error is recoverable
if ZLib.isRecoverableError(errorCode) {
    let suggestions = ZLib.getErrorRecoverySuggestions(errorCode)
    print("Recovery suggestions: \(suggestions)")
}

// Validate parameters
let warnings = ZLib.validateParameters(
    level: .bestCompression,
    windowBits: .deflate,
    memoryLevel: .maximum,
    strategy: .defaultStrategy
)
```

### Stream Statistics

```swift
let compressor = Compressor()
try compressor.initialize()

// Get compression statistics
let stats = try compressor.getStreamStats()
print("Processed: \(stats.bytesProcessed), Produced: \(stats.bytesProduced)")
print("Ratio: \(stats.compressionRatio), Active: \(stats.isActive)")
```

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

### Advanced InflateBack Usage

```swift
func processWithCustomCallbacks() throws {
    let inflateBack = InflateBackDecompressor()
    try inflateBack.initialize()
    
    var output = Data()
    
    try inflateBack.processWithCallbacks(
        inputProvider: {
            // Custom input logic
            return getNextChunk()
        },
        outputHandler: { data in
            // Custom output processing
            output.append(data)
            return output.count < maxSize
        }
    )
    
    return output
}
```

### Advanced InflateBack (C-Callback Bridged) Usage

You can use the true C-callback-based InflateBack decompressor for raw deflate streams:

```swift
let original = "Hello, InflateBackCBridged!".data(using: .utf8)!

// Compress using raw deflate (windowBits: -15)
let compressed = try ZLib.compress(original, windowBits: .raw)

// Decompress using InflateBackDecompressorCBridged
let inflater = InflateBackDecompressorCBridged(windowBits: .raw)
try inflater.initialize()
let decompressed = try inflater.processData(compressed)

print(String(data: decompressed, encoding: .utf8)!) // "Hello, InflateBackCBridged!"
```

- Note: `InflateBack` only works with raw deflate streams (`windowBits: .raw` or `-15`).
- The input must be compressed with the same windowBits.

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

### Gzip File Processing

```swift
func processGzipFile(at path: String) throws -> Data {
    let gzipFile = try GzipFile(path: path, mode: "r")
    defer { try? gzipFile.close() }
    
    var data = Data()
    let bufferSize = 4096
    
    while !gzipFile.eof() {
        let chunk = try gzipFile.readData(count: bufferSize)
        data.append(chunk)
    }
    
    return data
}

func createGzipFile(data: Data, at path: String) throws {
    let gzipFile = try GzipFile(path: path, mode: "w")
    defer { try? gzipFile.close() }
    
    try gzipFile.writeData(data)
    try gzipFile.flush()
}
```

## Usage Examples

### Basic Compression and Decompression

```swift
import SwiftZlib

// Simple compression
let originalData = "Hello, World!".data(using: .utf8)!
let compressed = try ZLib.compress(originalData)
let decompressed = try ZLib.decompress(compressed)

print("Original: \(originalData.count) bytes")
print("Compressed: \(compressed.count) bytes")
print("Decompressed: \(decompressed.count) bytes")
print("Success: \(originalData == decompressed)")
```

### Advanced Streaming with Builder Pattern

```swift
import SwiftZlib

let largeData = generateLargeData() // Your data source

// Create compression stream with builder pattern
let compressionStream = ZLib.stream()
    .compress()
    .format(.gzip)
    .level(.bestCompression)
    .bufferSize(4096)
    .build()

try compressionStream.initialize()

// Process data in chunks
var compressedData = Data()
let chunkSize = 1024

for i in stride(from: 0, to: largeData.count, by: chunkSize) {
    let end = min(i + chunkSize, largeData.count)
    let chunk = largeData.subdata(in: i..<end)
    
    let isLastChunk = (end == largeData.count)
    let flush: FlushMode = isLastChunk ? .finish : .noFlush
    
    let compressedChunk = try compressionStream.process(chunk, flush: flush)
    compressedData.append(compressedChunk)
}

// Create decompression stream
let decompressionStream = ZLib.stream()
    .decompress()
    .format(.gzip)
    .bufferSize(4096)
    .build()

try decompressionStream.initialize()

// Decompress the data
let decompressedData = try decompressionStream.process(compressedData)

print("Original: \(largeData.count) bytes")
print("Compressed: \(compressedData.count) bytes")
print("Decompressed: \(decompressedData.count) bytes")
print("Success: \(largeData == decompressedData)")
```

### Configuration-Based API

```swift
import SwiftZlib

// Create compression configuration
let compressionConfig = CompressionOptions(
    level: .bestCompression,
    format: .zlib,
    memoryLevel: 8,
    strategy: .defaultStrategy
)

// Create decompression configuration
let decompressionConfig = DecompressionOptions(
    format: .zlib
)

let data = "Compressible data that will be compressed efficiently".data(using: .utf8)!

// Compress with configuration
let compressed = try ZLib.compress(data, options: compressionConfig)

// Decompress with configuration
let decompressed = try ZLib.decompress(compressed, options: decompressionConfig)

print("Compression ratio: \(Double(compressed.count) / Double(data.count))")
```

### Dictionary-Based Compression

```swift
import SwiftZlib

// Create a dictionary for better compression of similar data
let dictionary = "common prefix data that appears frequently".data(using: .utf8)!

// Compression configuration with dictionary
let compressionConfig = CompressionOptions(
    level: .bestCompression,
    format: .zlib,
    dictionary: dictionary
)

// Decompression configuration with same dictionary
let decompressionConfig = DecompressionOptions(
    format: .zlib,
    dictionary: dictionary
)

let data = "common prefix data that appears frequently in this text".data(using: .utf8)!

let compressed = try ZLib.compress(data, options: compressionConfig)
let decompressed = try ZLib.decompress(compressed, options: decompressionConfig)

print("With dictionary: \(compressed.count) bytes")
print("Without dictionary: \(try ZLib.compress(data).count) bytes")
```

### Gzip File Operations

```swift
import SwiftZlib

// Create a gzip file
let gzipFile = try GzipFile(path: "example.txt.gz", mode: .write)
try gzipFile.setHeader(GzipHeader(
    filename: "example.txt",
    comment: "Compressed example file",
    timestamp: Date()
))

let data = "File content to compress".data(using: .utf8)!
try gzipFile.write(data)
try gzipFile.close()

// Read the gzip file
let readFile = try GzipFile(path: "example.txt.gz", mode: .read)
let header = try readFile.getHeader()
let decompressedData = try readFile.readAll()
try readFile.close()

print("Filename: \(header.filename ?? "unknown")")
print("Comment: \(header.comment ?? "none")")
print("Timestamp: \(header.timestamp ?? Date())")
print("Content: \(String(data: decompressedData, encoding: .utf8) ?? "invalid")")
```

### Error Handling

```swift
import SwiftZlib

do {
    let compressed = try ZLib.compress(data)
    let decompressed = try ZLib.decompress(compressed)
} catch ZLibError.compressionFailed(let code) {
    print("Compression failed with code: \(code)")
} catch ZLibError.decompressionFailed(let code) {
    print("Decompression failed with code: \(code)")
} catch ZLibError.streamError(let code) {
    print("Stream error with code: \(code)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Performance Monitoring

```swift
import SwiftZlib

let data = generateTestData(size: 1024 * 1024) // 1MB

// Monitor compression performance
let startTime = CFAbsoluteTimeGetCurrent()
let compressed = try ZLib.compress(data)
let compressionTime = CFAbsoluteTimeGetCurrent() - startTime

let startTime2 = CFAbsoluteTimeGetCurrent()
let decompressed = try ZLib.decompress(compressed)
let decompressionTime = CFAbsoluteTimeGetCurrent() - startTime2

print("Compression time: \(compressionTime)s")
print("Decompression time: \(decompressionTime)s")
print("Compression ratio: \(Double(compressed.count) / Double(data.count))")
print("Throughput: \(Double(data.count) / compressionTime / 1024 / 1024) MB/s")
```

### Async/Await Support

For non-blocking compression and decompression:

```swift
import SwiftZlib

// Simple async compression/decompression
let originalData = "Async compression test".data(using: .utf8)!
let compressed = try await ZLib.compressAsync(originalData)
let decompressed = try await ZLib.decompressAsync(compressed)

// Async compression with options
let compressionOptions = CompressionOptions(
    format: .gzip,
    level: .bestCompression
)
let compressedWithOptions = try await ZLib.compressAsync(originalData, options: compressionOptions)

// Async streaming compression
let asyncCompressor = AsyncCompressor(options: compressionOptions)
try await asyncCompressor.initialize()
let streamCompressed = try await asyncCompressor.compress(originalData, flush: FlushMode.finish)

// Async streaming decompression
let asyncDecompressor = AsyncDecompressor(options: DecompressionOptions(format: .gzip))
try await asyncDecompressor.initialize()
let streamDecompressed = try await asyncDecompressor.decompress(streamCompressed)

// Async unified streaming API
let asyncStream = ZLib.asyncStream()
    .compress()
    .format(.zlib)
    .level(.bestSpeed)
    .bufferSize(1024)
    .build()

try await asyncStream.initialize()
let unifiedCompressed = try await asyncStream.process(originalData, flush: FlushMode.finish)

// Async streaming with chunks
let chunkStream = ZLib.asyncStream().compress().format(.gzip).build()
try await chunkStream.initialize()

var chunkedCompressed = Data()
let chunkSize = 5

for i in stride(from: 0, to: originalData.count, by: chunkSize) {
    let end = min(i + chunkSize, originalData.count)
    let chunk = originalData.subdata(in: i..<end)
    let flush: FlushMode = (end == originalData.count) ? .finish : .noFlush
    let compressedChunk = try await chunkStream.process(chunk, flush: flush)
    chunkedCompressed.append(compressedChunk)
}
```

## Memory-Efficient Streaming

For processing large files without loading everything into memory:

```swift
import SwiftZlib

// Configure streaming options
let config = StreamingConfig(
    bufferSize: 64 * 1024,  // 64KB chunks
    useTempFiles: false,
    compressionLevel: 6,
    windowBits: 15
)

// File compression
let compressor = try FileCompressor(config: config)
try compressor.compressFile(from: "large_file.txt", to: "large_file.gz")

// ---
// Naming convention for file operations:
// - compressFile / decompressFile: synchronous
// - compressFileAsync / decompressFileAsync: async/await
// - compressFilePublisher / decompressFilePublisher: Combine publisher
// - compressFileProgressPublisher / decompressFileProgressPublisher: Combine publisher with progress
// ---

// Async/await file compression
try await ZLib.compressFileAsync(from: "large_file.txt", to: "large_file.gz")
try await ZLib.decompressFileAsync(from: "large_file.gz", to: "large_file_decompressed.txt")

// Combine publisher for file compression
import Combine
let cancellable = ZLib.compressFilePublisher(from: "large_file.txt", to: "large_file.gz")
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Compression finished")
        case .failure(let error):
            print("Compression failed: \(error)")
        }
    }, receiveValue: {
        print("Compression succeeded")
    })

// Combine publisher for file decompression
let cancellable2 = ZLib.decompressFilePublisher(from: "large_file.gz", to: "large_file_decompressed.txt")
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Decompression finished")
        case .failure(let error):
            print("Decompression failed: \(error)")
        }
    }, receiveValue: {
        print("Decompression succeeded")
    })

// Combine publisher for file compression with progress
let cancellable3 = ZLib.compressFileProgressPublisher(from: "large_file.txt", to: "large_file.gz")
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Compression finished")
        case .failure(let error):
            print("Compression failed: \(error)")
        }
    }, receiveValue: { progress in
        print("Progress: \(progress.percent)% (\(progress.processed)/\(progress.total))")
    })

// File decompression
let decompressor = try FileDecompressor(config: config)
try decompressor.decompressFile(from: "large_file.gz", to: "large_file_decompressed.txt")

// Auto-detect compression/decompression
let processor = FileProcessor(config: config)
try processor.processFile(from: "input.txt", to: "output.gz")  // Compress
try processor.processFile(from: "input.gz", to: "output.txt")  // Decompress

// With progress tracking
try compressor.compressFile(from: "large_file.txt", to: "large_file.gz") { processed, total in
    let percentage = Double(processed) / Double(total) * 100
    print("Progress: \(percentage)%")
}

// Chunked processing for large data
let chunkedProcessor = ChunkedProcessor(config: config)
let results = try chunkedProcessor.processChunks(data: largeData) { chunk in
    return processChunk(chunk)
}

// Convenience methods
try ZLib.compressFile(from: "input.txt", to: "output.gz")
try ZLib.decompressFile(from: "input.gz", to: "output.txt")
try ZLib.processFile(from: "input.txt", to: "output.gz")  // Auto-detect
```

### Streaming Configuration

```swift
let config = StreamingConfig(
    bufferSize: 64 * 1024,      // Buffer size for reading/writing
    useTempFiles: false,         // Use temporary files for intermediate results
    compressionLevel: 6,         // Compression level (0-9)
    windowBits: 15              // Window bits for format
)
```

## Performance Considerations

- **Compression Level**: Use `.bestSpeed` for real-time applications, `.bestCompression` for storage
- **Memory Usage**: For large files, use the stream-based API to avoid loading everything into memory
- **Chunk Size**: When streaming, use 1-64KB chunks for optimal performance
- **Window Bits**: Use `.deflate` for standard compression, `.gzip` for gzip format, `.raw` for no headers
- **Memory Level**: Higher levels use more memory but may be faster

## Testing

Run the test suite:

```bash
swift test
```

The test suite covers:
- Basic compression/decompression
- Stream-based operations
- Error handling
- Gzip file operations
- Header manipulation
- Checksum calculations
- Performance optimization
- Advanced InflateBack functionality

## Contributing

Contributions are welcome! Please ensure:
- All tests pass
- Code follows Swift style guidelines
- New features include appropriate tests
- Documentation is updated

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built on top of the excellent zlib library
- Inspired by modern Swift API design patterns
- Thanks to the zlib development team for their work 

## Thread Safety and Concurrency

**Important:** Compressor and Decompressor instances are **not thread-safe**. Only per-instance concurrency is valid for zlib and this Swift wrapper.

- Each thread must use its own, independent instance of `Compressor` or `Decompressor`.
- **Do not share** a single instance across multiple threads at the same time. Doing so can result in data corruption, crashes, or undefined behavior.
- It is safe to use many Compressor/Decompressor instances in parallel, as long as each is only used by one thread at a time.

### What is Per-Instance Concurrency?

- **Per-instance concurrency** means: each thread creates and uses its own instance of the compressor or decompressor.
- **Not allowed:** Multiple threads using the same instance at the same time.

#### Example (Valid)
```swift
DispatchQueue.concurrentPerform(iterations: 10) { i in
    let compressor = Compressor()
    try! compressor.initialize(level: .defaultCompression)
    let compressed = try! compressor.compress(myData)
    // Each thread uses its own Compressor instance
}
```

#### Example (Invalid)
```swift
let compressor = Compressor()
try! compressor.initialize(level: .defaultCompression)
DispatchQueue.concurrentPerform(iterations: 10) { i in
    let compressed = try! compressor.compress(myData)
    // All threads use the same Compressor instance at the same time (not allowed)
}
```

**Summary:**
- Use a separate Compressor/Decompressor per thread.
- Do not share instances between threads. 

## WindowBits Usage

- `.raw`, `.deflate`, and `.gzip` are valid for both compression and decompression.
- `.auto` is **only valid for decompression (inflate)**, not for compression (deflate).
- Using `.auto` for compression will result in a stream error (`Z_STREAM_ERROR`).
- Use `.raw`, `.deflate`, or `.gzip` for compression. 

## Dictionary Usage

### When to Use Dictionaries
- Dictionaries are used for compression/decompression of data that has known patterns or frequently repeated sequences.
- They can significantly improve compression ratios for data with predictable content.
- **Effectiveness**: Dictionaries are most effective when the data contains patterns that match the dictionary content. If the dictionary doesn't contain useful patterns for the data being compressed, zlib may not use it effectively.
- **Compression Ratio**: You can verify dictionary effectiveness by comparing compression ratios with and without the dictionary. Effective dictionaries typically reduce compressed size by 10-30% or more.

### Dictionary Requirements
- **Compression:** Dictionary must be set **before** compression begins.
- **Decompression:** Dictionary must be set **only after** receiving a `Z_NEED_DICT` error during decompression.
- **Timing:** You cannot set a dictionary on a decompressor unless the stream explicitly signals it needs one.

### Dictionary Error Handling
- Setting a dictionary before initialization will throw a `ZLibError`.
- Setting a dictionary on a decompressor without receiving `Z_NEED_DICT` will throw a `ZLibError`.
- The correct flow is: decompress → receive `Z_NEED_DICT` → set dictionary → continue decompression.

**Important:** When decompressing data that was compressed with a dictionary, but without providing the dictionary, zlib may return different error codes depending on the context:

- **`Z_NEED_DICT (2)`**: Returned during streaming decompression when zlib encounters a point in the stream where it needs a dictionary
- **`Z_DATA_ERROR (-3)`**: Returned when decompressing the entire stream at once without a dictionary

Both error codes are valid responses for missing dictionary scenarios. Your code should handle both cases.

### Example Dictionary Usage
```swift
// Compression with dictionary
let compressor = Compressor()
try compressor.initialize(level: .defaultCompression)
try compressor.setDictionary(dictionaryData)
let compressed = try compressor.compress(data, flush: .finish)

// Decompression with dictionary - handle both error codes
let decompressor = Decompressor()
try decompressor.initialize()
do {
    let decompressed = try decompressor.decompress(compressed)
    // Success
} catch ZLibError.decompressionFailed(let code) where code == 2 { // Z_NEED_DICT
    try decompressor.setDictionary(dictionaryData)
    let decompressed = try decompressor.decompress(compressed)
    // Success
} catch ZLibError.decompressionFailed(let code) where code == -3 { // Z_DATA_ERROR
    // Also a valid response for missing dictionary
    try decompressor.setDictionary(dictionaryData)
    let decompressed = try decompressor.decompress(compressed)
    // Success
}
```

## Priming (Advanced Feature)

### Priming Limitations
- **Priming is a low-level feature** that affects the raw bit stream.
- **Not supported for zlib/gzip streams** - only works with raw deflate streams.
- **Round-trip compression/decompression with priming is not typically supported** because primed bits interfere with the compressed data format.
- Priming is mainly used for specialized applications that need to insert bits into the raw deflate stream.

### Priming Usage
```swift
// Only use with raw deflate streams
let compressor = Compressor()
try compressor.initializeAdvanced(level: .noCompression, windowBits: .raw)
try compressor.prime(bits: 4, value: 0x5)
let compressed = try compressor.compress(data, flush: .finish)
```

## Important zlib Behaviors

### WindowBits Restrictions
- **Compression:** Only `.raw`, `.deflate`, and `.gzip` are valid.
- **Decompression:** All windowBits values are valid, including `.auto` for auto-detection.
- **`.auto` for compression:** Will result in `Z_STREAM_ERROR` (-2).

### Error Codes
- `-1` (`Z_ERRNO`): System error
- `-2` (`Z_STREAM_ERROR`): Invalid stream state or parameters
- `-3` (`Z_DATA_ERROR`): Corrupted or invalid data
- `-4` (`Z_MEM_ERROR`): Memory allocation failure
- `-5` (`Z_BUF_ERROR`): Buffer error
- `-6` (`Z_VERSION_ERROR`): Incompatible zlib version
- `2` (`Z_NEED_DICT`): Dictionary required for decompression

### Memory and Performance
- **Compression levels:** Higher levels use more memory and CPU but produce smaller output.
- **Window size:** Larger windows use more memory but may achieve better compression.
- **Stream reuse:** Reinitialize streams for new data to avoid state corruption.

### Thread Safety
- **Per-instance concurrency:** Each thread must use its own Compressor/Decompressor instance.
- **No shared instances:** Never share a single instance across threads without external synchronization.
- **Global state:** zlib has some global state, so use separate instances per thread. 

## Platform-Specific Behavior: Truncated/Corrupted Data

When decompressing truncated or corrupted data, zlib may either:
- Throw a decompression error (e.g., Z_DATA_ERROR), or
- Return as much decompressed data as possible without error.

This behavior depends on the zlib version and platform. The SwiftZlib test suite and API are robust to both outcomes, and your code should be prepared to handle either case. 

## Gzip Seeking and EOF Behavior

**Why is seeking in gzip files not always supported, and why is EOF reached after reading all data?**

- **Gzip is a compressed, stream-based format.** Unlike uncompressed files, each byte in the file does not map directly to a byte in the output. Gzip compresses data in blocks, so the mapping between compressed and uncompressed positions is not direct or predictable.
- **Seeking requires decompressing.** To seek to a specific position in the uncompressed data, the decompressor must process (decompress) all preceding compressed data. There’s no index or table in the gzip format that allows jumping directly to a specific uncompressed offset.
- **Gzip libraries (including zlib) only support limited seeking.** The `gzseek` function in zlib can only reliably seek to the beginning (`rewind`) or to a position that has already been decompressed and buffered. Seeking forward requires decompressing data up to the target position, which can be slow and memory-intensive.
- **Random access is not efficient or guaranteed.** Some implementations may buffer data to allow limited backward seeking, but this is not required by the format or the library. As a result, seeking to arbitrary positions is not always supported or may fail.

**EOF (End of File) is set after all data is read.**
- When you read until the end of a gzip file, the decompressor reaches the end of the compressed stream and sets the EOF flag. This is expected and correct behavior.
- Once the entire compressed stream has been processed, any further read attempts will immediately return EOF.
- In gzip files, after reading all data, you must `rewind` (start over) to read again.

| Operation         | Uncompressed File | Gzip File (zlib)         |
|-------------------|------------------|--------------------------|
| Seek to offset    | Fast, direct     | Slow, may not be supported |
| Random access     | Yes              | No (must decompress up to point) |
| EOF after read    | Only at end      | At end of decompressed stream    |
| Rewind            | Supported        | Supported (gzrewind)     |

**If you need efficient random access, consider using a format designed for it (like ZIP with an index, or uncompressed files).** 

### Compression Format Differences

**ZLib.compress() vs Compressor for different formats:**

The simple `ZLib.compress()` method always uses zlib format (windowBits = 15), while the `Compressor` class allows you to specify different formats.

```swift
// Simple API - always uses zlib format
let compressed = try ZLib.compress(originalData)

// Advanced API - can specify format
let compressor = Compressor()
try compressor.initializeAdvanced(windowBits: .raw)  // Raw deflate
let compressed = try compressor.compress(originalData)
```

**When to use each approach:**

| Use Case | Method | Format | Example |
|----------|--------|--------|---------|
| General compression | `ZLib.compress()` | zlib format | Standard compression |
| Raw deflate (for InflateBack) | `Compressor` with `.raw` | Raw deflate | Advanced streaming |
| Gzip format | `Compressor` with `.gzip` | Gzip format | File compression |
| Auto-detect | `Compressor` with `.auto` | Auto-detect | Unknown format |

**Example: Raw deflate for InflateBack compatibility**
```swift
// Must use raw deflate for InflateBack
let compressor = Compressor()
try compressor.initializeAdvanced(windowBits: .raw)
let compressed = try compressor.compress(originalData)

// Now compatible with InflateBack
let inflater = InflateBackDecompressorCBridged(windowBits: .raw)
try inflater.initialize()
let decompressed = try inflater.processData(compressed)
``` 

## True Chunked Streaming for Huge Files

For processing arbitrarily large files with constant memory usage:

```swift
import SwiftZlib

// Basic chunked streaming compression
let compressor = FileChunkedCompressor(
    bufferSize: 64 * 1024,  // 64KB chunks
    compressionLevel: .defaultCompression,
    windowBits: .deflate
)
try compressor.compressFile(from: "huge_file.txt", to: "huge_file.gz")

// Basic chunked streaming decompression
let decompressor = FileChunkedDecompressor(
    bufferSize: 64 * 1024,
    windowBits: .deflate
)
try decompressor.decompressFile(from: "huge_file.gz", to: "huge_file_decompressed.txt")

// With progress tracking
try compressor.compressFile(from: "huge_file.txt", to: "huge_file.gz") { processed, total in
    let percentage = Double(processed) / Double(total) * 100
    print("Compression progress: \(percentage)%")
}

// Async versions
try await compressor.compressFile(from: "huge_file.txt", to: "huge_file.gz")
try await decompressor.decompressFile(from: "huge_file.gz", to: "huge_file_decompressed.txt")

// Async with progress tracking
try await compressor.compressFile(from: "huge_file.txt", to: "huge_file.gz") { processed, total in
    let percentage = Double(processed) / Double(total) * 100
    print("Async compression progress: \(percentage)%")
}

// Convenience methods
try ZLib.compressFileChunked(from: "huge_file.txt", to: "huge_file.gz")
try ZLib.decompressFileChunked(from: "huge_file.gz", to: "huge_file_decompressed.txt")

// Async convenience methods
try await ZLib.compressFileChunked(from: "huge_file.txt", to: "huge_file.gz")
try await ZLib.decompressFileChunked(from: "huge_file.gz", to: "huge_file_decompressed.txt")
```

### Key Features

- **Constant Memory Usage**: Only uses a fixed buffer size regardless of file size
- **True Streaming**: Processes files in chunks without loading the entire file into memory
- **Progress Tracking**: Real-time progress callbacks for long-running operations
- **Async Support**: Non-blocking async/await APIs for modern Swift applications
- **Configurable**: Adjustable buffer sizes, compression levels, and window bits

### Use Cases

- **Large Log Files**: Compress multi-GB log files efficiently
- **Backup Systems**: Stream large backups without memory constraints
- **Data Processing**: Handle large datasets in data pipelines
- **Web Services**: Stream compression/decompression in HTTP responses
- **CLI Tools**: Build command-line utilities for file compression 

## Advanced Progress Reporting for Chunked Streaming

You can track progress with rich information, throttle updates, support cancellation, and integrate with Foundation.Progress and UI queues:

```swift
import SwiftZlib
import Foundation

let compressor = FileChunkedCompressor(bufferSize: 64 * 1024)
let progress = Progress(totalUnitCount: 0) // Set after file size is known

try compressor.compressFile(
    from: "huge_file.txt",
    to: "huge_file.gz",
    progressCallback: { info in
        print("[\(info.phase.rawValue)] \(info.percentage)% (\(info.processedBytes)/\(info.totalBytes)) ETA: \(info.etaSeconds ?? 0)s Speed: \(info.speedBytesPerSec ?? 0) B/s")
        // Cancel if needed:
        if info.percentage > 50 { return true } // continue
        return true // return false to cancel
    },
    progressObject: progress, // Optional: Foundation.Progress integration
    progressInterval: 0.2,   // Throttle updates to every 200ms
    progressQueue: .main     // UI updates on main queue
)
```

- `ProgressInfo` provides: processedBytes, totalBytes, percentage, speedBytesPerSec, etaSeconds, phase, timestamp.
- `progressCallback` can return `false` to cancel.
- `progressObject` (optional) is a Foundation.Progress instance for UI integration.
- `progressInterval` controls how often updates are sent.
- `progressQueue` lets you specify the dispatch queue for callbacks (e.g., `.main` for UI).
- `phase` is a `CompressionPhase` enum: `.reading`, `.compressing`, `.writing`, `.flushing`, `.finished`.

The same applies to `FileChunkedDecompressor`. 

### AsyncStream Progress Reporting for File Compression/Decompression

The `FileChunkedCompressor` and `FileChunkedDecompressor` classes provide AsyncStream-based progress reporting for modern Swift concurrency patterns. This allows you to process large files with real-time progress updates using async/await syntax.

#### Basic AsyncStream Usage

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()
let srcPath = "/tmp/large_input.txt"
let dstPath = "/tmp/large_output.gz"

// Compress with progress updates
for await progress in compressor.compressFileProgressStream(from: srcPath, to: dstPath) {
    print("Compression progress: \(progress.percentage)% (\(progress.processedBytes)/\(progress.totalBytes))")
}

let decompressor = FileChunkedDecompressor()
let decompressedPath = "/tmp/large_output_decompressed.txt"

// Decompress with progress updates
for await progress in decompressor.decompressFileProgressStream(from: dstPath, to: decompressedPath) {
    print("Decompression progress: \(progress.percentage)% (\(progress.processedBytes)/\(progress.totalBytes))")
}
```

#### Advanced AsyncStream Usage with Configuration

```swift
import SwiftZlib

// Configure compressor with custom settings
let compressor = FileChunkedCompressor(
    bufferSize: 128 * 1024,  // 128KB chunks
    compressionLevel: .bestCompression,
    windowBits: .gzip
)

// Compress with detailed progress tracking
for await progress in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz"
) {
    switch progress.phase {
    case .reading:
        print("📖 Reading: \(progress.percentage)%")
    case .compressing:
        print("🗜️ Compressing: \(progress.percentage)%")
    case .writing:
        print("💾 Writing: \(progress.percentage)%")
    case .flushing:
        print("🔄 Flushing: \(progress.percentage)%")
    case .finished:
        print("✅ Finished: \(progress.percentage)%")
    }
    
    if let speed = progress.speedBytesPerSec {
        print("   Speed: \(speed / 1024 / 1024) MB/s")
    }
    
    if let eta = progress.etaSeconds {
        print("   ETA: \(eta) seconds")
    }
}
```

#### AsyncStream with Cancellation Support

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

// Create a task that can be cancelled
let compressionTask = Task {
    for await progress in compressor.compressFileProgressStream(
        from: "huge_file.txt",
        to: "huge_file.gz"
    ) {
        print("Progress: \(progress.percentage)%")
        
        // Check for cancellation
        if Task.isCancelled {
            print("Compression cancelled")
            break
        }
        
        // Cancel after 50%
        if progress.percentage > 50 {
            print("Cancelling at 50%")
            break
        }
    }
}

// Cancel the task if needed
// compressionTask.cancel()
```

#### AsyncStream with Error Handling

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

do {
    for await progress in compressor.compressFileProgressStream(
        from: "input.txt",
        to: "output.gz"
    ) {
        print("Progress: \(progress.percentage)%")
    }
    print("Compression completed successfully")
} catch ZLibError.compressionFailed(let code) {
    print("Compression failed with code: \(code)")
} catch {
    print("Unexpected error: \(error)")
}
```

#### AsyncStream with Progress Throttling

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

// Throttle progress updates to every 500ms
for await progress in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz",
    progressInterval: 0.5  // 500ms intervals
) {
    print("Progress: \(progress.percentage)%")
}
```

#### AsyncStream with Custom Progress Queue

```swift
import SwiftZlib
import Foundation

let compressor = FileChunkedCompressor()

// Use main queue for UI updates
for await progress in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz",
    progressQueue: .main
) {
    // Update UI on main thread
    updateProgressBar(progress.percentage)
    updateSpeedLabel(progress.speedBytesPerSec ?? 0)
    updateETALabel(progress.etaSeconds ?? 0)
}
```

#### AsyncStream with Foundation.Progress Integration

```swift
import SwiftZlib
import Foundation

let compressor = FileChunkedCompressor()
let progress = Progress(totalUnitCount: 0) // Will be set automatically

// Integrate with Foundation.Progress for UI frameworks
for await progressInfo in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz",
    progressObject: progress
) {
    // Foundation.Progress is automatically updated
    print("Foundation Progress: \(progress.fractionCompleted * 100)%")
    print("Custom Progress: \(progressInfo.percentage)%")
}
```

#### AsyncStream for Multiple Files

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

// Process multiple files with progress tracking
let files = ["file1.txt", "file2.txt", "file3.txt"]

for file in files {
    let outputFile = file + ".gz"
    print("Compressing \(file)...")
    
    for await progress in compressor.compressFileProgressStream(
        from: file,
        to: outputFile
    ) {
        print("\(file): \(progress.percentage)%")
    }
    
    print("Completed \(file)")
}
```

#### AsyncStream with Structured Progress Information

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

struct CompressionStats {
    var totalFiles = 0
    var completedFiles = 0
    var totalBytes = 0
    var processedBytes = 0
}

var stats = CompressionStats()

for await progress in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz"
) {
    stats.processedBytes = progress.processedBytes
    stats.totalBytes = progress.totalBytes
    
    let compressionRatio = Double(progress.processedBytes) / Double(progress.totalBytes)
    let estimatedFinalSize = Int64(Double(progress.totalBytes) * compressionRatio)
    
    print("""
    📊 Compression Statistics:
    - Progress: \(progress.percentage)%
    - Processed: \(progress.processedBytes) bytes
    - Total: \(progress.totalBytes) bytes
    - Estimated final size: \(estimatedFinalSize) bytes
    - Phase: \(progress.phase.rawValue)
    - Speed: \(progress.speedBytesPerSec ?? 0) B/s
    - ETA: \(progress.etaSeconds ?? 0) seconds
    """)
}
```

#### AsyncStream with Conditional Processing

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

// Only compress if file is large enough
let fileSize = try FileManager.default.attributesOfItem(atPath: "input.txt")[.size] as? Int64 ?? 0

if fileSize > 1024 * 1024 { // Only compress files > 1MB
    for await progress in compressor.compressFileProgressStream(
        from: "input.txt",
        to: "input.gz"
    ) {
        print("Compressing large file: \(progress.percentage)%")
    }
} else {
    print("File too small, skipping compression")
}
```

#### AsyncStream with Memory Monitoring

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

for await progress in compressor.compressFileProgressStream(
    from: "huge_file.txt",
    to: "huge_file.gz"
) {
    // Monitor memory usage during compression
    let memoryUsage = ProcessInfo.processInfo.memoryFootprint
    let maxMemory = ProcessInfo.processInfo.physicalMemory
    
    print("""
    Progress: \(progress.percentage)%
    Memory Usage: \(memoryUsage / 1024 / 1024) MB / \(maxMemory / 1024 / 1024) MB
    Memory Pressure: \(Double(memoryUsage) / Double(maxMemory) * 100)%
    """)
    
    // Pause if memory pressure is high
    if Double(memoryUsage) / Double(maxMemory) > 0.8 {
        print("⚠️ High memory pressure, consider pausing...")
    }
}
```

#### AsyncStream with Performance Metrics

```swift
import SwiftZlib

let compressor = FileChunkedCompressor()

var startTime: TimeInterval = 0
var lastUpdateTime: TimeInterval = 0

for await progress in compressor.compressFileProgressStream(
    from: "large_file.txt",
    to: "large_file.gz"
) {
    let currentTime = CFAbsoluteTimeGetCurrent()
    
    if startTime == 0 {
        startTime = currentTime
        lastUpdateTime = currentTime
    }
    
    let elapsed = currentTime - startTime
    let timeSinceLastUpdate = currentTime - lastUpdateTime
    
    if timeSinceLastUpdate >= 1.0 { // Update every second
        let throughput = Double(progress.processedBytes) / elapsed
        let compressionRatio = Double(progress.processedBytes) / Double(progress.totalBytes)
        
        print("""
        ⚡ Performance Metrics:
        - Elapsed Time: \(elapsed)s
        - Throughput: \(throughput / 1024 / 1024) MB/s
        - Compression Ratio: \(compressionRatio)
        - Progress: \(progress.percentage)%
        """)
        
        lastUpdateTime = currentTime
    }
}
```

### Key Features of AsyncStream Progress Reporting

- **Real-time Updates**: Get progress information as the operation proceeds
- **Structured Data**: Access detailed progress information including speed, ETA, and phase
- **Cancellation Support**: Can be cancelled using Swift's structured concurrency
- **Error Handling**: Proper error propagation through async/await
- **Throttling**: Control update frequency to avoid overwhelming the system
- **Queue Control**: Specify which dispatch queue to use for callbacks
- **Foundation Integration**: Optional integration with Foundation.Progress
- **Memory Efficient**: Constant memory usage regardless of file size
- **Cross-platform**: Works on macOS and Linux

### Progress Information Structure

The `ProgressInfo` struct provides:

```swift
struct ProgressInfo {
    let processedBytes: Int64      // Bytes processed so far
    let totalBytes: Int64         // Total bytes to process
    let percentage: Double         // Progress percentage (0-100)
    let speedBytesPerSec: Int64?  // Processing speed in bytes/second
    let etaSeconds: Double?       // Estimated time to completion
    let phase: CompressionPhase   // Current operation phase
    let timestamp: Date           // When this progress update was generated
}

enum CompressionPhase: String {
    case reading = "reading"       // Reading input file
    case compressing = "compressing" // Compressing data
    case writing = "writing"       // Writing output file
    case flushing = "flushing"     // Finalizing compression
    case finished = "finished"     // Operation completed
}
```

### Best Practices

1. **Use appropriate buffer sizes**: Larger buffers (64KB-128KB) for better performance
2. **Handle cancellation gracefully**: Check `Task.isCancelled` in long-running operations
3. **Throttle updates**: Use `progressInterval` to avoid overwhelming the system
4. **Use main queue for UI**: Set `progressQueue: .main` for UI updates
5. **Monitor memory**: Large files can consume significant memory during processing
6. **Handle errors**: Always wrap in do-catch blocks for proper error handling
7. **Consider compression levels**: Balance between speed and compression ratio
8. **Use appropriate window bits**: Choose the right format for your use case

## Documentation

- [Architecture Overview](doc/ARCHITECTURE.md)
- [Priming Support](doc/PRIMING.md)
- [Dictionary Compression](doc/DICTIONARY_COMPRESSION.md)
- [Streaming API](doc/STREAMING.md)
- [Error Handling](doc/ERROR_HANDLING.md)
- [Gzip Support](doc/GZIP_SUPPORT.md)
- [Testing](doc/TESTING.md)
- [Advanced Features](doc/ADVANCED_FEATURES.md)

## Test Coverage Summary

| Area                | Coverage | Comments |
|---------------------|----------|----------|
| Basic Compression   | ✅        | Round-trip, all levels, small/large/binary/empty data |
| Streaming/Chunked   | ✅        | Multiple chunk sizes, streaming APIs, output handler aborts |
| Dictionary          | ✅        | All edge cases: correct, wrong, missing, large, empty, timing |
| Priming             | ✅        | All edge cases: before/after, invalid, round-trip, raw/zlib/gzip |
| WindowBits          | ✅        | All variants, mismatches, auto-detect, empty/corrupted input |
| Error Handling      | ✅        | All major zlib errors, custom error codes, recovery suggestions |
| Edge Cases          | ✅        | Empty, single-byte, large, binary, corrupted, concurrent |
| Gzip Header         | ✅        | Metadata, corruption, round-trip, streaming, auto-detect |