# SwiftZlib Architecture

## Overview

SwiftZlib is a comprehensive Swift wrapper for the ZLib compression library, designed with a layered architecture that provides both high-level convenience APIs and low-level streaming capabilities. The architecture follows modern Swift design patterns and provides multiple abstraction levels to suit different use cases.

## Architecture Layers

### 1. C Bridge Layer (`CZLib`)

- **Purpose**: Direct interface to the zlib C library
- **Components**:
  - `zlib_shim.c`: C wrapper functions
  - `zlib_shim.h`: Header declarations
  - `module.modulemap`: Swift module interface
- **Responsibilities**:
  - Raw C function calls
  - Memory management
  - Error code translation
  - Type bridging between C and Swift

### 2. Core Compression Layer (`Core/`)

- **Purpose**: Low-level compression and decompression primitives
- **Components**:
  - `Compressor.swift`: Deflate compression stream
  - `Decompressor.swift`: Inflate decompression stream
  - `InflateBackDecompressor.swift`: Advanced callback-based decompression
  - `ZLibStream.swift`: Unified stream interface
  - `ZLibError.swift`: Error handling and recovery
- **Responsibilities**:
  - Stream initialization and management
  - Data processing with configurable parameters
  - Error handling and recovery
  - Memory-efficient streaming operations

### 3. Configuration Layer (`Core/`)

- **Purpose**: Parameter management and validation
- **Components**:
  - `CompressionLevel.swift`: Compression quality settings
  - `CompressionMethod.swift`: Algorithm selection
  - `CompressionStrategy.swift`: Optimization strategies
  - `WindowBits.swift`: Format and window size configuration
  - `MemoryLevel.swift`: Memory usage optimization
  - `FlushMode.swift`: Stream control operations
- **Responsibilities**:
  - Parameter validation
  - Default configuration management
  - Performance optimization settings

### 4. File Operations Layer (`FileOperations/`)

- **Purpose**: File-based compression and decompression
- **Components**:
  - `FileCompressor.swift`: Simple file compression
  - `FileDecompressor.swift`: Simple file decompression
  - `FileChunkedCompressor.swift`: Memory-efficient streaming compression
  - `FileChunkedDecompressor.swift`: Memory-efficient streaming decompression
  - `FileProcessor.swift`: Auto-detection and processing
  - `GzipFile.swift`: Gzip file format support
- **Responsibilities**:
  - File I/O management
  - Progress tracking
  - Memory-efficient processing of large files
  - Format auto-detection

### 5. Async/Concurrency Layer (`Async/`)

- **Purpose**: Modern Swift concurrency support
- **Components**:
  - `AsyncCompressor.swift`: Async compression streams
  - `AsyncDecompressor.swift`: Async decompression streams
  - `AsyncZLibStream.swift`: Unified async stream interface
  - `AsyncZLibStreamBuilder.swift`: Fluent async API builder
- **Responsibilities**:
  - Async/await support
  - Structured concurrency
  - Non-blocking operations
  - Task management

### 6. Combine Integration Layer (`API/ZLib+Combine.swift`)

- **Purpose**: Reactive programming support
- **Components**:
  - Publisher implementations for all operations
  - Progress reporting publishers
  - Error handling publishers
- **Responsibilities**:
  - Combine publisher creation
  - Reactive data flow
  - Progress monitoring
  - Cancellation support

### 7. High-Level API Layer (`API/`)

- **Purpose**: Simple, one-line operations
- **Components**:
  - `ZLib.swift`: Main convenience methods
  - `ZLib+Async.swift`: Async convenience methods
  - `ZLib+File.swift`: File operation convenience methods
  - `ZLib+FileChunked.swift`: Chunked file operations
  - `Data+Extensions.swift`: Data type extensions
  - `String+Extensions.swift`: String type extensions
- **Responsibilities**:
  - Simple API design
  - Automatic parameter selection
  - Type-safe operations
  - Convenience method chaining

## Detailed Architecture Diagrams

### 1. High-Level Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SwiftZlib Architecture                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   High-Level    │  │   File Ops      │  │   Async/Combine │            │
│  │     API         │  │   Layer         │  │   Layer         │            │
│  │                 │  │                 │  │                 │            │
│  │ • ZLib.swift    │  │ • FileCompressor│  │ • AsyncCompressor│            │
│  │ • ZLib+Async    │  │ • FileDecompressor│ │ • AsyncDecompressor│        │
│  │ • ZLib+File     │  │ • FileChunked   │  │ • AsyncZLibStream│          │
│  │ • ZLib+Combine  │  │ • FileProcessor │  │ • Combine Publishers│        │
│  │ • Data+Extensions│ │ • GzipFile      │  │ • Progress Tracking│         │
│  │ • String+Extensions│ │ • Progress Callbacks│ │ • Cancellation Support│   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│           │                       │                       │                │
│           └───────────────────────┼───────────────────────┘                │
│                                   │                                        │
│                    ┌─────────────────┐                                    │
│                    │   Core Layer    │                                    │
│                    │                 │                                    │
│                    │ • Compressor    │                                    │
│                    │ • Decompressor  │                                    │
│                    │ • InflateBack   │                                    │
│                    │ • ZLibStream    │                                    │
│                    │ • ZLibError     │                                    │
│                    │ • Configuration │                                    │
│                    │   Classes       │                                    │
│                    └─────────────────┘                                    │
│                                   │                                        │
│                    ┌─────────────────┐                                    │
│                    │   C Bridge      │                                    │
│                    │   Layer         │                                    │
│                    │                 │                                    │
│                    │ • zlib_shim.c   │                                    │
│                    │ • zlib_shim.h   │                                    │
│                    │ • module.modulemap│                                  │
│                    └─────────────────┘                                    │
│                                   │                                        │
│                    ┌─────────────────┐                                    │
│                    │   ZLib C        │                                    │
│                    │   Library       │                                    │
│                    │                 │                                    │
│                    │ • deflate       │                                    │
│                    │ • inflate       │                                    │
│                    │ • checksums     │                                    │
│                    │ • utilities     │                                    │
│                    └─────────────────┘                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2. Data Flow Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Input Data    │    │   Processing    │    │   Output Data   │
│                 │    │   Pipeline      │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Raw Data      │───▶│ • Compression   │───▶│ • Compressed    │
│ • File Path     │    │ • Decompression │    │ • Decompressed  │
│ • Stream Data   │    │ • Streaming     │    │ • Progress Info │
│ • Async Data    │    │ • Async/Combine │    │ • Error Info    │
│ • Combine Data  │    │ • Error Handling│    │ • Status Info   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Validation    │    │   Processing    │    │   Validation    │
│   Layer         │    │   Engine        │    │   Layer         │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Type Checking │    │ • Core ZLib     │    │ • Output Format │
│ • Size Limits   │    │ • Memory Mgmt   │    │ • Error Codes   │
│ • Format Detect │    │ • Buffer Mgmt   │    │ • Progress Calc │
│ • Error Detect  │    │ • Stream Mgmt   │    │ • Status Report │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 3. Class Relationship Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ZLib (Enum)   │    │   Compressor    │    │ Decompressor    │
│                 │    │                 │    │                 │
│ • compress()    │◄───┤ • initialize()  │    │ • initialize()  │
│ • decompress()  │    │ • compress()    │    │ • decompress()  │
│ • compressFile()│    │ • reset()       │    │ • reset()       │
│ • decompressFile()│  │ • setDictionary()│   │ • setDictionary()│
│ • compressAsync()│   │ • setGzipHeader()│   │ • getGzipHeader()│
│ • decompressAsync()│ │ • getBound()    │    │ • sync()        │
│ • compressPublisher()│ │ • copy()       │    │ • copy()        │
│ • decompressPublisher()│ • tune()      │    │ • prime()       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ InflateBack     │    │ FileCompressor   │
         │              │ Decompressor    │    │                 │
         │              │                 │    │ • compressFile()│
         │              │ • initialize()  │    │ • compressFileToMemory()│
         │              │ • processData() │    │ • progress callback│
         │              │ • callbacks     │    │                 │
         │              │ • C bridging    │    └─────────────────┘
         │              └─────────────────┘              │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   FileChunked   │    │   FileChunked   │    │   FileProcessor │
│   Compressor    │    │   Decompressor  │    │                 │
│                 │    │                 │    │ • processFile() │
│ • compressFile()│    │ • decompressFile()│  │ • auto-detect   │
│ • progress      │    │ • progress      │    │ • format detect │
│ • async         │    │ • async         │    │ • compression   │
│ • streaming     │    │ • streaming     │    │ • decompression │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 4. API Usage Patterns

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           API Usage Patterns                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Simple API (One-liner)                                                 │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ let compressed = try ZLib.compress(data)                          │ │
│     │ let decompressed = try ZLib.decompress(compressed)                │ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  2. File Operations                                                        │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ try ZLib.compressFile(from: "input.txt", to: "output.gz")        │ │
│     │ try ZLib.decompressFile(from: "input.gz", to: "output.txt")      │ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  3. Async/Await                                                            │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ let compressed = try await ZLib.compressAsync(data)               │ │
│     │ try await ZLib.compressFileAsync(from: "input.txt", to: "output.gz")│ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  4. Combine Publishers                                                     │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ ZLib.compressPublisher(data)                                       │ │
│     │   .sink(receiveCompletion: { ... }, receiveValue: { ... })        │ │
│     │   .store(in: &cancellables)                                       │ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  5. Progress Tracking                                                      │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ ZLib.compressFileProgressPublisher(from: "input.txt", to: "output.gz")│ │
│     │   .sink(receiveValue: { progress in                                │ │
│     │     print("Progress: \(progress.percent)%")                        │ │
│     │   })                                                               │ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  6. Advanced Streaming                                                     │
│     ┌─────────────────────────────────────────────────────────────────────┐ │
│     │ let compressor = Compressor()                                      │ │
│     │ try compressor.initialize(level: .bestCompression)                 │ │
│     │ let compressed = try compressor.compress(data, flush: .finish)    │ │
│     └─────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5. Error Handling Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Input Error   │    │   Error         │    │   Error         │
│   Detection     │    │   Processing    │    │   Recovery      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • C Error Code  │───▶│ • ZLibError     │───▶│ • Recovery      │
│ • Swift Error   │    │ • Error Context │    │ • Retry Logic   │
│ • System Error  │    │ • Error Details │    │ • Fallback      │
│ • Validation    │    │ • Error Chain   │    │ • User Message  │
│ • Type Error    │    │ • Error Code    │    │ • Debug Info    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Error Types   │    │   Error         │    │   Error         │
│                 │    │   Categories    │    │   Actions       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • ZLibError     │    │ • Compression   │    │ • Retry         │
│ • FileError     │    │ • Decompression │    │ • Reset         │
│ • MemoryError   │    │ • File I/O      │    │ • Fallback      │
│ • ConfigError   │    │ • Memory        │    │ • Abort         │
│ • SystemError   │    │ • Validation    │    │ • Log           │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 6. Memory Management Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Memory        │    │   Memory        │    │   Memory        │
│   Allocation    │    │   Usage         │    │   Cleanup       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Buffer Alloc  │───▶│ • Data Processing│───▶│ • Buffer Free   │
│ • Stream Init   │    │ • Compression   │    │ • Stream End    │
│ • Context Setup │    │ • Decompression │    │ • Context Clean │
│ • Dictionary    │    │ • Streaming     │    │ • Memory Reset  │
│ • Progress      │    │ • Progress      │    │ • Error Cleanup │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Memory        │    │   Memory        │    │   Memory        │
│   Monitoring    │    │   Optimization  │    │   Validation    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Usage Tracking│    │ • Buffer Sizing │    │ • Leak Detection│
│ • Pressure Check│    │ • Level Tuning  │    │ • Cleanup Verify│
│ • Performance   │    │ • Strategy Opt  │    │ • Resource Check│
│ • Limits        │    │ • Memory Levels │    │ • Final Check   │
│ • Alerts        │    │ • Auto-tuning   │    │ • Report        │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 7. Concurrency Model

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Thread        │    │   Async         │    │   Combine       │
│   Safety        │    │   Operations    │    │   Publishers    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Per-Instance  │    │ • Non-blocking  │    │ • Reactive      │
│ • No Sharing    │    │ • Structured    │    │ • Cancellable   │
│ • Independent   │    │ • Task-based    │    │ • Progress      │
│ • Synchronized  │    │ • Continuation  │    │ • Error Flow    │
│ • Isolated      │    │ • Memory Safe   │    │ • Backpressure  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Concurrency   │    │   Async         │    │   Combine       │
│   Patterns      │    │   Patterns      │    │   Patterns      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Instance Pool │    │ • Async Stream  │    │ • Publisher     │
│ • Thread Local  │    │ • Task Groups   │    │ • Subscriber    │
│ • Lock-free     │    │ • Continuation  │    │ • Operator      │
│ • Atomic        │    │ • Cancellation  │    │ • Scheduler     │
│ • Barrier       │    │ • Error Handling│    │ • Subscription  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 8. Gzip Header Memory Management

SwiftZlib includes special memory management for gzip headers to ensure safety when interfacing with zlib's C API.

**The Problem:**
Gzip headers contain optional fields (`extra`, `name`, `comment`) that require C pointers to remain valid for the entire lifetime of the compression stream:

```swift
struct GzipHeader {
    var text: Int32 = 0
    var time: UInt32 = 0
    var xflags: Int32 = 0
    var os: Int32 = 0
    var hcrc: Int32 = 0
    var done: Int32 = 0
    var extra: Data?
    var name: String?
    var comment: String?
}
```

When these Swift types are converted to C pointers for zlib, Swift's automatic memory management can deallocate the pointers prematurely, leading to use-after-free errors and segmentation faults.

**The Solution:**
SwiftZlib uses a dedicated `GzipHeaderStorage` class to manage the lifetime of gzip header memory:

```swift
final class GzipHeaderStorage {
    var cHeader: gz_header
    private var extraPtr: UnsafeMutablePointer<Bytef>?
    private var namePtr: UnsafeMutablePointer<CChar>?
    private var commentPtr: UnsafeMutablePointer<CChar>?

    init(swiftHeader: GzipHeader) {
        cHeader = gz_header()
        // Allocate and copy memory for each field
        // Store pointers for later deallocation
    }

    deinit {
        // Safely deallocate all memory
        extraPtr?.deallocate()
        namePtr?.deallocate()
        commentPtr?.deallocate()
    }
}
```

**Memory Management Flow:**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Swift         │    │   GzipHeader    │    │   Zlib C        │
│   GzipHeader    │    │   Storage       │    │   API           │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • extra: Data?  │───▶│ • extraPtr      │───▶│ • gz_header.extra│
│ • name: String? │    │ • namePtr       │    │ • gz_header.name│
│ • comment: String?│  │ • commentPtr    │    │ • gz_header.comment│
│                 │    │ • Lifetime Mgmt │    │ • Stream Usage  │
│                 │    │ • Auto Cleanup  │    │ • Memory Valid  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Memory        │    │   Memory        │    │   Memory        │
│   Allocation    │    │   Validation    │    │   Cleanup       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ • Data.copyBytes│    │ • Pointer Valid │    │ • deallocate()  │
│ • String.cString│    │ • Lifetime Check│    │ • Stream End    │
│ • Memory Alloc  │    │ • Safety Check  │    │ • Auto Cleanup  │
│ • Copy Data     │    │ • Error Detect  │    │ • Memory Free   │
│ • Store Ptrs    │    │ • Debug Output  │    │ • Final Check   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Key Benefits:**

- **Memory Safety**: Prevents use-after-free and double-free errors
- **Stream Lifetime**: Memory remains valid for the entire zlib stream
- **Single Header**: Each compressor can only have one gzip header, preventing conflicts
- **Automatic Cleanup**: Memory is deallocated when the compressor is deinitialized

**Usage Pattern:**

```swift
let compressor = Compressor()
try compressor.initializeAdvanced(level: .default, method: .deflated, windowBits: 16)

// Memory is automatically managed - no manual cleanup needed
try compressor.setGzipHeader(header)

// ... compression operations ...
// Memory is automatically freed when compressor is deallocated
```

**Error Prevention:**

- **Segmentation Faults**: Eliminated through proper memory lifetime management
- **Use-After-Free**: Prevented by maintaining strong references
- **Double-Free**: Avoided through single header enforcement
- **Memory Leaks**: Prevented through automatic cleanup in deinit

This memory management strategy ensures that gzip headers work safely across all platforms while maintaining the performance and usability of the SwiftZlib API.

## Design Patterns

### 1. Builder Pattern

Used in `AsyncZLibStreamBuilder` and `ZLibStreamBuilder` for fluent API design:

```swift
let stream = ZLib.asyncStream()
    .compress()
    .format(.gzip)
    .level(.bestCompression)
    .build()
```

### 2. Strategy Pattern

Used for compression strategies and memory levels:

```swift
let compressor = Compressor()
try compressor.initializeAdvanced(
    level: .bestCompression,
    strategy: .filtered
)
```

### 3. Factory Pattern

Used in `ZLib` convenience methods to create appropriate implementations:

```swift
// Automatically selects best implementation
let compressed = try ZLib.compress(data)
```

### 4. Observer Pattern

Used for progress tracking and Combine publishers:

```swift
// Progress callbacks
try compressor.compressFile(from: source, to: dest) { progress in
    updateUI(progress)
}

// Combine publishers
ZLib.compressFileProgressPublisher(from: source, to: dest)
    .sink(receiveValue: { progress in
        updateUI(progress)
    })
```

### 5. Adapter Pattern

Used in `InflateBackDecompressorCBridged` to bridge C callbacks to Swift:

```swift
let inflater = InflateBackDecompressorCBridged(windowBits: .raw)
try inflater.initialize()
let result = try inflater.processData(compressedData)
```

## API Design Principles

### 1. Progressive Disclosure

- **Simple API**: `ZLib.compress(data)` for basic needs
- **Advanced API**: `Compressor` class for fine-grained control
- **Expert API**: Direct C bridge for specialized use cases

### 2. Type Safety

- Strongly typed enums for all parameters
- Compile-time validation of configurations
- Clear error types with recovery suggestions

### 3. Memory Efficiency

- Streaming operations for large data
- Configurable buffer sizes
- Automatic memory management
- Progress tracking for long operations

### 4. Modern Swift Features

- Async/await support
- Combine integration
- Structured concurrency
- Error handling with detailed information

## Component Relationships

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   High-Level    │    │   File Ops      │    │   Async/Combine │
│     API         │    │   Layer         │    │   Layer         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Core Layer    │
                    │  (Compressor/   │
                    │  Decompressor)  │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   C Bridge      │
                    │   Layer         │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ZLib C        │
                    │   Library       │
                    └─────────────────┘
```

## Error Handling Architecture

### 1. Error Propagation

- C errors → `ZLibError` with detailed information
- Recovery suggestions for common errors
- Structured error types for different scenarios

### 2. Error Recovery

- Automatic retry mechanisms where appropriate
- Dictionary handling for decompression
- Stream reset capabilities
- Memory pressure handling

### 3. Error Context

- Detailed error messages
- Error code explanations
- Recovery suggestions
- Debugging information

## Performance Considerations

### 1. Memory Management

- Streaming operations for large files
- Configurable buffer sizes
- Memory pressure monitoring
- Automatic cleanup

### 2. Concurrency

- Thread-safe operations where possible
- Per-instance concurrency model
- Async/await for non-blocking operations
- Combine for reactive programming

### 3. Optimization

- Compression level selection
- Memory level configuration
- Strategy optimization
- Window size tuning

## Testing Architecture

### 1. Test Organization

- **Core Tests**: Basic functionality and edge cases
- **File Operation Tests**: File I/O and streaming
- **Async Tests**: Concurrency and async operations
- **Combine Tests**: Publisher and reactive programming
- **Performance Tests**: Benchmarks and stress testing
- **Error Tests**: Error handling and recovery

### 2. Test Coverage

- Unit tests for individual components
- Integration tests for API layers
- Performance tests for optimization
- Error injection tests for robustness

## Future Architecture Considerations

### 1. Extensibility

- Plugin architecture for custom formats
- Custom compression algorithms
- Platform-specific optimizations
- Third-party integration points

### 2. Scalability

- Distributed processing support
- Cloud storage integration
- Batch processing capabilities
- Real-time streaming

### 3. Maintainability

- Clear separation of concerns
- Comprehensive documentation
- Automated testing
- Performance monitoring

## Platform Support

### 1. macOS

- Native zlib library
- Full API support
- Performance optimizations
- Integration with system frameworks

### 2. Linux

- System zlib package
- Cross-platform compatibility
- Command-line tool support
- Server-side optimization

### 3. Future Platforms

- iOS support (if needed)
- Windows support (if needed)
- WebAssembly support (if needed)

This architecture provides a solid foundation for compression and decompression operations while maintaining flexibility for future enhancements and platform support.
