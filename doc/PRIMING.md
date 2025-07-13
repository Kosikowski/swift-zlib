# Priming Support in SwiftZlib

## What is Priming?
Priming in zlib refers to the ability to insert a specific number of bits into the compression or decompression stream before any actual data is processed. This is a low-level feature, exposed via `deflatePrime` and `inflatePrime`, and is rarely needed in typical applications.

## Supported Scenarios
- **Priming affects the raw bit stream**: Any bits primed are prepended to the compressed output. This can be used for bit-level protocol integration or special framing.
- **Priming is only meaningful for raw deflate streams**: For `windowBits: .raw` (no zlib/gzip headers), priming can be used to manipulate the bit stream. However, even here, round-trip compression/decompression with priming is not generally supported, as the primed bits interfere with the deflate format.
- **Priming is not supported for zlib/gzip streams**: If you use priming with `windowBits: .deflate` (zlib) or `.gzip`, decompression will fail, as the header is not recognized.

## Limitations
- **Round-trip with priming is not supported**: Even with raw deflate, decompressing data that was primed during compression will usually fail, as the primed bits disrupt the deflate stream format.
- **Priming after partial decompression is not supported**: Once decompression has started, calling `inflatePrime` will fail.
- **Maximum bits**: zlib's `deflatePrime` only supports a limited number of bits (typically less than 32). Attempting to prime with more bits will result in a buffer error.

## Test Coverage
- Tests verify that priming affects the compressed output.
- Tests verify that priming with different values produces different outputs.
- Tests verify that priming is not supported for zlib/gzip streams.
- Tests verify that round-trip with priming fails (documented limitation).
- Tests verify that priming after partial decompression fails.
- Tests verify that excessive priming (e.g., 32 bits) fails with a buffer error.

## Practical Guidance
- **Do not use priming unless you have a very specific bit-level protocol need.**
- For most applications, priming should be avoided.
- If you need to use priming, use raw deflate streams and be aware of the limitations above. 

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