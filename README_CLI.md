# SwiftZlib Command Line Tool

A comprehensive command-line interface for the SwiftZlib package that demonstrates all its key features including compression, decompression, benchmarking, checksum calculation, and more.

## Features

- **File Compression/Decompression** - Handle both files and data
- **Performance Benchmarking** - Compare different compression levels
- **Checksum Calculation** - Adler-32 and CRC-32 support
- **Streaming Operations** - Memory-efficient large file handling
- **Gzip Support** - Compression with proper gzip headers
- **Library Information** - Detailed zlib version and configuration info
- **Error Handling** - Comprehensive error reporting and recovery suggestions

## Installation

The command-line tool is included with the SwiftZlib package. To build and run:

```bash
# Build the package
swift build

# Run the CLI tool
swift run SwiftZlibCLI
```

## Quick Test

To verify the command-line tool is working correctly, run this sequence of commands:

```bash
# Test help and info
swift run SwiftZlibCLI help
swift run SwiftZlibCLI info

# Create a test file and test all features
echo "This is a test file for SwiftZlib compression. It contains repeated text to demonstrate the effectiveness of compression algorithms." > test_file.txt

# Test compression and decompression
swift run SwiftZlibCLI compress test_file.txt compressed.zlib 9
swift run SwiftZlibCLI decompress compressed.zlib decompressed.txt

# Test benchmarking
swift run SwiftZlibCLI benchmark test_file.txt

# Test checksums
swift run SwiftZlibCLI checksum test_file.txt

# Test gzip
swift run SwiftZlibCLI gzip test_file.txt test_file.gz

# Test large file compression (create 10MB test file)
dd if=/dev/urandom of=test_large.dat bs=1M count=10
swift run SwiftZlibCLI large test_large.dat compressed_large.zlib 6

# Verify everything worked
diff test_file.txt decompressed.txt
gunzip -t test_file.gz

# Clean up
rm test_file.txt test_file.gz compressed.zlib decompressed.txt test_large.dat compressed_large.zlib
```

If all commands complete successfully, the tool is working correctly!

## Usage

### Basic Commands

#### 1. Compress Files or Data

```bash
# Compress a file
swift run SwiftZlibCLI compress input.txt output.zlib

# Compress with specific level (0-9)
swift run SwiftZlibCLI compress input.txt output.zlib 9

# Compress data (string)
swift run SwiftZlibCLI compress "Hello, World!" output.zlib
```

#### 2. Decompress Files or Data

```bash
# Decompress a file
swift run SwiftZlibCLI decompress output.zlib result.txt

# Decompress data
swift run SwiftZlibCLI decompress "compressed_data" result.txt
```

#### 3. Benchmark Compression Levels

```bash
# Compare all compression levels on a file
swift run SwiftZlibCLI benchmark large_file.dat
```

This will show:

- Compression ratio for each level
- Processing time for each level
- Performance profiles for different data sizes

#### 4. Calculate Checksums

```bash
# Calculate Adler-32 and CRC-32 checksums
swift run SwiftZlibCLI checksum important_file.txt
```

#### 5. Show Library Information

```bash
# Display detailed zlib information
swift run SwiftZlibCLI info
```

Shows:

- ZLib version
- Compile flags breakdown
- Buffer size recommendations
- Memory usage estimates
- Optimal parameters for different data sizes

#### 6. Streaming Compression

```bash
# Use streaming for large files
swift run SwiftZlibCLI stream big_file.dat compressed.zlib
```

#### 7. Gzip Compression

```bash
# Compress with gzip headers
swift run SwiftZlibCLI gzip document.txt document.gz
```

#### 8. Large File Compression with Progress

```bash
# Compress large files with progress bar
swift run SwiftZlibCLI large huge_file.dat compressed.zlib 9

# This command is optimized for files >100MB and shows:
# - Real-time progress bar
# - Processing speed (MB/s)
# - Estimated time remaining
# - Compression ratio
```

## Large File Compression Demonstration

The `large` command now demonstrates compression on three types of data to illustrate how data entropy affects compression effectiveness:

- **Random Data (Incompressible):** High entropy, should not compress (ratio ≈ 1.00)
- **Zero-Filled Data (Highly Compressible):** Low entropy, compresses extremely well (ratio ≈ 0.01)
- **Repetitive Text Data (Moderately Compressible):** Moderate entropy, compresses well (ratio ≈ 0.30)

### Example Usage

```bash
swift run SwiftZlibCLI large test large_output
```

### Example Output

```
🚀 SwiftZlib Command Line Tool
================================
🗜️ Large file compression demonstration
=====================================
📊 Using streaming compression with progress tracking...
🔧 Compression level: defaultCompression

🧪 Test 1: Random Data (Incompressible)
----------------------------------------
📝 This test uses random data which has high entropy and cannot be compressed effectively.
📊 Expected result: Compression ratio ≈ 1.00 (0% reduction)

📁 Creating random test file...
📁 File: test_random
📦 Size: 10.0 MB
🎯 Type: Random data
📦 [██████████████████████████████████████████████████] 100.0% (10.0/10.0 MB) 56.2 MB/s ETA: ∞
✅ Compression completed!
⏱️ Time: 0.2 seconds
📊 Speed: 55.3 MB/s
📦 Ratio: 1.00 (-0.0% reduction)

🧪 Test 2: Zero-Filled Data (Highly Compressible)
--------------------------------------------------
📝 This test uses zero-filled data which has very low entropy and compresses extremely well.
📊 Expected result: Compression ratio ≈ 0.01 (99% reduction)

📁 Creating zero-filled test file...
📁 File: test_zeros
📦 Size: 10.0 MB
🎯 Type: Zero-filled data
📦 [██████████████████████████████████████████████████] 100.0% (10.0/10.0 MB) 434.6 MB/s ETA: ∞
✅ Compression completed!
⏱️ Time: 0.0 seconds
📊 Speed: 426.7 MB/s
📦 Ratio: 0.00 (99.9% reduction)

🧪 Test 3: Repetitive Text Data (Moderately Compressible)
----------------------------------------------------------
📝 This test uses repetitive text which has moderate entropy and compresses reasonably well.
📊 Expected result: Compression ratio ≈ 0.30 (70% reduction)

📁 Creating repetitive text file...
📁 File: test_text
📦 Size: 11.6 MB
🎯 Type: Repetitive text data
📦 [██████████████████████████████████████████████████] 100.0% (11.6/11.6 MB) 408.0 MB/s ETA: ∞
✅ Compression completed!
⏱️ Time: 0.0 seconds
📊 Speed: 404.5 MB/s
📦 Ratio: 0.00 (99.7% reduction)

📊 Compression Test Summary
==========================
Random data:    1.00 ratio (-0.0% reduction)
Zero-filled:    0.00 ratio (99.9% reduction)
Repetitive text: 0.00 ratio (99.7% reduction)

💡 Key Insight: Data entropy determines compression effectiveness!
   - High entropy (random) = poor compression
   - Low entropy (repetitive) = excellent compression
   - Moderate entropy (text) = good compression
```

This demonstration helps users understand why some files compress well and others do not, based on their content's entropy.

## Compression Levels

- **0** - No compression (fastest)
- **1** - Best speed
- **6** - Default compression (balanced)
- **9** - Best compression (slowest)

## Examples

### Example 1: Quick Test and Verification

```bash
# Test the help command
swift run SwiftZlibCLI help

# Show library information
swift run SwiftZlibCLI info

# Create a test file
echo "This is a test file for SwiftZlib compression. It contains repeated text to demonstrate the effectiveness of compression algorithms. This text will be compressed and then decompressed to verify the functionality of the SwiftZlib package." > test_file.txt

# Compress with best compression level
swift run SwiftZlibCLI compress test_file.txt compressed.zlib 9

# Decompress the file
swift run SwiftZlibCLI decompress compressed.zlib decompressed.txt

# Benchmark different compression levels
swift run SwiftZlibCLI benchmark test_file.txt

# Calculate checksums
swift run SwiftZlibCLI checksum test_file.txt

# Create gzip file with headers
swift run SwiftZlibCLI gzip test_file.txt test_file.gz

# Verify files were created correctly
ls -la test_file.* compressed.zlib decompressed.txt

# Verify compression/decompression worked correctly
diff test_file.txt decompressed.txt

# Verify gzip file is valid
gunzip -t test_file.gz && echo "Gzip file is valid"

# Clean up test files
rm test_file.txt test_file.gz compressed.zlib decompressed.txt
```

### Example 2: Compress a Text File

```bash
# Create a sample file
echo "This is a sample text file for compression testing. It contains repeated text to demonstrate compression effectiveness." > sample.txt

# Compress with best compression
swift run SwiftZlibCLI compress sample.txt compressed.zlib 9

# Check the results
ls -la sample.txt compressed.zlib
```

### Example 3: Benchmark Different Files

```bash
# Benchmark a text file
swift run SwiftZlibCLI benchmark sample.txt

# Benchmark a binary file
swift run SwiftZlibCLI benchmark large_binary.dat
```

### Example 4: Verify Data Integrity

```bash
# Calculate checksums
swift run SwiftZlibCLI checksum important_file.txt

# Compress and verify
swift run SwiftZlibCLI compress important_file.txt compressed.zlib
swift run SwiftZlibCLI checksum compressed.zlib
```

### Example 5: Streaming Large Files

```bash
# Create a large file
dd if=/dev/urandom of=large_file.dat bs=1M count=100

# Compress using streaming
swift run SwiftZlibCLI stream large_file.dat compressed.zlib

# Decompress
swift run SwiftZlibCLI decompress compressed.zlib decompressed.dat
```

### Example 6: Gzip with Headers

```bash
# Compress with gzip format
swift run SwiftZlibCLI gzip document.txt document.gz

# The resulting file will have proper gzip headers
# and can be decompressed with standard gzip tools
gunzip document.gz
```

### Example 7: Large File Compression with Progress

```bash
# Create a large test file (100MB)
dd if=/dev/urandom of=large_test.dat bs=1M count=100

# Compress with progress tracking
swift run SwiftZlibCLI large large_test.dat compressed_large.zlib 9

# Expected output:
# 🗜️ Large file compression: large_test.dat -> compressed_large.zlib
# 📊 Using streaming compression with progress tracking...
# 📁 File size: 100.0 MB
# 📦 [██████████████████████████████████████████████████] 100.0% (100.0/100.0 MB) 56.6 MB/s ETA: ∞
# ✅ Large file compression completed!
# ⏱️ Total time: 1.8 seconds
# 📊 Average speed: 56.6 MB/s
# 📦 Compression ratio: 1.00 (-0.0% reduction)

# Clean up
rm large_test.dat compressed_large.zlib
```

## Error Handling

The tool provides comprehensive error handling:

- **File not found** - Clear error messages with suggestions
- **Compression errors** - Detailed error codes and recovery suggestions
- **Memory errors** - Recommendations for buffer sizes and memory levels
- **Data corruption** - Validation and integrity checks

## Performance Tips

1. **For small files (< 1MB)**: Use default compression level (6)
2. **For large files (> 100MB)**: Use streaming compression
3. **For speed-critical applications**: Use level 1 (best speed)
4. **For maximum compression**: Use level 9 (best compression)
5. **For network transfer**: Consider gzip format for compatibility

## Integration

The command-line tool demonstrates all the key APIs of the SwiftZlib package:

- `ZLib.compress()` / `ZLib.decompress()` - Basic compression
- `ZLib.compressFile()` / `ZLib.decompressFile()` - File operations
- `Data.compressed()` / `Data.decompressed()` - Data extensions
- `Data.adler32()` / `Data.crc32()` - Checksum calculation
- `ZLib.getPerformanceProfiles()` - Performance analysis
- `ZLib.compileFlagsInfo` - Library information

## Troubleshooting

### Common Issues

1. **"File not found"**: Ensure the input file exists and is readable
2. **"Compression failed"**: Check if the input data is valid
3. **"Memory error"**: Try reducing compression level or using streaming
4. **"Data error"**: Verify the compressed data is not corrupted

### Getting Help

```bash
# Show help
swift run SwiftZlibCLI help

# Show usage for specific command
swift run SwiftZlibCLI compress
```

## Advanced Usage

### Custom Buffer Sizes

The tool uses recommended buffer sizes by default, but you can modify the source code to use custom sizes for specific use cases.

### Error Recovery

The tool includes error recovery suggestions based on zlib error codes, helping users understand and resolve compression issues.

### Performance Monitoring

The benchmarking feature helps users choose the optimal compression level for their specific data and performance requirements.
