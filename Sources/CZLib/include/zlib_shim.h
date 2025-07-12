#ifndef ZLIB_SHIM_H
#define ZLIB_SHIM_H

#include <zlib.h>

// Basic compression/decompression wrappers
int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen,
                   int level);

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen);

int swift_uncompress2(Bytef *dest, uLongf *destLen,
                      const Bytef *source, uLong *sourceLen);

// Stream-based compression wrappers
int swift_deflateInit(z_streamp strm, int level);
int swift_deflate(z_streamp strm, int flush);
int swift_deflateEnd(z_streamp strm);

// Advanced stream compression wrappers
int swift_deflateInit2(z_streamp strm, int level, int method, int windowBits, 
                       int memLevel, int strategy);
int swift_deflateParams(z_streamp strm, int level, int strategy);
int swift_deflateReset(z_streamp strm);
int swift_deflateCopy(z_streamp dest, z_streamp source);
int swift_deflatePrime(z_streamp strm, int bits, int value);

// Stream-based decompression wrappers
int swift_inflateInit(z_streamp strm);
int swift_inflate(z_streamp strm, int flush);
int swift_inflateEnd(z_streamp strm);

// Advanced stream decompression wrappers
int swift_inflateInit2(z_streamp strm, int windowBits);
int swift_inflateReset(z_streamp strm);
int swift_inflateCopy(z_streamp dest, z_streamp source);
int swift_inflatePrime(z_streamp strm, int bits, int value);

// InflateBack API for advanced streaming
int swift_inflateBackInit(z_streamp strm, int windowBits, unsigned char *window);
int swift_inflateBack(z_streamp strm, in_func in, void *in_desc, out_func out, void *out_desc);
int swift_inflateBackEnd(z_streamp strm);

// Stream introspection
long swift_inflateMark(z_streamp strm);
unsigned long swift_inflateCodesUsed(z_streamp strm);

// Dictionary support
int swift_deflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);
int swift_inflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);

// Checksum functions
uLong swift_adler32(uLong adler, const Bytef *buf, uInt len);
uLong swift_crc32(uLong crc, const Bytef *buf, uInt len);

// Utility functions
uLong swift_compressBound(uLong sourceLen);
const char* swift_zlibVersion(void);
const char* swift_zError(int err);

// Advanced stream functions
int swift_deflatePending(z_streamp strm, unsigned *pending, int *bits);
uLong swift_deflateBound(z_streamp strm, uLong sourceLen);
int swift_deflateTune(z_streamp strm, int good_length, int max_lazy, int nice_length, int max_chain);
int swift_inflateSync(z_streamp strm);
int swift_inflateSyncPoint(z_streamp strm);
int swift_inflateReset2(z_streamp strm, int windowBits);

// Dictionary functions
int swift_deflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);
int swift_inflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);

// Checksum combination functions
uLong swift_adler32_combine(uLong adler1, uLong adler2, z_off_t len2);
uLong swift_crc32_combine(uLong crc1, uLong crc2, z_off_t len2);

// Compile flags
uLong swift_zlibCompileFlags(void);

// Gzip file operations
void* swift_gzopen(const char* path, const char* mode);
int swift_gzclose(void* file);
int swift_gzread(void* file, void* buf, unsigned int len);
int swift_gzwrite(void* file, void* buf, unsigned int len);
long swift_gzseek(void* file, long offset, int whence);
long swift_gztell(void* file);
int swift_gzflush(void* file, int flush);
int swift_gzrewind(void* file);
int swift_gzeof(void* file);
int swift_gzsetparams(void* file, int level, int strategy);
const char* swift_gzerror(void* file, int* errnum);

// Gzip header manipulation
int swift_deflateSetHeader(z_streamp strm, gz_headerp head);
int swift_inflateGetHeader(z_streamp strm, gz_headerp head);

#endif /* ZLIB_SHIM_H */ 