# Advanced Features

SwiftZlib provides advanced features for sophisticated compression scenarios, modern Swift concurrency, and performance optimization.

## Async/Await Support

SwiftZlib fully supports Swift's modern concurrency model with async/await.

### Async Compression

```swift
// Async data compression
let data = "Hello, World!".data(using: .utf8)!
let compressed = try await data.compressAsync(level: .best)

// Async string compression
let text = "Large text content..."
let compressedText = try await text.compressAsync(level: .bestSpeed)
```

### Async File Operations

```swift
// Async file compression with progress
try await ZLib.compressFileAsync(
    from: "input.txt",
    to: "output.gz",
    level: .best,
    progress: { progress in
        print("Compression: \(Int(progress * 100))%")
    }
)

// Async file decompression
try await ZLib.decompressFileAsync(
    from: "output.gz",
    to: "decompressed.txt"
)
```

### Async Streaming

```swift
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    compressionLevel: .best
)

let stream = AsyncZLibStream(config: config)

// Process large files asynchronously
try await stream.compressFile(
    from: "large-input.txt",
    to: "compressed.gz",
    progress: { progress in
        await MainActor.run {
            progressView.progress = Float(progress)
        }
    }
)
```

## Combine Integration

SwiftZlib provides comprehensive Combine support for reactive programming patterns.

### Data Publishers

```swift
import Combine

var cancellables = Set<AnyCancellable>()

// Compress data with Combine
ZLib.compressPublisher(data: data, level: .best)
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Compression completed")
            case .failure(let error):
                print("Compression failed: \(error)")
            }
        },
        receiveValue: { compressed in
            print("Compressed size: \(compressed.count)")
        }
    )
    .store(in: &cancellables)

// Decompress data with Combine
ZLib.decompressPublisher(data: compressedData)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { decompressed in
            print("Decompressed: \(decompressed)")
        }
    )
    .store(in: &cancellables)
```

### File Operation Publishers

```swift
// File compression with progress
ZLib.compressFilePublisher(
    from: "input.txt",
    to: "output.gz",
    level: .best
)
.sink(
    receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("File compression failed: \(error)")
        }
    },
    receiveValue: { _ in
        print("File compression completed")
    }
)
.store(in: &cancellables)

// File decompression
ZLib.decompressFilePublisher(from: "output.gz", to: "decompressed.txt")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { _ in
            print("File decompression completed")
        }
    )
    .store(in: &cancellables)
```

### Progress Publishers

```swift
// Get progress updates during compression
ZLib.compressFilePublisher(
    from: "large-file.txt",
    to: "compressed.gz",
    level: .best
)
.progressPublisher
.sink { progress in
    print("Progress: \(Int(progress * 100))%")
}
.store(in: &cancellables)
```

## Dictionary Compression

Dictionary compression allows you to provide a custom dictionary that helps compress data with common patterns.

### Basic Dictionary Usage

```swift
// Create a dictionary from common text
let dictionary = "Hello, this is a common prefix that appears frequently in our data.".data(using: .utf8)!

// Compress with dictionary
let data = "Hello, this is a common prefix that appears frequently in our data. And here is more content.".data(using: .utf8)!
let compressed = try data.compress(level: .best, dictionary: dictionary)
```

### Dictionary for Structured Data

```swift
// For JSON data with common keys
let jsonDictionary = """
{
    "id": "",
    "name": "",
    "email": "",
    "created_at": "",
    "updated_at": ""
}
""".data(using: .utf8)!

let jsonData = """
{
    "id": "123",
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2023-01-01",
    "updated_at": "2023-01-02"
}
""".data(using: .utf8)!

let compressed = try jsonData.compress(level: .best, dictionary: jsonDictionary)
```

### Dictionary for Network Protocols

```swift
// For HTTP headers
let httpDictionary = """
GET / HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0
Accept: text/html
Connection: keep-alive
""".data(using: .utf8)!

let httpRequest = """
GET /api/users HTTP/1.1
Host: api.example.com
User-Agent: MyApp/1.0
Accept: application/json
Connection: keep-alive
""".data(using: .utf8)!

let compressed = try httpRequest.compress(level: .best, dictionary: httpDictionary)
```

## Custom Compression Strategies

SwiftZlib supports different compression strategies for various data types.

### Strategy Selection

```swift
// Default strategy (good for general data)
let compressed = try data.compress(level: .best, strategy: .default)

// Filtered strategy (good for image data)
let imageData = loadImageData()
let compressed = try imageData.compress(level: .best, strategy: .filtered)

// Huffman-only strategy (good for pre-filtered data)
let filteredData = applyCustomFilter(imageData)
let compressed = try filteredData.compress(level: .best, strategy: .huffman)

// RLE strategy (good for data with runs)
let runData = generateRunData()
let compressed = try runData.compress(level: .best, strategy: .rle)

// Fixed strategy (good for small data)
let smallData = "small".data(using: .utf8)!
let compressed = try smallData.compress(level: .best, strategy: .fixed)
```

### Strategy Guidelines

| Strategy | Best For | Use Cases |
|----------|----------|-----------|
| `.default` | General data | Text, mixed content |
| `.filtered` | Image data | PNG, JPEG, raw images |
| `.huffman` | Pre-filtered data | Already processed data |
| `.rle` | Data with runs | Repeated patterns |
| `.fixed` | Small data | Headers, metadata |

## Performance Optimization

### Memory Level Configuration

```swift
// Minimal memory usage (good for mobile)
let mobileConfig = StreamingConfig(
    chunkSize: 32 * 1024,
    memoryLevel: .min
)

// Default memory usage (balanced)
let balancedConfig = StreamingConfig(
    chunkSize: 64 * 1024,
    memoryLevel: .default
)

// Maximum memory usage (good for desktop)
let desktopConfig = StreamingConfig(
    chunkSize: 256 * 1024,
    memoryLevel: .max
)
```

### Compression Level Optimization

```swift
// Fast compression for real-time applications
let realtimeConfig = StreamingConfig(
    compressionLevel: .bestSpeed
)

// Balanced compression for general use
let generalConfig = StreamingConfig(
    compressionLevel: .default
)

// Best compression for storage
let storageConfig = StreamingConfig(
    compressionLevel: .best
)
```

### Chunk Size Optimization

```swift
// Small chunks for network streaming
let networkConfig = StreamingConfig(chunkSize: 8 * 1024)

// Medium chunks for file processing
let fileConfig = StreamingConfig(chunkSize: 128 * 1024)

// Large chunks for high-throughput
let throughputConfig = StreamingConfig(chunkSize: 1024 * 1024)
```

## Advanced Error Handling

### Custom Error Types

```swift
enum CompressionError: Error {
    case invalidInput
    case insufficientMemory
    case streamError(ZLibStatus)
    case fileError(String)
}

func safeCompress(_ data: Data) throws -> Data {
    do {
        return try data.compress(level: .best)
    } catch ZLibError.invalidData {
        throw CompressionError.invalidInput
    } catch ZLibError.insufficientMemory {
        throw CompressionError.insufficientMemory
    } catch ZLibError.streamError(let status) {
        throw CompressionError.streamError(status)
    } catch {
        throw CompressionError.fileError(error.localizedDescription)
    }
}
```

### Error Recovery

```swift
func compressWithFallback(_ data: Data) -> Data {
    // Try best compression first
    do {
        return try data.compress(level: .best)
    } catch {
        // Fall back to faster compression
        do {
            return try data.compress(level: .bestSpeed)
        } catch {
            // Fall back to no compression
            return data
        }
    }
}
```

## Advanced Patterns

### Batch Processing

```swift
func compressBatch(_ files: [String]) async throws -> [String] {
    let config = StreamingConfig(
        chunkSize: 64 * 1024,
        compressionLevel: .best
    )
    
    return try await withThrowingTaskGroup(of: String.self) { group in
        for file in files {
            group.addTask {
                let output = file + ".gz"
                try await ZLib.compressFileAsync(
                    from: file,
                    to: output,
                    level: .best
                )
                return output
            }
        }
        
        var results: [String] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}
```

### Streaming with Custom Processing

```swift
class CustomStreamProcessor {
    private let stream: ZLibStream
    private let processor: (Data) -> Data
    
    init(config: StreamingConfig, processor: @escaping (Data) -> Data) {
        self.stream = ZLibStream(config: config)
        self.processor = processor
    }
    
    func processAndCompress(_ data: Data) throws -> Data {
        let processed = processor(data)
        return try stream.compress(processed)
    }
    
    func finish() throws -> Data {
        return try stream.finish()
    }
}

// Usage
let processor = CustomStreamProcessor(
    config: .default,
    processor: { data in
        // Apply custom transformation
        return data.uppercased()
    }
)

let processed = try processor.processAndCompress(inputData)
let final = try processor.finish()
```

### Memory-Efficient Processing

```swift
func processLargeFileEfficiently(input: String, output: String) throws {
    let config = StreamingConfig(
        chunkSize: 16 * 1024,  // Small chunks
        memoryLevel: .min,      // Minimal memory
        compressionLevel: .bestSpeed  // Fast compression
    )
    
    let stream = ZLibStream(config: config)
    
    let inputHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: input))
    let outputHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: output))
    
    defer {
        try? inputHandle.close()
        try? outputHandle.close()
    }
    
    while let chunk = try inputHandle.read(upToCount: 16 * 1024) {
        let compressed = try stream.compress(chunk)
        try outputHandle.write(contentsOf: compressed)
    }
    
    let final = try stream.finish()
    try outputHandle.write(contentsOf: final)
}
```

## Integration Examples

### Combine with Async

```swift
func compressWithProgress(_ data: Data) -> AnyPublisher<Double, Never> {
    let progressSubject = PassthroughSubject<Double, Never>()
    
    Task {
        do {
            let compressed = try await data.compressAsync(level: .best)
            progressSubject.send(1.0)
            progressSubject.send(completion: .finished)
        } catch {
            progressSubject.send(completion: .finished)
        }
    }
    
    return progressSubject.eraseToAnyPublisher()
}
```

### Custom Progress Reporting

```swift
class ProgressTracker {
    private let totalSize: Int
    private var processedSize: Int = 0
    private let progressCallback: (Double) -> Void
    
    init(totalSize: Int, progressCallback: @escaping (Double) -> Void) {
        self.totalSize = totalSize
        self.progressCallback = progressCallback
    }
    
    func updateProgress(_ additionalSize: Int) {
        processedSize += additionalSize
        let progress = Double(processedSize) / Double(totalSize)
        progressCallback(progress)
    }
}

func compressWithCustomProgress(_ data: Data) async throws -> Data {
    let tracker = ProgressTracker(totalSize: data.count) { progress in
        print("Progress: \(Int(progress * 100))%")
    }
    
    return try await data.compressAsync(level: .best)
}
```

This advanced features documentation covers all the sophisticated capabilities of SwiftZlib, from modern Swift concurrency to performance optimization and custom processing patterns. 