# API Reference

This document provides a comprehensive reference for all public APIs in SwiftZlib.

## Core APIs

### ZLib

The main entry point for compression and decompression operations.

```swift
class ZLib
```

#### Static Methods

##### Compression

```swift
static func compress(_ data: Data, level: CompressionLevel = .default) throws -> Data
static func compress(_ data: Data, level: CompressionLevel, strategy: CompressionStrategy) throws -> Data
static func compress(_ data: Data, level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits) throws -> Data
```

Compress data using zlib compression.

**Parameters:**

- `data`: The data to compress
- `level`: Compression level (0-9, default is 6)
- `strategy`: Compression strategy (default, filtered, huffman, rle, fixed)
- `windowBits`: Window size and format (default, gzip, raw, etc.)

**Returns:** Compressed data

**Throws:** `ZLibError` if compression fails

##### Decompression

```swift
static func decompress(_ data: Data) throws -> Data
static func decompress(_ data: Data, windowBits: WindowBits) throws -> Data
```

Decompress data using zlib decompression.

**Parameters:**

- `data`: The compressed data to decompress
- `windowBits`: Window size and format (default, gzip, raw, etc.)

**Returns:** Decompressed data

**Throws:** `ZLibError` if decompression fails

#### Streaming APIs

##### Compressor

```swift
static func createCompressor(level: CompressionLevel = .default) -> Compressor
static func createCompressor(level: CompressionLevel, strategy: CompressionStrategy) -> Compressor
static func createCompressor(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits) -> Compressor
```

Create a streaming compressor for processing large data in chunks.

**Parameters:**

- `level`: Compression level (0-9, default is 6)
- `strategy`: Compression strategy
- `windowBits`: Window size and format

**Returns:** A `Compressor` instance

##### Decompressor

```swift
static func createDecompressor() -> Decompressor
static func createDecompressor(windowBits: WindowBits) -> Decompressor
```

Create a streaming decompressor for processing large compressed data in chunks.

**Parameters:**

- `windowBits`: Window size and format

**Returns:** A `Decompressor` instance

#### Fluent Builder APIs

##### ZLibStreamBuilder

```swift
static func stream() -> ZLibStreamBuilder
```

Create a fluent builder for configuring and creating zlib streams.

**Returns:** A `ZLibStreamBuilder` instance

**Example:**

```swift
let stream = ZLib.stream()
    .compression(level: .best)
    .strategy(.huffman)
    .windowBits(.gzip)
    .build()
```

##### AsyncZLibStreamBuilder

```swift
static func asyncStream() -> AsyncZLibStreamBuilder
```

Create a fluent builder for configuring and creating async zlib streams.

**Returns:** An `AsyncZLibStreamBuilder` instance

**Example:**

```swift
let asyncStream = ZLib.asyncStream()
    .compression(level: .best)
    .strategy(.huffman)
    .windowBits(.gzip)
    .build()
```

### Compression

#### CompressionLevel

```swift
enum CompressionLevel: Int32, CaseIterable
```

Compression levels from 0 (no compression) to 9 (best compression).

**Cases:**

- `noCompression = 0`: No compression
- `bestSpeed = 1`: Best speed
- `bestCompression = 9`: Best compression
- `default = 6`: Default compression level

#### CompressionMethod

```swift
enum CompressionMethod: Int32
```

Compression methods supported by zlib.

**Cases:**

- `deflate = 8`: Deflate compression method

#### CompressionStrategy

```swift
enum CompressionStrategy: Int32
```

Compression strategies for different data types.

**Cases:**

- `default`: Default strategy
- `filtered`: Filtered strategy for data with small runs
- `huffman`: Huffman-only strategy
- `rle`: Run-length encoding strategy
- `fixed`: Fixed strategy

#### CompressionPhase

```swift
enum CompressionPhase
```

Phases of the compression process.

**Cases:**

- `start`: Initialization phase
- `compress`: Compression phase
- `finish`: Finalization phase

### WindowBits

```swift
enum WindowBits: Int32
```

Window size and format options for compression/decompression.

**Cases:**

- `default = 15`: Default window size (32KB)
- `gzip = 31`: Gzip format with 32KB window
- `raw = -15`: Raw deflate format
- `custom(Int32)`: Custom window size (8-15 for window size, 16 for gzip, 32 for zlib)

### FlushMode

```swift
enum FlushMode: Int32
```

Flush modes for streaming operations.

**Cases:**

- `none = 0`: No flushing
- `partial = 1`: Partial flush
- `sync = 2`: Synchronous flush
- `full = 3`: Full flush
- `finish = 4`: Finish compression
- `block = 5`: Block flush

### MemoryLevel

```swift
enum MemoryLevel: Int32
```

Memory usage levels for compression.

**Cases:**

- `minimum = 1`: Minimum memory usage
- `default = 8`: Default memory usage
- `maximum = 9`: Maximum memory usage

## Streaming APIs

### Compressor

```swift
class Compressor
```

A streaming compressor for processing large data in chunks.

#### Initialization

```swift
init(level: CompressionLevel = .default)
init(level: CompressionLevel, strategy: CompressionStrategy)
init(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits)
```

#### Methods

```swift
func compress(_ data: Data, flush: FlushMode = .none) throws -> Data
func finish() throws -> Data
func reset()
```

**Parameters:**

- `data`: Data to compress
- `flush`: Flush mode for this operation

**Returns:** Compressed data

**Throws:** `ZLibError` if compression fails

### Decompressor

```swift
class Decompressor
```

A streaming decompressor for processing large compressed data in chunks.

#### Initialization

```swift
init()
init(windowBits: WindowBits)
```

#### Methods

```swift
func decompress(_ data: Data, flush: FlushMode = .none) throws -> Data
func reset()
```

**Parameters:**

- `data`: Compressed data to decompress
- `flush`: Flush mode for this operation

**Returns:** Decompressed data

**Throws:** `ZLibError` if decompression fails

### InflateBackDecompressor

```swift
class InflateBackDecompressor
```

A specialized decompressor for processing data in reverse order.

#### Initialization

```swift
init(windowBits: WindowBits = .default)
```

#### Methods

```swift
func decompress(_ data: Data, flush: FlushMode = .none) throws -> Data
func reset()
```

### EnhancedInflateBackDecompressor

```swift
class EnhancedInflateBackDecompressor
```

An enhanced version of the inflate back decompressor with additional features.

#### Initialization

```swift
init(windowBits: WindowBits = .default)
```

#### Methods

```swift
func decompress(_ data: Data, flush: FlushMode = .none) throws -> Data
func reset()
```

## File Operations

### FileCompressor

```swift
class FileCompressor
```

Compressor for processing files directly.

#### Initialization

```swift
init(level: CompressionLevel = .default)
init(level: CompressionLevel, strategy: CompressionStrategy)
init(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits)
```

#### Methods

```swift
func compressFile(at path: String, to outputPath: String) throws
func compressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
```

**Parameters:**

- `path`: Path to input file
- `outputPath`: Path to output file
- `progress`: Optional progress callback

**Throws:** `ZLibError` if compression fails

### FileDecompressor

```swift
class FileDecompressor
```

Decompressor for processing files directly.

#### Initialization

```swift
init(windowBits: WindowBits = .default)
```

#### Methods

```swift
func decompressFile(at path: String, to outputPath: String) throws
func decompressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
```

**Parameters:**

- `path`: Path to input file
- `outputPath`: Path to output file
- `progress`: Optional progress callback

**Throws:** `ZLibError` if decompression fails

### Chunked File Operations

#### FileChunkedCompressor

```swift
class FileChunkedCompressor
```

Compressor for processing large files in chunks with memory-efficient streaming.

#### Initialization

```swift
init(level: CompressionLevel = .default, chunkSize: Int = 64 * 1024)
init(level: CompressionLevel, strategy: CompressionStrategy, chunkSize: Int = 64 * 1024)
init(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits, chunkSize: Int = 64 * 1024)
```

#### Methods

```swift
func compressFile(at path: String, to outputPath: String) throws
func compressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
```

#### FileChunkedDecompressor

```swift
class FileChunkedDecompressor
```

Decompressor for processing large compressed files in chunks with memory-efficient streaming.

#### Initialization

```swift
init(windowBits: WindowBits = .default, chunkSize: Int = 64 * 1024)
```

#### Methods

```swift
func decompressFile(at path: String, to outputPath: String) throws
func decompressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
```

### GzipFile

```swift
class GzipFile
```

Specialized class for working with gzip files.

#### Initialization

```swift
init(path: String, mode: String)
```

#### Methods

```swift
func write(_ data: Data) throws
func read(_ length: Int) throws -> Data
func close() throws
```

## Async APIs

### AsyncCompressor

```swift
class AsyncCompressor
```

Asynchronous compressor for processing data in background.

#### Initialization

```swift
init(level: CompressionLevel = .default)
init(level: CompressionLevel, strategy: CompressionStrategy)
init(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits)
```

#### Methods

```swift
func compress(_ data: Data, flush: FlushMode = .none) async throws -> Data
func finish() async throws -> Data
func reset()
```

### AsyncDecompressor

```swift
class AsyncDecompressor
```

Asynchronous decompressor for processing data in background.

#### Initialization

```swift
init(windowBits: WindowBits = .default)
```

#### Methods

```swift
func decompress(_ data: Data, flush: FlushMode = .none) async throws -> Data
func reset()
```

### AsyncZLibStream

```swift
class AsyncZLibStream
```

Asynchronous stream for processing data with progress reporting.

#### Initialization

```swift
init(compression: Compression, windowBits: WindowBits = .default)
```

#### Methods

```swift
func process(_ data: Data) async throws -> Data
func finish() async throws -> Data
func reset()
```

## Builder Pattern APIs

### ZLibStreamBuilder

```swift
class ZLibStreamBuilder
```

Fluent builder for configuring and creating zlib streams.

#### Configuration Methods

```swift
func compression(level: CompressionLevel) -> ZLibStreamBuilder
func compression(level: CompressionLevel, strategy: CompressionStrategy) -> ZLibStreamBuilder
func decompression() -> ZLibStreamBuilder
func windowBits(_ windowBits: WindowBits) -> ZLibStreamBuilder
func memoryLevel(_ memoryLevel: MemoryLevel) -> ZLibStreamBuilder
func chunkSize(_ chunkSize: Int) -> ZLibStreamBuilder
```

#### Build Methods

```swift
func build() -> ZLibStream
func buildCompressor() -> Compressor
func buildDecompressor() -> Decompressor
```

### AsyncZLibStreamBuilder

```swift
class AsyncZLibStreamBuilder
```

Fluent builder for configuring and creating async zlib streams.

#### Configuration Methods

```swift
func compression(level: CompressionLevel) -> AsyncZLibStreamBuilder
func compression(level: CompressionLevel, strategy: CompressionStrategy) -> AsyncZLibStreamBuilder
func decompression() -> AsyncZLibStreamBuilder
func windowBits(_ windowBits: WindowBits) -> AsyncZLibStreamBuilder
func memoryLevel(_ memoryLevel: MemoryLevel) -> AsyncZLibStreamBuilder
func chunkSize(_ chunkSize: Int) -> AsyncZLibStreamBuilder
```

#### Build Methods

```swift
func build() -> AsyncZLibStream
func buildCompressor() -> AsyncCompressor
func buildDecompressor() -> AsyncDecompressor
```

## Progress Stream APIs

### Progress Reporting

All file operations support optional progress callbacks:

```swift
func compressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
func decompressFile(at path: String, to outputPath: String, progress: ((Int, Int) -> Void)?) throws
```

**Progress Callback:**

- First parameter: Bytes processed
- Second parameter: Total bytes (if known, otherwise 0)

**Example:**

```swift
try compressor.compressFile(
    at: "input.txt",
    to: "output.gz",
    progress: { processed, total in
        let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
        print("Progress: \(percentage)%")
    }
)
```

## Error Handling

### ZLibError

```swift
enum ZLibError: Error, LocalizedError
```

Errors that can occur during compression or decompression.

**Cases:**

- `invalidParameter`: Invalid parameter provided
- `bufferError`: Buffer error
- `dataError`: Corrupted or invalid data
- `streamError`: Stream error
- `memoryError`: Memory allocation error
- `versionError`: Version mismatch
- `streamEnd`: End of stream reached
- `needDictionary`: Dictionary needed for decompression
- `unknownError(Int32)`: Unknown error with code

### ZLibErrorCode

```swift
enum ZLibErrorCode: Int32
```

Raw error codes from zlib.

**Cases:**

- `ok = 0`: No error
- `streamEnd = 1`: End of stream
- `needDictionary = 2`: Dictionary needed
- `streamError = -2`: Stream error
- `dataError = -3`: Data error
- `memoryError = -4`: Memory error
- `bufferError = -5`: Buffer error
- `versionError = -6`: Version error

### GzipFileError

```swift
enum GzipFileError: Error, LocalizedError
```

Errors specific to gzip file operations.

**Cases:**

- `fileNotFound`: File not found
- `permissionDenied`: Permission denied
- `invalidFormat`: Invalid gzip format
- `compressionError`: Compression error
- `decompressionError`: Decompression error
- `ioError`: I/O error

## Data Extensions

### Data+Extensions

```swift
extension Data
```

#### Compression Methods

```swift
func compressed(level: CompressionLevel = .default) throws -> Data
func compressed(level: CompressionLevel, strategy: CompressionStrategy) throws -> Data
func compressed(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits) throws -> Data
```

#### Decompression Methods

```swift
func decompressed() throws -> Data
func decompressed(windowBits: WindowBits) throws -> Data
```

## String Extensions

### String+Extensions

```swift
extension String
```

#### Compression Methods

```swift
func compressed(level: CompressionLevel = .default) throws -> Data
func compressed(level: CompressionLevel, strategy: CompressionStrategy) throws -> Data
func compressed(level: CompressionLevel, strategy: CompressionStrategy, windowBits: WindowBits) throws -> Data
```

#### Decompression Methods

```swift
func decompressed() throws -> String
func decompressed(windowBits: WindowBits) throws -> String
```

## Combine Integration

### ZLib+Combine

```swift
extension ZLib
```

#### Publishers

```swift
static func compressPublisher(_ data: Data, level: CompressionLevel = .default) -> AnyPublisher<Data, ZLibError>
static func decompressPublisher(_ data: Data) -> AnyPublisher<Data, ZLibError>
```

## AsyncStream Integration

### ZLib+AsyncStream

```swift
extension ZLib
```

#### AsyncStream Methods

```swift
static func compressStream(_ data: Data, level: CompressionLevel = .default) -> AsyncStream<Data>
static func decompressStream(_ data: Data) -> AsyncStream<Data>
```

## File Operations

### ZLib+File

```swift
extension ZLib
```

#### File Methods

```swift
static func compressFile(at path: String, to outputPath: String, level: CompressionLevel = .default) throws
static func decompressFile(at path: String, to outputPath: String) throws
```

### ZLib+FileChunked

```swift
extension ZLib
```

#### Chunked File Methods

```swift
static func compressFileChunked(at path: String, to outputPath: String, level: CompressionLevel = .default, chunkSize: Int = 64 * 1024) throws
static func decompressFileChunked(at path: String, to outputPath: String, chunkSize: Int = 64 * 1024) throws
```

## Stream Operations

### ZLib+Stream

```swift
extension ZLib
```

#### Stream Methods

```swift
static func createStream(compression: Compression, windowBits: WindowBits = .default) -> ZLibStream
static func createAsyncStream(compression: Compression, windowBits: WindowBits = .default) -> AsyncZLibStream
```

## Configuration

### StreamingConfig

```swift
struct StreamingConfig
```

Configuration for streaming operations.

**Properties:**

- `chunkSize`: Size of chunks to process
- `memoryLevel`: Memory usage level
- `windowBits`: Window size and format

### GzipHeader

```swift
struct GzipHeader
```

Gzip file header information.

**Properties:**

- `filename`: Original filename
- `comment`: File comment
- `modificationTime`: File modification time
- `os`: Operating system identifier
- `extraFlags`: Extra flags
- `compressionMethod`: Compression method used

## Logging

### Logging

```swift
enum Logging
```

Logging configuration for debugging.

**Methods:**

```swift
static func enableDebugLogging()
static func disableDebugLogging()
```

## Timer

### Timer

```swift
class Timer
```

Utility for measuring operation performance.

**Methods:**

```swift
static func measure<T>(_ operation: () throws -> T) throws -> (T, TimeInterval)
static func measureAsync<T>(_ operation: () async throws -> T) async throws -> (T, TimeInterval)
```
