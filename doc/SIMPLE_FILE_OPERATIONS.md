# Simple File Operations

Simple file operations provide high-performance compression and decompression using `GzipFile` for basic use cases where cancellation is not required.

## Overview

Simple file operations are designed for:

- **High performance**: Direct use of `GzipFile` for optimal speed
- **Simple use cases**: When cancellation is not needed
- **Memory efficiency**: Streaming operations with configurable buffer sizes
- **Progress tracking**: Built-in progress reporting
- **Async support**: Full async/await integration

## When to Use Simple File Operations

### ✅ Use Simple File Operations When:

- You need maximum performance
- Cancellation is not required
- Processing small to medium files
- You want simple, straightforward APIs
- You need progress tracking but don't need cancellation

### ❌ Don't Use Simple File Operations When:

- You need to cancel operations
- Processing very large files that might need cancellation
- You need advanced features like throttling or custom progress objects
- You need fine-grained control over the compression process

## API Reference

### SimpleFileCompressor

```swift
class SimpleFileCompressor
```

Simple file compressor using `GzipFile` for optimal performance.

> **Note:** This operation cannot be cancelled.

#### Initialization

```swift
init(bufferSize: Int = 64 * 1024, compressionLevel: CompressionLevel = .defaultCompression)
```

**Parameters:**

- `bufferSize`: Buffer size for processing (default: 64KB)
- `compressionLevel`: Compression level (default: .defaultCompression)

#### Methods

```swift
// Synchronous compression
func compressFile(from sourcePath: String, to destinationPath: String) throws

// Synchronous compression with progress
func compressFile(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) throws

// Async compression
func compressFile(from sourcePath: String, to destinationPath: String) async throws

// Async compression with progress
func compressFile(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) async throws
```

### SimpleFileDecompressor

```swift
class SimpleFileDecompressor
```

Simple file decompressor using `GzipFile` for optimal performance.

> **Note:** This operation cannot be cancelled.

#### Initialization

```swift
init(bufferSize: Int = 64 * 1024)
```

**Parameters:**

- `bufferSize`: Buffer size for processing (default: 64KB)

#### Methods

```swift
// Synchronous decompression
func decompressFile(from sourcePath: String, to destinationPath: String) throws

// Synchronous decompression with progress
func decompressFile(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) throws

// Async decompression
func decompressFile(from sourcePath: String, to destinationPath: String) async throws

// Async decompression with progress
func decompressFile(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) async throws
```

### Convenience Methods

```swift
// Simple compression
static func compressFileSimple(from sourcePath: String, to destinationPath: String) throws
static func compressFileSimple(from sourcePath: String, to destinationPath: String, bufferSize: Int, compressionLevel: CompressionLevel) throws

// Simple decompression
static func decompressFileSimple(from sourcePath: String, to destinationPath: String) throws
static func decompressFileSimple(from sourcePath: String, to destinationPath: String, bufferSize: Int) throws

// With progress tracking
static func compressFileSimple(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) throws
static func decompressFileSimple(from sourcePath: String, to destinationPath: String, progress: @escaping (Int, Int) -> Void) throws

// Async versions
static func compressFileSimpleAsync(from sourcePath: String, to destinationPath: String) async throws
static func decompressFileSimpleAsync(from sourcePath: String, to destinationPath: String) async throws
```

## Usage Examples

### Basic Compression

```swift
// Simple compression
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")

// With custom settings
try ZLib.compressFileSimple(
    from: "input.txt",
    to: "output.gz",
    bufferSize: 128 * 1024,  // 128KB buffer
    compressionLevel: .best   // Best compression
)
```

### Basic Decompression

```swift
// Simple decompression
try ZLib.decompressFileSimple(from: "output.gz", to: "decompressed.txt")

// With custom buffer size
try ZLib.decompressFileSimple(
    from: "output.gz",
    to: "decompressed.txt",
    bufferSize: 256 * 1024  // 256KB buffer
)
```

### With Progress Tracking

```swift
// Compression with progress
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz") { processed, total in
    let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
    print("Compression progress: \(percentage)%")
}

// Decompression with progress
try ZLib.decompressFileSimple(from: "output.gz", to: "decompressed.txt") { processed, total in
    let percentage = total > 0 ? Double(processed) / Double(total) * 100 : 0
    print("Decompression progress: \(percentage)%")
}
```

### Async Operations

```swift
// Async compression
try await ZLib.compressFileSimpleAsync(from: "input.txt", to: "output.gz")

// Async decompression
try await ZLib.decompressFileSimpleAsync(from: "output.gz", to: "decompressed.txt")
```

### Direct Class Usage

```swift
// Using SimpleFileCompressor directly
let compressor = SimpleFileCompressor(bufferSize: 64 * 1024, compressionLevel: .best)
try compressor.compressFile(from: "input.txt", to: "output.gz")

// Using SimpleFileDecompressor directly
let decompressor = SimpleFileDecompressor(bufferSize: 64 * 1024)
try decompressor.decompressFile(from: "output.gz", to: "decompressed.txt")
```

## Performance Characteristics

### Advantages

- **High Performance**: Direct use of `GzipFile` for optimal speed
- **Memory Efficient**: Streaming operations with configurable buffer sizes
- **Simple API**: Easy to use with minimal configuration
- **Progress Tracking**: Built-in progress reporting
- **Async Support**: Full async/await integration

### Limitations

- **Non-Cancellable**: Operations cannot be cancelled once started
- **Limited Control**: Less fine-grained control compared to chunked operations
- **No Advanced Features**: No throttling, custom progress objects, or advanced configuration

## Comparison with Other File Operations

| Feature               | Simple File Operations | Chunked File Operations |
| --------------------- | ---------------------- | ----------------------- |
| **Performance**       | ⭐⭐⭐⭐⭐ High        | ⭐⭐⭐⭐ Good           |
| **Cancellation**      | ❌ No                  | ✅ Yes                  |
| **Memory Usage**      | ⭐⭐⭐⭐ Low           | ⭐⭐⭐⭐⭐ Very Low     |
| **API Complexity**    | ⭐⭐⭐⭐⭐ Simple      | ⭐⭐⭐ Moderate         |
| **Progress Tracking** | ✅ Yes                 | ✅ Yes                  |
| **Async Support**     | ✅ Yes                 | ✅ Yes                  |
| **Advanced Features** | ❌ No                  | ✅ Yes                  |

## Error Handling

Simple file operations throw `ZLibError` for various error conditions:

```swift
do {
    try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")
} catch ZLibError.fileError(let underlyingError) {
    print("File operation failed: \(underlyingError)")
} catch ZLibError.compressionError(let message) {
    print("Compression failed: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Best Practices

### 1. Choose the Right Tool

```swift
// Use simple operations for basic needs
if needsCancellation {
    // Use FileChunkedCompressor
    let compressor = FileChunkedCompressor()
    try compressor.compressFile(at: "input.txt", to: "output.gz")
} else {
    // Use simple operations for better performance
    try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")
}
```

### 2. Configure Buffer Sizes Appropriately

```swift
// For small files, use smaller buffers
try ZLib.compressFileSimple(
    from: "small.txt",
    to: "small.gz",
    bufferSize: 16 * 1024  // 16KB
)

// For large files, use larger buffers
try ZLib.compressFileSimple(
    from: "large.txt",
    to: "large.gz",
    bufferSize: 256 * 1024  // 256KB
)
```

### 3. Handle Progress Updates Efficiently

```swift
// Update UI on main queue
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz") { processed, total in
    DispatchQueue.main.async {
        let percentage = total > 0 ? Double(processed) / Double(total) : 0
        self.progressView.progress = Float(percentage)
    }
}
```

### 4. Use Async Operations for Better UX

```swift
// Don't block the main thread
Task {
    do {
        try await ZLib.compressFileSimpleAsync(from: "input.txt", to: "output.gz")
        await MainActor.run {
            self.showSuccessMessage()
        }
    } catch {
        await MainActor.run {
            self.showErrorMessage(error)
        }
    }
}
```

## Migration from Chunked Operations

If you're currently using chunked operations but don't need cancellation:

```swift
// Before (chunked operations)
let compressor = FileChunkedCompressor()
try compressor.compressFile(at: "input.txt", to: "output.gz")

// After (simple operations) - better performance
try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")
```

## Troubleshooting

### Common Issues

1. **File Not Found**: Ensure source files exist and are readable
2. **Permission Denied**: Check file permissions and directory access
3. **Disk Space**: Ensure sufficient disk space for output files
4. **Invalid Gzip Format**: Ensure input files are valid gzip format for decompression

### Debug Tips

```swift
// Enable verbose logging for debugging
ZLibVerboseConfig.enableAll()

// Check file existence before operations
let fileManager = FileManager.default
if fileManager.fileExists(atPath: "input.txt") {
    try ZLib.compressFileSimple(from: "input.txt", to: "output.gz")
} else {
    print("Input file does not exist")
}
```

---

For more advanced file operations with cancellation support, see [Chunked File Operations](STREAMING.md#chunked-file-operations).
