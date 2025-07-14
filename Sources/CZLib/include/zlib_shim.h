#ifndef ZLIB_SHIM_H
#define ZLIB_SHIM_H

#include "zlib_simple.h"

// Swift-compatible wrapper functions for zlib
int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen);

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen);

int swift_uncompress2(Bytef *dest, uLongf *destLen,
                      const Bytef *source, uLong sourceLen);

// Stream management functions
int swift_deflateInit(z_streamp strm, int level);
int swift_deflate(z_streamp strm, int flush);
int swift_deflateEnd(z_streamp strm);
int swift_deflateInit2(z_streamp strm, int level, int method, int windowBits, int memLevel, int strategy);

int swift_inflateInit(z_streamp strm);
int swift_inflate(z_streamp strm, int flush);
int swift_inflateEnd(z_streamp strm);
int swift_inflateInit2(z_streamp strm, int windowBits);

// Advanced functions
int swift_inflateBack(z_streamp strm, in_func in, void *in_desc, out_func out, void *out_desc);

// Header management
int swift_deflateSetHeader(z_streamp strm, gz_headerp head);
int swift_inflateGetHeader(z_streamp strm, gz_headerp head);

// Utility functions
uLong swift_adler32(uLong adler, const Bytef *buf, uInt len);
uLong swift_crc32(uLong crc, const Bytef *buf, uInt len);
uLong swift_compressBound(uLong sourceLen);

// Version and error functions
const char* swift_zlibVersion(void);
const char* swift_zError(int err);

#endif /* ZLIB_SHIM_H */
