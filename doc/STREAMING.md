# Streaming API in SwiftZlib

## Overview

SwiftZlib provides advanced streaming APIs for both compression and decompression, supporting chunked processing and custom output handlers.

## Streaming Compressor
- Usage
- Chunked input
- Flushing and finishing
- Performance tips

> **Note:** `Compressor.reset()` (zlib's `deflateReset`) only resets the internal state for continued use with the same parameters. It does **not** re-emit headers or fully reinitialize the stream. For a new, unrelated compression, create a new `Compressor` instance or re-initialize. See the [zlib manual](https://zlib.net/manual.html#deflateReset) for details.

## Streaming Decompressor
- Usage
- Chunked input
- Output handler
- Error handling
- Edge cases

## InflateBackDecompressor
- Overview
- Callback-based streaming
- Use cases

## Edge Cases
- Single-byte chunks
- Large chunks
- Output handler aborts
- Stream interruption/cancellation
- Chunk boundary issues

## Performance Tips
- Buffer sizing
- Memory usage
- Throughput optimization

## See Also
- [Error Handling](ERROR_HANDLING.md)
- [Testing](TESTING.md) 