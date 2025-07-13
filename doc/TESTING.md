# Testing in SwiftZlib

## Test Philosophy
- Comprehensive coverage
- Edge cases and error conditions

## Running Tests
- How to run the test suite
- Platform requirements

## Test Coverage Summary

| Area                | Coverage | Comments |
|---------------------|----------|----------|
| Basic Compression   | ✅        | Round-trip, all levels, small/large/binary/empty data |
| Streaming/Chunked   | ✅        | Multiple chunk sizes, streaming APIs, output handler aborts |
| Dictionary          | ✅        | All edge cases: correct, wrong, missing, large, empty, timing |
| Priming             | ✅        | All edge cases: before/after, invalid, round-trip, raw/zlib/gzip |
| WindowBits          | ✅        | All variants, mismatches, auto-detect, empty/corrupted input |
| Error Handling      | ✅        | All major zlib errors, custom error codes, recovery suggestions |
| Edge Cases          | ✅        | Empty, single-byte, large, binary, corrupted, concurrent |
| Gzip Header         | ✅        | Metadata, corruption, round-trip, streaming, auto-detect |

## Adding New Tests
- Guidelines
- Where to add
- Naming conventions

## Platform-Specific Notes
- macOS vs Linux
- zlib version differences

## See Also
- [Error Handling](ERROR_HANDLING.md)
- [Streaming API](STREAMING.md) 