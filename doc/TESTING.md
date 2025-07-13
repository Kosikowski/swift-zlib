# Testing Guide

SwiftZlib includes a comprehensive test suite covering all functionality, edge cases, and performance scenarios.

## Test Structure

The test suite is organized into logical groups:

```
Tests/SwiftZlibTests/
├── CoreTests.swift              # Core compression/decompression
├── ExtensionsTests.swift        # Data and String extensions
├── DictionaryTests.swift        # Dictionary compression
├── StreamTests.swift            # Streaming functionality
├── ErrorHandlingTests.swift     # Error scenarios
├── AdvancedFeaturesTests.swift  # Advanced features
├── InflateBackTests.swift      # InflateBack decompression
├── UtilityTests.swift           # Utility functions
├── PrimeTests.swift            # Priming functionality
├── WindowBitsTests.swift       # Window bits configuration
├── GzipHeaderTests.swift       # Gzip header handling
├── FileOperationsTests.swift    # File operations
├── AsyncStreamTests.swift      # Async streaming
├── CombineTests.swift          # Combine integration
├── ConcurrencyTests.swift      # Concurrency scenarios
├── PerformanceTests.swift      # Performance benchmarks
└── EdgeCases/
    └── ErrorHandlingTests.swift # Additional error cases
```

## Running Tests

### Basic Test Execution

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run tests with parallel execution
swift test --parallel
```

### Running Specific Test Groups

```bash
# Run only core tests
swift test --filter CoreTests

# Run only file operation tests
swift test --filter FileOperationsTests

# Run only error handling tests
swift test --filter ErrorHandlingTests

# Run only performance tests
swift test --filter PerformanceTests
```

### Running Individual Tests

```bash
# Run a specific test method
swift test --filter "testBasicCompression"

# Run tests matching a pattern
swift test --filter "testCompress"

# Run tests excluding certain patterns
swift test --filter "testCompress" --filter-out "testError"
```

### Test Discovery

```bash
# List all available tests
swift test --list-tests

# List tests in a specific file
swift test --list-tests --filter CoreTests
```

## Writing Tests

### Basic Test Structure

```swift
import XCTest
@testable import SwiftZlib

final class MyTests: XCTestCase {
    
    // Test discovery property
    static var allTests = [
        ("testBasicCompression", testBasicCompression),
        ("testCompressionWithLevel", testCompressionWithLevel),
        ("testDecompression", testDecompression)
    ]
    
    func testBasicCompression() throws {
        // Arrange
        let data = "Hello, World!".data(using: .utf8)!
        
        // Act
        let compressed = try data.compress()
        
        // Assert
        XCTAssertLessThan(compressed.count, data.count)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testCompressionWithLevel() throws {
        // Test different compression levels
        let data = generateTestData(size: 1024)
        
        let fastCompressed = try data.compress(level: .bestSpeed)
        let bestCompressed = try data.compress(level: .best)
        
        // Best compression should be smaller than fast compression
        XCTAssertLessThanOrEqual(bestCompressed.count, fastCompressed.count)
    }
    
    func testDecompression() throws {
        // Test round-trip compression/decompression
        let original = "Test data for compression".data(using: .utf8)!
        let compressed = try original.compress()
        let decompressed = try compressed.decompress()
        
        XCTAssertEqual(original, decompressed)
    }
}
```

### Test Data Generation

```swift
extension XCTestCase {
    
    func generateTestData(size: Int) -> Data {
        var data = Data(count: size)
        data.withUnsafeMutableBytes { bytes in
            for i in 0..<size {
                bytes[i] = UInt8(i % 256)
            }
        }
        return data
    }
    
    func generateCompressibleData(size: Int) -> Data {
        let pattern = "This is a repeating pattern that should compress well. "
        let repeatCount = size / pattern.count + 1
        let repeated = String(repeating: pattern, count: repeatCount)
        return repeated.prefix(size).data(using: .utf8)!
    }
    
    func generateRandomData(size: Int) -> Data {
        var data = Data(count: size)
        data.withUnsafeMutableBytes { bytes in
            for i in 0..<size {
                bytes[i] = UInt8.random(in: 0...255)
            }
        }
        return data
    }
}
```

### Error Testing

```swift
func testInvalidDataDecompression() {
    // Test decompression of invalid data
    let invalidData = "This is not compressed data".data(using: .utf8)!
    
    XCTAssertThrowsError(try invalidData.decompress()) { error in
        XCTAssertTrue(error is ZLibError)
        if case ZLibError.invalidData = error {
            // Expected error
        } else {
            XCTFail("Expected ZLibError.invalidData")
        }
    }
}

func testEmptyDataCompression() throws {
    // Test compression of empty data
    let emptyData = Data()
    let compressed = try emptyData.compress()
    
    // Empty data should still produce some output
    XCTAssertGreaterThan(compressed.count, 0)
    
    // Decompression should restore empty data
    let decompressed = try compressed.decompress()
    XCTAssertEqual(decompressed, emptyData)
}
```

### Performance Testing

```swift
func testCompressionPerformance() {
    let data = generateTestData(size: 1024 * 1024) // 1MB
        
    measure {
        for _ in 0..<10 {
            try! data.compress(level: .best)
        }
    }
}

func testDecompressionPerformance() {
    let data = generateTestData(size: 1024 * 1024)
    let compressed = try! data.compress(level: .best)
    
    measure {
        for _ in 0..<10 {
            try! compressed.decompress()
        }
    }
}
```

### Async Testing

```swift
func testAsyncCompression() async throws {
    let data = generateTestData(size: 1024)
    
    let compressed = try await data.compressAsync(level: .best)
    let decompressed = try await compressed.decompressAsync()
    
    XCTAssertEqual(data, decompressed)
}

func testAsyncFileOperations() async throws {
    // Create temporary file
    let tempDir = FileManager.default.temporaryDirectory
    let inputFile = tempDir.appendingPathComponent("test-input.txt")
    let outputFile = tempDir.appendingPathComponent("test-output.gz")
    
    defer {
        try? FileManager.default.removeItem(at: inputFile)
        try? FileManager.default.removeItem(at: outputFile)
    }
    
    // Write test data
    let testData = "Test content for async file operations".data(using: .utf8)!
    try testData.write(to: inputFile)
    
    // Test async compression
    try await ZLib.compressFileAsync(
        from: inputFile.path,
        to: outputFile.path,
        level: .best
    )
    
    // Verify output exists
    XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
}
```

### Combine Testing

```swift
func testCombineCompression() throws {
    let expectation = XCTestExpectation(description: "Combine compression")
    let data = generateTestData(size: 1024)
    
    var cancellables = Set<AnyCancellable>()
    
    ZLib.compressPublisher(data: data, level: .best)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Compression failed: \(error)")
                }
            },
            receiveValue: { compressed in
                XCTAssertGreaterThan(compressed.count, 0)
                XCTAssertLessThan(compressed.count, data.count)
            }
        )
        .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 5.0)
}

func testCombineFileOperations() throws {
    let expectation = XCTestExpectation(description: "Combine file operations")
    
    // Create temporary files
    let tempDir = FileManager.default.temporaryDirectory
    let inputFile = tempDir.appendingPathComponent("combine-input.txt")
    let outputFile = tempDir.appendingPathComponent("combine-output.gz")
    
    defer {
        try? FileManager.default.removeItem(at: inputFile)
        try? FileManager.default.removeItem(at: outputFile)
    }
    
    // Write test data
    let testData = "Test content for Combine file operations".data(using: .utf8)!
    try testData.write(to: inputFile)
    
    var cancellables = Set<AnyCancellable>()
    
    ZLib.compressFilePublisher(
        from: inputFile.path,
        to: outputFile.path,
        level: .best
    )
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("File compression failed: \(error)")
            }
        },
        receiveValue: { _ in
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        }
    )
    .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 10.0)
}
```

## Debugging Tests

### Test Output Analysis

```bash
# Run tests with detailed output
swift test --verbose

# Run tests with Xcode-style output
swift test --enable-test-discovery

# Run tests and save output to file
swift test --verbose > test-output.txt 2>&1
```

### Common Test Issues

**Test Discovery Problems**
```bash
# Ensure allTests properties are correct
swift test --list-tests

# Check for missing test discovery
grep -r "static var allTests" Tests/
```

**Build Errors**
```bash
# Clean and rebuild
swift package clean
swift build
swift test
```

**Runtime Errors**
```bash
# Run with debug symbols
swift test --debug-info

# Run specific failing test
swift test --filter "testFailingTest"
```

### Test Debugging Techniques

```swift
func testWithDebugging() throws {
    let data = generateTestData(size: 1024)
    
    // Add debug prints
    print("Original data size: \(data.count)")
    
    let compressed = try data.compress(level: .best)
    print("Compressed size: \(compressed.count)")
    print("Compression ratio: \(Double(compressed.count) / Double(data.count))")
    
    let decompressed = try compressed.decompress()
    print("Decompressed size: \(decompressed.count)")
    
    XCTAssertEqual(data, decompressed)
}
```

## Test Best Practices

### 1. Test Organization

```swift
final class CompressionTests: XCTestCase {
    
    // Group related tests together
    func testBasicCompression() throws { /* ... */ }
    func testCompressionWithLevel() throws { /* ... */ }
    func testCompressionWithStrategy() throws { /* ... */ }
    
    // Use descriptive test names
    func testCompressionShouldReduceSizeForCompressibleData() throws { /* ... */ }
    func testCompressionShouldHandleEmptyData() throws { /* ... */ }
    func testCompressionShouldThrowErrorForInvalidInput() throws { /* ... */ }
}
```

### 2. Test Data Management

```swift
final class FileOperationTests: XCTestCase {
    
    private var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testFileCompression() throws {
        let inputFile = tempDirectory.appendingPathComponent("input.txt")
        let outputFile = tempDirectory.appendingPathComponent("output.gz")
        
        // Test implementation
    }
}
```

### 3. Error Testing

```swift
func testComprehensiveErrorHandling() {
    // Test all error conditions
    let testCases: [(Data, ZLibError)] = [
        (Data(), .invalidData),           // Empty data
        ("Invalid".data(using: .utf8)!, .invalidData),  // Invalid compressed data
    ]
    
    for (input, expectedError) in testCases {
        XCTAssertThrowsError(try input.decompress()) { error in
            XCTAssertEqual(error as? ZLibError, expectedError)
        }
    }
}
```

### 4. Performance Testing

```swift
func testPerformanceAcrossSizes() {
    let sizes = [1024, 1024 * 1024, 10 * 1024 * 1024] // 1KB, 1MB, 10MB
    
    for size in sizes {
        let data = generateTestData(size: size)
        
        measure {
            try! data.compress(level: .best)
        }
    }
}
```

### 5. Edge Case Testing

```swift
func testEdgeCases() throws {
    // Test very small data
    let smallData = "A".data(using: .utf8)!
    let smallCompressed = try smallData.compress()
    let smallDecompressed = try smallCompressed.decompress()
    XCTAssertEqual(smallData, smallDecompressed)
    
    // Test very large data
    let largeData = generateTestData(size: 100 * 1024 * 1024) // 100MB
    let largeCompressed = try largeData.compress()
    let largeDecompressed = try largeCompressed.decompress()
    XCTAssertEqual(largeData, largeDecompressed)
    
    // Test data with specific patterns
    let patternData = String(repeating: "A", count: 10000).data(using: .utf8)!
    let patternCompressed = try patternData.compress()
    XCTAssertLessThan(patternCompressed.count, patternData.count)
}
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_13.0.app
    
    - name: Run Tests
      run: swift test --verbose
    
    - name: Run Performance Tests
      run: swift test --filter PerformanceTests
    
    - name: Run All Test Groups
      run: |
        swift test --filter CoreTests
        swift test --filter ExtensionsTests
        swift test --filter FileOperationsTests
        swift test --filter CombineTests
```

This testing guide provides comprehensive coverage of testing practices, debugging techniques, and best practices for the SwiftZlib test suite. 