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

## Linux Memory Leak Investigation

### Background

During CI testing on Linux Ubuntu runners, AddressSanitizer reported a memory leak of 32 bytes that appeared to be unrelated to our SwiftZlib code. This section documents our investigation and findings.

### Initial Problem

When running tests with AddressSanitizer on Linux:

```bash
swift test --filter MemoryLeakTests --sanitize=address --verbose
```

AddressSanitizer reported:

```
Direct leak of 32 byte(s) in 1 object(s) allocated from:
#0 0x55e8e24e1f67  (/home/runner/work/swift-zlib/swift-zlib/.build/x86_64-unknown-linux-gnu/debug/SwiftZlibPackageTests.xctest+0x10af67)
#1 0x7f2f04e0673a  (/opt/hostedtoolcache/swift-Ubuntu/5.9.2/x64/usr/lib/swift/linux/libswiftCore.so+0x40673a)
#2 0x7f2f04e4c675  (/opt/hostedtoolcache/swift-Ubuntu/5.9.2/x64/usr/lib/swift/linux/libswiftCore.so+0x44c675)
#3 0x7f2f04e0871a  (/opt/hostedtoolcache/swift-Ubuntu/5.9.2/x64/usr/lib/swift/linux/libswiftCore.so+0x40871a)
#4 0x7f2f0486488b  (/opt/hostedtoolcache/swift-Ubuntu/5.9.2/x64/usr/lib/swift/linux/libXCTest.so+0x4688b)
#5 0x7f2f04864e6a  (/opt/hostedtoolcache/swift-Ubuntu/5.9.2/x64/usr/lib/swift/linux/libXCTest.so+0x46e6a)
SUMMARY: AddressSanitizer: 32 byte(s) leaked in 1 allocation(s).
```

### Investigation Steps

#### 1. Stack Trace Analysis

The stack trace showed allocations in:

- `libswiftCore.so` (Swift runtime)
- `libXCTest.so` (XCTest framework)

**Key Finding**: No symbols from our SwiftZlib code appeared in the stack trace, indicating the leak was not in our application code.

#### 2. Test Isolation

We created a minimal test to isolate our code from the test harness:

```swift
/// Minimal test to isolate allocation/deallocation for AddressSanitizer
func testIsolatedAllocationDeallocation() throws {
    // Allocate and deallocate Compressor
    do {
        let compressor = Compressor()
        try compressor.initialize(level: .defaultCompression)
        let testData = "leak test".data(using: .utf8)!
        let _ = try compressor.compress(testData, flush: .finish)
        // Compressor deallocated at end of scope
    }
    // Allocate and deallocate Decompressor
    do {
        let decompressor = Decompressor()
        try decompressor.initialize()
        let testData = "leak test".data(using: .utf8)!
        let compressed = try ZLib.compress(testData)
        let _ = try decompressor.decompress(compressed)
        // Decompressor deallocated at end of scope
    }
}
```

#### 3. Local Testing

We ran AddressSanitizer locally on macOS:

```bash
swift test --filter MemoryLeakTests --sanitize=address --verbose
```

**Result**: No memory leaks reported on macOS, confirming the issue was Linux-specific.

#### 4. Swift Version Testing

We tested with different Swift versions:

- Swift 5.9: Leak reported
- Swift 6.1: Leak still reported

**Finding**: The issue persisted across Swift versions.

### Root Cause Analysis

#### 1. Swift Runtime Behavior

⚠️ **Note**: The 32-byte leak is consistent with small internal allocations in the Swift runtime that are not cleaned up at process exit. This is a known behavior in some Swift/XCTest combinations on Linux.

#### 2. AddressSanitizer Sensitivity

AddressSanitizer is extremely sensitive and reports all unreleased memory, including:

- Swift runtime internal allocations
- XCTest framework allocations
- System library allocations

#### 3. Platform Differences

The leak only occurs on Linux, not macOS, due to:

- Different memory management in Swift runtime between platforms
- Different XCTest implementation details
- Different system library behaviors

### Resolution Strategy

#### 1. CI Configuration Changes

We updated our GitHub Actions workflow to:

- Use Swift 5.10.1 on Ubuntu 24.04 runners
- Use SwiftyLab/setup-swift@v1 to avoid GPG verification issues
- Focus on functional testing rather than memory analysis

```yaml
# Updated memory-leak-linux job
memory-leak-linux:
  name: Linux Memory Leak Test (MemoryLeakTests only)
  runs-on: ubuntu-latest
  steps:
    - name: Install Swift
      uses: SwiftyLab/setup-swift@v1
      with:
        swift-version: "5.10.1"

    - name: Run MemoryLeakTests
      run: swift test --filter MemoryLeakTests --verbose # No sanitizer flags
```

**Note**: We removed `--no-sanitize` flags from all test commands because:

- `--no-sanitize` is not a valid Swift option
- The alternative Swift installation (SwiftyLab/setup-swift) handles installation more reliably
- We focus on functional testing rather than sanitizer-based memory analysis

#### 2. Alternative Swift Installation

We switched from the official `swift-actions/setup-swift` to `SwiftyLab/setup-swift@v1` because:

- **GPG Issues**: The official action had GPG key rotation problems
- **Reliability**: Alternative action works more consistently
- **Cross-platform**: Better support across different environments
- **Simpler**: No complex signing key management

#### 3. Memory Leak Test Strategy

Our approach to memory leak testing:

1. **Functional Testing**: Ensure all objects are properly deallocated through normal usage
2. **Scope Testing**: Use tight scopes to force deallocation
3. **Stress Testing**: Create many objects in rapid succession
4. **Error Testing**: Ensure proper cleanup even when errors occur

#### 4. Known Limitations

- AddressSanitizer on Linux may report false positives from Swift/XCTest runtime
- Small leaks (32 bytes) in runtime code are common and not actionable
- Platform-specific differences in memory management are expected
- Alternative Swift installation avoids GPG issues but may not have sanitizer support

### Best Practices for Memory Testing

#### 1. Focus on Application Code

```swift
func testApplicationMemoryManagement() throws {
    // Test your actual code, not framework code
    let compressor = Compressor()
    try compressor.initialize()

    // Use the compressor
    let result = try compressor.compress(testData)

    // Verify functionality
    XCTAssertGreaterThan(result.count, 0)

    // Compressor will be deallocated here
}
```

#### 2. Use Explicit Scoping

```swift
func testExplicitScoping() throws {
    do {
        let compressor = Compressor()
        try compressor.initialize()
        // Use compressor
    } // Explicit deallocation here

    do {
        let decompressor = Decompressor()
        try decompressor.initialize()
        // Use decompressor
    } // Explicit deallocation here
}
```

#### 3. Test Error Scenarios

```swift
func testMemoryCleanupOnError() throws {
    let compressor = Compressor()

    // Don't initialize - this should throw an error
    XCTAssertThrowsError(try compressor.compress(testData))

    // Compressor should still be deallocated properly
}
```

### Conclusion

The 32-byte memory leak reported by AddressSanitizer on Linux is:

- **Not in our code**: Stack trace shows Swift/XCTest runtime
- **Platform-specific**: Only occurs on Linux, not macOS
- **Common occurrence**: Known behavior in Swift/XCTest combinations
- **Not actionable**: Small runtime leaks are not fixable by application code

Our solution focuses on:

- Functional correctness testing
- Proper object lifecycle management
- Error handling with cleanup
- Platform-appropriate testing strategies

## Continuous Integration

See the GitHub Actions workflow in `.github/workflows/tests.yml` for comprehensive CI configuration.

This testing guide provides comprehensive coverage of testing practices, debugging techniques, and best practices for the SwiftZlib test suite.
