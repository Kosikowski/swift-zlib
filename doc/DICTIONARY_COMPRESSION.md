# Dictionary Compression in SwiftZlib

## Overview

This document outlines the findings and requirements for dictionary compression in the SwiftZlib wrapper, based on extensive testing and analysis of the underlying zlib behavior.

## Key Findings

### ⚠️ Critical Timing Requirement

**The dictionary must be set immediately after initializing the (de)compressor and before starting any (de)compression operations.**

- **Compression**: Set dictionary after `initializeAdvanced()` but before `compress()`
- **Decompression**: Set dictionary after `initializeAdvanced()` but before `decompress()`
- **If you attempt to set the dictionary after (de)compression has started, zlib will return `Z_STREAM_ERROR`**

```swift
// ✅ CORRECT - Dictionary set at the right time
let compressor = Compressor()
try compressor.initializeAdvanced(windowBits: .raw)
try compressor.setDictionary(dictionary)  // Set BEFORE compression
let compressed = try compressor.compress(data, flush: .finish)

let decompressor = Decompressor()
try decompressor.initializeAdvanced(windowBits: .raw)
try decompressor.setDictionary(dictionary)  // Set BEFORE decompression
let decompressed = try decompressor.decompress(compressed)
```

```swift
// ❌ WRONG - Dictionary set too late
let decompressor = Decompressor()
try decompressor.initializeAdvanced(windowBits: .raw)
let result = try decompressor.decompress(data)  // Decompression started
try decompressor.setDictionary(dictionary)      // Too late! Will fail
```

### 1. Raw Deflate Format Requirement

**Critical Discovery**: Dictionary compression and decompression **require raw deflate format** (`windowBits = -15`), not standard deflate format (`windowBits = 15`).

```swift
// ❌ WRONG - Standard deflate format doesn't support dictionaries
try compressor.initializeAdvanced(windowBits: .deflate)  // windowBits = 15
try decompressor.initializeAdvanced(windowBits: .deflate) // windowBits = 15

// ✅ CORRECT - Raw deflate format supports dictionaries
try compressor.initializeAdvanced(windowBits: .raw)   // windowBits = -15
try decompressor.initializeAdvanced(windowBits: .raw)  // windowBits = -15
```

### 2. Zlib Behavior with Dictionaries

#### Compression with Dictionary
- **Works correctly** with raw deflate format (`windowBits = -15`)
- Dictionary must be set **before** compression begins
- `deflateSetDictionary()` returns `Z_OK` (0) on success

#### Decompression without Dictionary
- Returns `Z_NEED_DICT (2)` or `Z_DATA_ERROR (-3)` when data was compressed with a dictionary
- Both error codes are acceptable and expected behavior

#### Decompression with Dictionary
- Dictionary must be set **before** decompression begins
- `inflateSetDictionary()` returns `Z_OK` (0) on success
- Decompression proceeds normally after dictionary is set

### 3. WindowBits Format Compatibility

| Format | WindowBits | Dictionary Support | Use Case |
|--------|------------|-------------------|----------|
| Raw Deflate | -15 | ✅ Yes | Dictionary compression |
| Standard Deflate | 15 | ❌ No | Regular compression |
| Gzip | 31 | ❌ No | Gzip format |
| Auto-detect | 47 | ❌ No | Auto-detection |

## Implementation Requirements

### 1. Compressor Setup

```swift
let compressor = Compressor()
try compressor.initializeAdvanced(level: .defaultCompression, windowBits: .raw)
try compressor.setDictionary(dictionary)
let compressed = try compressor.compress(data, flush: .finish)
```

### 2. Decompressor Setup

```swift
let decompressor = Decompressor()
try decompressor.initializeAdvanced(windowBits: .raw)
try decompressor.setDictionary(dictionary)
let decompressed = try decompressor.decompress(compressed)
```

### 3. Streaming Decompressor

The `StreamingDecompressor` class now properly supports dictionary operations:

```swift
let decompressor = StreamingDecompressor(windowBits: .raw)
try decompressor.initialize()
try decompressor.setDictionary(dictionary)
// ... use streaming methods
```

## Error Handling

### Expected Error Codes

When decompressing data compressed with a dictionary **without** providing the dictionary:

- `Z_NEED_DICT (2)` - Dictionary is required
- `Z_DATA_ERROR (-3)` - Data error (also acceptable)

### Dictionary Setting Errors

- `Z_STREAM_ERROR (-2)` - Stream error (occurs when using wrong windowBits)
- `Z_OK (0)` - Success

## Testing Results

### C Test Validation

A minimal C test was created to validate zlib behavior:

```c
// Compression with dictionary (works)
int ret = deflateInit2(&c_stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
ret = deflateSetDictionary(&c_stream, dict, dict_len); // Returns Z_OK

// Decompression without dictionary (fails as expected)
ret = inflateInit2(&d_stream, -15);
ret = inflate(&d_stream, Z_FINISH); // Returns Z_NEED_DICT or Z_DATA_ERROR

// Decompression with dictionary (works)
ret = inflateInit2(&d_stream, -15);
ret = inflateSetDictionary(&d_stream, dict, dict_len); // Returns Z_OK
ret = inflate(&d_stream, Z_FINISH); // Returns Z_STREAM_END
```

### Swift Test Results

The `testStreamingWithDictionaryAdvanced` test now passes:

1. **Compression with dictionary**: ✅ Success
2. **Decompression without dictionary**: ✅ Fails with expected error
3. **Decompression with dictionary**: ✅ Success

## Technical Details

### Zlib Function Requirements

- `deflateInit2()` with `windowBits = -15` for compression
- `inflateInit2()` with `windowBits = -15` for decompression
- `deflateSetDictionary()` for compression dictionary
- `inflateSetDictionary()` for decompression dictionary

### Memory Management

- Dictionary data must remain valid during compression/decompression
- Dictionary size should be reasonable (typically 32KB or less)
- Dictionary content should match between compression and decompression

## Best Practices

### 1. Always Use Raw Format for Dictionaries

```swift
// ✅ Correct approach
let compressor = Compressor()
try compressor.initializeAdvanced(windowBits: .raw)
try compressor.setDictionary(dictionary)

let decompressor = Decompressor()
try decompressor.initializeAdvanced(windowBits: .raw)
try decompressor.setDictionary(dictionary)
```

### 2. Handle Dictionary Errors Gracefully

```swift
do {
    try decompressor.setDictionary(dictionary)
} catch ZLibError.decompressionFailed(let code) {
    if code == Z_STREAM_ERROR {
        // Likely wrong windowBits format
        throw ZLibError.streamError(code)
    }
    throw ZLibError.decompressionFailed(code)
}
```

### 3. Validate Dictionary Compatibility

```swift
// Ensure compressor and decompressor use same format
let windowBits: WindowBits = .raw
try compressor.initializeAdvanced(windowBits: windowBits)
try decompressor.initializeAdvanced(windowBits: windowBits)
```

## Common Pitfalls

### 1. Wrong WindowBits Format

```swift
// ❌ This will fail
try compressor.initializeAdvanced(windowBits: .deflate) // Standard format
try compressor.setDictionary(dictionary) // Will fail
```

### 2. Mismatched Formats

```swift
// ❌ Compressor and decompressor must use same format
try compressor.initializeAdvanced(windowBits: .raw)
try decompressor.initializeAdvanced(windowBits: .deflate) // Mismatch!
```

### 3. Dictionary Set After Decompression

```swift
// ❌ Dictionary must be set before decompression
let result = try decompressor.decompress(data) // May fail
try decompressor.setDictionary(dictionary) // Too late!
```

## Conclusion

Dictionary compression in SwiftZlib requires careful attention to the windowBits format. Always use `WindowBits.raw` (-15) for dictionary operations, and ensure both compressor and decompressor use the same format. The underlying zlib library is strict about these requirements, and the Swift wrapper now properly handles these constraints.

## References

- [Zlib Documentation](https://www.zlib.net/manual.html)
- [Zlib Source Code](https://github.com/madler/zlib)
- [SwiftZlib Implementation](../Sources/SwiftZlib/swift_zlib.swift) 

## Running the Minimal C Tests

To validate zlib dictionary behavior independently, you can compile and run the provided C tests. These are useful for debugging or learning about zlib's dictionary requirements.

### Example (macOS/Linux)

```sh
gcc -o test_zlib_example test_zlib_example.c -lz
./test_zlib_example

gcc -o test_zlib_dict_checksum test_zlib_dict_checksum.c -lz
./test_zlib_dict_checksum
```

- Ensure you have the zlib development headers installed (on Linux: `sudo apt-get install zlib1g-dev`)
- The output will show step-by-step results and error codes for each dictionary scenario. 