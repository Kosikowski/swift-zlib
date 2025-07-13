# API Reference

Complete reference for all SwiftZlib public APIs, types, and methods.

## Core Types

### ZLibError

```swift
enum ZLibError: Error, LocalizedError {
    case invalidData
    case insufficientMemory
    case streamError(ZLibStatus)
    case fileError(String)
    case unsupportedOperation(String)
}
```

**Description**: Main error type for zlib-related operations.

**Cases**:

- `invalidData`: Input data is corrupted or not compressed
- `insufficientMemory`: System memory is insufficient for operation
- `streamError(ZLibStatus)`: Internal zlib stream error with status code
- `fileError(String)`: File operation error with description
- `unsupportedOperation(String)`: Operation not supported with reason

### ZLibStatus

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

**Description**: Detailed status codes from the underlying zlib library.

### CompressionLevel

```swift
enum CompressionLevel: Int32 {
    case noCompression = 0
    case bestSpeed = 1
    case best = 9
    case default = 6
}
```

**Description**: Compression level options affecting speed vs. ratio trade-off.

### CompressionStrategy

```swift
enum CompressionStrategy: Int32 {
    case `default` = 0
    case filtered = 1
    case huffman = 2
    case rle = 3
    case fixed = 4
}
```

**Description**: Compression strategy for different data types.

### MemoryLevel

```swift
enum MemoryLevel: Int32 {
    case min = 1
    case `default` = 8
    case max = 9
}
```

**Description**: Memory usage level for compression operations.

### FlushMode

```swift
enum FlushMode: Int32 {
    case none = 0
    case partial = 1
    case sync = 2
    case full = 3
    case finish = 4
    case block = 5
}
```

**Description**: Flush modes for streaming operations.

## Data Extensions

### Data+Extensions

#### compress(level:strategy:dictionary:)

```swift
func compress(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) throws -> Data
```

**Description**: Compresses data using zlib DEFLATE algorithm.

**Parameters**:

- `level`: Compression level (default: `.default`)
- `strategy`: Compression strategy (default: `.default`)
- `dictionary`: Optional dictionary for compression (default: `nil`)

**Returns**: Compressed data

**Throws**: `ZLibError` on compression failure

**Example**:

```swift
let data = "Hello, World!".data(using: .utf8)!
let compressed = try data.compress(level: .best)
```

#### compressAsync(level:strategy:dictionary:)

```swift
func compressAsync(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) async throws -> Data
```

**Description**: Asynchronously compresses data.

**Parameters**: Same as `compress(level:strategy:dictionary:)`

**Returns**: Compressed data

**Throws**: `ZLibError` on compression failure

#### compressPublisher(level:strategy:dictionary:)

```swift
func compressPublisher(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) -> AnyPublisher<Data, ZLibError>
```

**Description**: Returns a Combine publisher for compression.

**Parameters**: Same as `compress(level:strategy:dictionary:)`

**Returns**: Publisher that emits compressed data

#### decompress()

```swift
func decompress() throws -> Data
```

**Description**: Decompresses data using zlib INFLATE algorithm.

**Returns**: Decompressed data

**Throws**: `ZLibError` on decompression failure

**Example**:

```swift
let decompressed = try compressedData.decompress()
```

#### decompressAsync()

```swift
func decompressAsync() async throws -> Data
```

**Description**: Asynchronously decompresses data.

**Returns**: Decompressed data

**Throws**: `ZLibError` on decompression failure

#### decompressPublisher()

```swift
func decompressPublisher() -> AnyPublisher<Data, ZLibError>
```

**Description**: Returns a Combine publisher for decompression.

**Returns**: Publisher that emits decompressed data

## String Extensions

### String+Extensions

#### compress(level:strategy:dictionary:)

```swift
func compress(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) throws -> Data
```

**Description**: Compresses string data.

**Parameters**: Same as Data extension

**Returns**: Compressed data

**Throws**: `ZLibError` on compression failure

**Example**:

```swift
let text = "Hello, World!"
let compressed = try text.compress(level: .best)
```

#### compressAsync(level:strategy:dictionary:)

```swift
func compressAsync(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) async throws -> Data
```

**Description**: Asynchronously compresses string data.

#### compressPublisher(level:strategy:dictionary:)

```swift
func compressPublisher(
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) -> AnyPublisher<Data, ZLibError>
```

**Description**: Returns a Combine publisher for string compression.

#### decompress()

```swift
func decompress() throws -> String
```

**Description**: Decompresses data to string.

**Returns**: Decompressed string

**Throws**: `ZLibError` on decompression failure

**Example**:

```swift
let decompressed = try compressedData.decompress()
```

#### decompressAsync()

```swift
func decompressAsync() async throws -> String
```

**Description**: Asynchronously decompresses data to string.

#### decompressPublisher()

```swift
func decompressPublisher() -> AnyPublisher<String, ZLibError>
```

**Description**: Returns a Combine publisher for string decompression.

## ZLib Static Methods

### File Operations

#### compressFile(from:to:level:progress:)

```swift
static func compressFile(
    from inputPath: String,
    to outputPath: String,
    level: CompressionLevel = .default,
    progress: ((Double) -> Void)? = nil
) throws
```

**Description**: Compresses a file with progress reporting.

**Parameters**:

- `inputPath`: Path to input file
- `outputPath`: Path to output file
- `level`: Compression level (default: `.default`)
- `progress`: Optional progress callback (default: `nil`)

**Throws**: `ZLibError` on failure

**Example**:

```swift
try ZLib.compressFile(
    from: "input.txt",
    to: "output.gz",
    level: .best,
    progress: { progress in
        print("Compression: \(Int(progress * 100))%")
    }
)
```

#### compressFileAsync(from:to:level:progress:)

```swift
static func compressFileAsync(
    from inputPath: String,
    to outputPath: String,
    level: CompressionLevel = .default,
    progress: ((Double) -> Void)? = nil
) async throws
```

**Description**: Asynchronously compresses a file.

#### compressFilePublisher(from:to:level:)

```swift
static func compressFilePublisher(
    from inputPath: String,
    to outputPath: String,
    level: CompressionLevel = .default
) -> AnyPublisher<Void, ZLibError>
```

**Description**: Returns a Combine publisher for file compression.

#### decompressFile(from:to:progress:)

```swift
static func decompressFile(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) throws
```

**Description**: Decompresses a file with progress reporting.

**Parameters**:

- `inputPath`: Path to compressed file
- `outputPath`: Path to output file
- `progress`: Optional progress callback (default: `nil`)

**Throws**: `ZLibError` on failure

**Example**:

```swift
try ZLib.decompressFile(
    from: "output.gz",
    to: "decompressed.txt",
    progress: { progress in
        print("Decompression: \(Int(progress * 100))%")
    }
)
```

#### decompressFileAsync(from:to:progress:)

```swift
static func decompressFileAsync(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) async throws
```

**Description**: Asynchronously decompresses a file.

#### decompressFilePublisher(from:to:)

```swift
static func decompressFilePublisher(
    from inputPath: String,
    to outputPath: String
) -> AnyPublisher<Void, ZLibError>
```

**Description**: Returns a Combine publisher for file decompression.

### Progress Publishers

#### progressPublisher

```swift
var progressPublisher: AnyPublisher<Double, Never>
```

**Description**: Publisher that emits progress updates during file operations.

**Example**:

```swift
ZLib.compressFilePublisher(from: "input.txt", to: "output.gz")
    .progressPublisher
    .sink { progress in
        print("Progress: \(Int(progress * 100))%")
    }
    .store(in: &cancellables)
```

## Streaming Types

### StreamingConfig

```swift
struct StreamingConfig {
    let chunkSize: Int
    let compressionLevel: CompressionLevel
    let compressionStrategy: CompressionStrategy
    let memoryLevel: MemoryLevel
    let enableLogging: Bool
}
```

**Description**: Configuration for streaming operations.

**Properties**:

- `chunkSize`: Size of data chunks for processing
- `compressionLevel`: Compression level for operations
- `compressionStrategy`: Compression strategy
- `memoryLevel`: Memory usage level
- `enableLogging`: Whether to enable debug logging

**Example**:

```swift
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    compressionLevel: .best,
    compressionStrategy: .default,
    memoryLevel: .default,
    enableLogging: false
)
```

### ZLibStream

```swift
class ZLibStream {
    let config: StreamingConfig

    init(config: StreamingConfig)
}
```

**Description**: Main streaming interface for compression and decompression.

#### compress(\_:)

```swift
func compress(_ data: Data) throws -> Data
```

**Description**: Compresses a chunk of data.

**Parameters**:

- `data`: Data chunk to compress

**Returns**: Compressed data

**Throws**: `ZLibError` on compression failure

#### decompress(\_:)

```swift
func decompress(_ data: Data) throws -> Data
```

**Description**: Decompresses a chunk of data.

**Parameters**:

- `data`: Compressed data chunk

**Returns**: Decompressed data

**Throws**: `ZLibError` on decompression failure

#### finish()

```swift
func finish() throws -> Data
```

**Description**: Finalizes compression/decompression and returns remaining data.

**Returns**: Final compressed/decompressed data

**Throws**: `ZLibError` on failure

#### compressFile(from:to:progress:)

```swift
func compressFile(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) throws
```

**Description**: Compresses a file using streaming.

**Parameters**:

- `inputPath`: Path to input file
- `outputPath`: Path to output file
- `progress`: Optional progress callback

**Throws**: `ZLibError` on failure

#### decompressFile(from:to:progress:)

```swift
func decompressFile(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) throws
```

**Description**: Decompresses a file using streaming.

**Parameters**:

- `inputPath`: Path to compressed file
- `outputPath`: Path to output file
- `progress`: Optional progress callback

**Throws**: `ZLibError` on failure

## Async Types

### AsyncZLibStream

```swift
class AsyncZLibStream {
    let config: StreamingConfig

    init(config: StreamingConfig)
}
```

**Description**: Async streaming interface for compression and decompression.

#### compressFile(from:to:progress:)

```swift
func compressFile(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) async throws
```

**Description**: Asynchronously compresses a file using streaming.

#### decompressFile(from:to:progress:)

```swift
func decompressFile(
    from inputPath: String,
    to outputPath: String,
    progress: ((Double) -> Void)? = nil
) async throws
```

**Description**: Asynchronously decompresses a file using streaming.

## Combine Publishers

### Compression Publishers

#### compressPublisher(data:level:strategy:dictionary:)

```swift
static func compressPublisher(
    data: Data,
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) -> AnyPublisher<Data, ZLibError>
```

**Description**: Publisher for data compression.

#### compressPublisher(string:level:strategy:dictionary:)

```swift
static func compressPublisher(
    string: String,
    level: CompressionLevel = .default,
    strategy: CompressionStrategy = .default,
    dictionary: Data? = nil
) -> AnyPublisher<Data, ZLibError>
```

**Description**: Publisher for string compression.

#### decompressPublisher(data:)

```swift
static func decompressPublisher(data: Data) -> AnyPublisher<Data, ZLibError>
```

**Description**: Publisher for data decompression.

#### decompressPublisher(string:)

```swift
static func decompressPublisher(string: String) -> AnyPublisher<String, ZLibError>
```

**Description**: Publisher for string decompression.

### File Operation Publishers

#### compressFilePublisher(from:to:level:)

```swift
static func compressFilePublisher(
    from inputPath: String,
    to outputPath: String,
    level: CompressionLevel = .default
) -> AnyPublisher<Void, ZLibError>
```

**Description**: Publisher for file compression.

#### decompressFilePublisher(from:to:)

```swift
static func decompressFilePublisher(
    from inputPath: String,
    to outputPath: String
) -> AnyPublisher<Void, ZLibError>
```

**Description**: Publisher for file decompression.

## Utility Types

### GzipHeader

```swift
struct GzipHeader {
    let filename: String?
    let comment: String?
    let timestamp: Date?
    let operatingSystem: UInt8
    let extraFlags: UInt8
    let compressionLevel: UInt8
}
```

**Description**: Gzip header information.

**Properties**:

- `filename`: Original filename
- `comment`: Optional comment
- `timestamp`: File timestamp
- `operatingSystem`: OS identifier
- `extraFlags`: Additional flags
- `compressionLevel`: Compression level used

### WindowBits

```swift
enum WindowBits: Int32 {
    case raw = -15
    case zlib = 15
    case gzip = 31
}
```

**Description**: Window bits for different compression formats.

## Error Handling

### Error Recovery

All methods that can fail throw `ZLibError` with specific error cases:

- `invalidData`: Input data is corrupted or not compressed
- `insufficientMemory`: System memory is insufficient
- `streamError(ZLibStatus)`: Internal zlib stream error
- `fileError(String)`: File operation error
- `unsupportedOperation(String)`: Operation not supported

### Error Examples

```swift
do {
    let compressed = try data.compress(level: .best)
} catch ZLibError.invalidData {
    print("Invalid input data")
} catch ZLibError.insufficientMemory {
    print("Not enough memory")
} catch ZLibError.streamError(let status) {
    print("Stream error: \(status)")
} catch {
    print("Other error: \(error)")
}
```

## Performance Considerations

### Memory Usage

- Use appropriate `MemoryLevel` for your environment
- Consider chunk size for streaming operations
- Monitor memory usage for large files

### Compression Levels

- `.noCompression`: Fastest, no compression
- `.bestSpeed`: Fast compression
- `.default`: Balanced approach
- `.best`: Best compression ratio

### Strategies

- `.default`: General data
- `.filtered`: Image data
- `.huffman`: Pre-filtered data
- `.rle`: Data with runs
- `.fixed`: Small data

This API reference provides comprehensive coverage of all public SwiftZlib APIs with detailed descriptions, parameters, return values, and usage examples.
