# Gzip Support

SwiftZlib provides comprehensive gzip support including header handling, metadata management, and file operations.

## Overview

Gzip is a file format that uses the DEFLATE compression algorithm with additional metadata headers. SwiftZlib supports:

- Gzip header creation and parsing
- Metadata extraction (filename, comment, timestamp)
- Automatic gzip format detection
- File operations with gzip headers
- Streaming gzip compression/decompression

## Gzip Header Structure

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

### Header Creation

```swift
// Create a basic gzip header
let header = GzipHeader(
    filename: "example.txt",
    comment: "Compressed with SwiftZlib",
    timestamp: Date(),
    operatingSystem: 3, // Unix
    extraFlags: 0,
    compressionLevel: 6
)

// Create header from existing file
let fileHeader = GzipHeader(
    filename: "data.json",
    timestamp: Date(),
    operatingSystem: 3
)
```

## Basic Gzip Operations

### Compression with Gzip Header

```swift
// Compress data with gzip header
let data = "Hello, World!".data(using: .utf8)!
let compressed = try data.compressGzip(
    filename: "hello.txt",
    comment: "Test compression"
)

// Compress with custom header
let header = GzipHeader(
    filename: "custom.txt",
    comment: "Custom header",
    timestamp: Date(),
    operatingSystem: 3
)
let customCompressed = try data.compressGzip(header: header)
```

### Decompression with Header Extraction

```swift
// Decompress and extract header information
let decompressed = try compressed.decompressGzip()

// Access header information
if let gzipData = compressed as? GzipData {
    print("Filename: \(gzipData.header.filename ?? "None")")
    print("Comment: \(gzipData.header.comment ?? "None")")
    print("Timestamp: \(gzipData.header.timestamp ?? Date())")
    print("OS: \(gzipData.header.operatingSystem)")
}
```

## File Operations

### Gzip File Compression

```swift
// Compress file with gzip header
try ZLib.compressFileGzip(
    from: "input.txt",
    to: "output.gz",
    filename: "input.txt",
    comment: "Compressed file"
)

// Compress with custom header
let header = GzipHeader(
    filename: "data.csv",
    comment: "CSV data compressed",
    timestamp: Date(),
    operatingSystem: 3
)

try ZLib.compressFileGzip(
    from: "data.csv",
    to: "data.gz",
    header: header
)
```

### Gzip File Decompression

```swift
// Decompress gzip file
try ZLib.decompressFileGzip(
    from: "output.gz",
    to: "decompressed.txt"
)

// Decompress with header extraction
let gzipInfo = try ZLib.decompressFileGzipWithHeader(
    from: "output.gz",
    to: "decompressed.txt"
)

print("Original filename: \(gzipInfo.header.filename ?? "Unknown")")
print("Compression comment: \(gzipInfo.header.comment ?? "None")")
print("Original timestamp: \(gzipInfo.header.timestamp ?? Date())")
```

## Streaming Gzip Operations

### Streaming Compression

```swift
let config = StreamingConfig(
    chunkSize: 64 * 1024,
    compressionLevel: .best
)

let stream = ZLibStream(config: config)

// Start gzip compression with header
try stream.startGzipCompression(
    filename: "streaming-data.txt",
    comment: "Streaming compression test"
)

// Process data in chunks
for chunk in dataChunks {
    let compressed = try stream.compress(chunk)
    // Send compressed data
}

// Finish compression
let final = try stream.finish()
```

### Streaming Decompression

```swift
let stream = ZLibStream(config: config)

// Start gzip decompression
let header = try stream.startGzipDecompression()

print("Gzip header extracted:")
print("  Filename: \(header.filename ?? "None")")
print("  Comment: \(header.comment ?? "None")")
print("  Timestamp: \(header.timestamp ?? Date())")

// Process compressed data
for compressedChunk in compressedChunks {
    let decompressed = try stream.decompress(compressedChunk)
    // Process decompressed data
}
```

## Metadata Handling

### Header Information Extraction

```swift
// Extract header without decompressing
let header = try ZLib.extractGzipHeader(from: "file.gz")

print("Gzip file information:")
print("  Filename: \(header.filename ?? "None")")
print("  Comment: \(header.comment ?? "None")")
print("  Timestamp: \(header.timestamp ?? Date())")
print("  OS: \(header.operatingSystem)")
print("  Extra flags: \(header.extraFlags)")
print("  Compression level: \(header.compressionLevel)")
```

### Header Validation

```swift
func validateGzipHeader(_ header: GzipHeader) -> Bool {
    // Check timestamp validity
    if let timestamp = header.timestamp {
        let now = Date()
        let timeDifference = now.timeIntervalSince(timestamp)
        
        // Timestamp should not be in the future
        if timeDifference < 0 {
            return false
        }
        
        // Timestamp should not be too old (e.g., > 100 years)
        if timeDifference > 3153600000 { // 100 years in seconds
            return false
        }
    }
    
    // Check operating system
    let validOS: [UInt8] = [0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    if !validOS.contains(header.operatingSystem) {
        return false
    }
    
    // Check compression level
    if header.compressionLevel > 9 {
        return false
    }
    
    return true
}
```

## Advanced Features

### Custom Header Creation

```swift
// Create header with specific metadata
let customHeader = GzipHeader(
    filename: "custom-data.bin",
    comment: "Generated on \(Date())",
    timestamp: Date(),
    operatingSystem: 3, // Unix
    extraFlags: 2,      // Maximum compression
    compressionLevel: 9  // Best compression
)

// Compress with custom header
let compressed = try data.compressGzip(header: customHeader)
```

### Header Modification

```swift
// Extract existing header
let originalHeader = try ZLib.extractGzipHeader(from: "original.gz")

// Create modified header
let modifiedHeader = GzipHeader(
    filename: originalHeader.filename,
    comment: "Modified: \(originalHeader.comment ?? "")",
    timestamp: Date(), // Update timestamp
    operatingSystem: originalHeader.operatingSystem,
    extraFlags: originalHeader.extraFlags,
    compressionLevel: originalHeader.compressionLevel
)

// Recompress with modified header
let originalData = try ZLib.decompressFileGzip(from: "original.gz")
try ZLib.compressFileGzip(
    from: originalData,
    to: "modified.gz",
    header: modifiedHeader
)
```

### Batch Processing with Headers

```swift
func processGzipFiles(_ files: [String]) async throws {
    for file in files {
        // Extract header information
        let header = try ZLib.extractGzipHeader(from: file)
        
        print("Processing \(file):")
        print("  Original filename: \(header.filename ?? "Unknown")")
        print("  Comment: \(header.comment ?? "None")")
        
        // Decompress with header preservation
        let outputFile = file.replacingOccurrences(of: ".gz", with: "")
        try ZLib.decompressFileGzip(from: file, to: outputFile)
        
        // Optionally recompress with updated header
        let updatedHeader = GzipHeader(
            filename: header.filename,
            comment: "Processed on \(Date())",
            timestamp: Date(),
            operatingSystem: header.operatingSystem,
            extraFlags: header.extraFlags,
            compressionLevel: header.compressionLevel
        )
        
        try ZLib.compressFileGzip(
            from: outputFile,
            to: "processed_\(file)",
            header: updatedHeader
        )
    }
}
```

## Error Handling

### Gzip-Specific Errors

```swift
func handleGzipErrors(_ data: Data) {
    do {
        let decompressed = try data.decompressGzip()
    } catch ZLibError.invalidGzipHeader {
        print("Invalid gzip header")
    } catch ZLibError.corruptedGzipData {
        print("Gzip data is corrupted")
    } catch ZLibError.incompleteGzipData {
        print("Gzip data is incomplete")
    } catch {
        print("Other error: \(error)")
    }
}
```

### Header Validation

```swift
func validateGzipFile(_ filePath: String) throws -> Bool {
    do {
        let header = try ZLib.extractGzipHeader(from: filePath)
        
        // Validate header
        guard validateGzipHeader(header) else {
            throw ZLibError.invalidGzipHeader
        }
        
        // Test decompression
        let testData = try ZLib.decompressFileGzip(from: filePath)
        
        return true
    } catch {
        print("Gzip validation failed: \(error)")
        return false
    }
}
```

## Best Practices

### 1. Header Information

```swift
// Always include meaningful header information
let header = GzipHeader(
    filename: originalFilename,
    comment: "Compressed with SwiftZlib v1.0",
    timestamp: Date(),
    operatingSystem: 3 // Unix
)

// Use descriptive comments
let descriptiveHeader = GzipHeader(
    filename: "user-data.json",
    comment: "User profile data, compressed on \(Date())",
    timestamp: Date()
)
```

### 2. File Naming

```swift
// Preserve original filename in header
let originalName = "data.csv"
let compressedName = "\(originalName).gz"

try ZLib.compressFileGzip(
    from: originalName,
    to: compressedName,
    filename: originalName // Preserve original name
)
```

### 3. Error Recovery

```swift
func safeGzipDecompression(_ filePath: String) throws -> Data {
    do {
        return try ZLib.decompressFileGzip(from: filePath)
    } catch ZLibError.invalidGzipHeader {
        // Try without gzip header (raw deflate)
        return try ZLib.decompressFile(from: filePath)
    } catch {
        throw error
    }
}
```

### 4. Metadata Preservation

```swift
func compressWithMetadata(_ filePath: String) throws {
    let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
    let creationDate = fileAttributes[.creationDate] as? Date ?? Date()
    
    let header = GzipHeader(
        filename: URL(fileURLWithPath: filePath).lastPathComponent,
        comment: "Original creation: \(creationDate)",
        timestamp: creationDate,
        operatingSystem: 3
    )
    
    let outputPath = "\(filePath).gz"
    try ZLib.compressFileGzip(
        from: filePath,
        to: outputPath,
        header: header
    )
}
```

## Performance Considerations

### Streaming for Large Files

```swift
func compressLargeFileGzip(_ inputPath: String, _ outputPath: String) throws {
    let config = StreamingConfig(
        chunkSize: 256 * 1024, // 256KB chunks
        compressionLevel: .best
    )
    
    let stream = ZLibStream(config: config)
    
    try stream.startGzipCompression(
        filename: URL(fileURLWithPath: inputPath).lastPathComponent,
        comment: "Large file compression"
    )
    
    try stream.compressFile(from: inputPath, to: outputPath)
}
```

### Memory-Efficient Processing

```swift
func processGzipFilesEfficiently(_ files: [String]) async throws {
    let config = StreamingConfig(
        chunkSize: 64 * 1024,
        memoryLevel: .min
    )
    
    for file in files {
        let stream = ZLibStream(config: config)
        
        // Extract header without full decompression
        let header = try ZLib.extractGzipHeader(from: file)
        
        // Process with minimal memory usage
        try await stream.decompressFileGzip(
            from: file,
            to: "processed_\(file)",
            progress: { progress in
                print("Processing \(file): \(Int(progress * 100))%")
            }
        )
    }
}
```

This gzip support documentation provides comprehensive coverage of gzip header handling, metadata management, file operations, and best practices for working with gzip files in SwiftZlib. 