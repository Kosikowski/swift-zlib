#ifndef ZLIB_SHIM_H
#define ZLIB_SHIM_H

#include <zlib.h>

// Basic compression/decompression wrappers
int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen,
                   int level);

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen);

// Stream-based compression wrappers
int swift_deflateInit(z_streamp strm, int level);
int swift_deflate(z_streamp strm, int flush);
int swift_deflateEnd(z_streamp strm);

// Stream-based decompression wrappers
int swift_inflateInit(z_streamp strm);
int swift_inflate(z_streamp strm, int flush);
int swift_inflateEnd(z_streamp strm);

// Utility functions
uLong swift_compressBound(uLong sourceLen);
const char* swift_zlibVersion(void);

#endif /* ZLIB_SHIM_H */ 