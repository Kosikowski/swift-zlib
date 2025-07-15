#ifndef ZLIB_SHIM_H
#define ZLIB_SHIM_H

// Windows-specific guards to prevent cyclic dependencies
#ifdef _WIN32
#ifndef _CRT_NO_POSIX_ERROR_CODES
#define _CRT_NO_POSIX_ERROR_CODES
#endif
#ifndef _NO_CRT_RAND_S
#define _NO_CRT_RAND_S
#endif
#ifndef _NO_CRT_TIME_INLINE
#define _NO_CRT_TIME_INLINE
#endif
#ifndef _NO_CRT_MATH_INLINE
#define _NO_CRT_MATH_INLINE
#endif
#ifndef _NO_CRT_STRING_INLINE
#define _NO_CRT_STRING_INLINE
#endif
#ifndef _NO_CRT_WCTYPE_INLINE
#define _NO_CRT_WCTYPE_INLINE
#endif
#ifndef _NO_CRT_LOCALE_INLINE
#define _NO_CRT_LOCALE_INLINE
#endif
#ifndef _NO_CRT_STDLIB_INLINE
#define _NO_CRT_STDLIB_INLINE
#endif
#ifndef _NO_CRT_CTYPE_INLINE
#define _NO_CRT_CTYPE_INLINE
#endif
#ifndef _NO_CRT_ERRNO_INLINE
#define _NO_CRT_ERRNO_INLINE
#endif
#ifndef _NO_CRT_SETJMP_INLINE
#define _NO_CRT_SETJMP_INLINE
#endif
#ifndef _NO_CRT_SIGNAL_INLINE
#define _NO_CRT_SIGNAL_INLINE
#endif
#ifndef _NO_CRT_ASSERT_INLINE
#define _NO_CRT_ASSERT_INLINE
#endif
#ifndef _NO_CRT_MEMORY_INLINE
#define _NO_CRT_MEMORY_INLINE
#endif
#ifndef __NO_INTRINSICS__
#define __NO_INTRINSICS__
#endif
#endif

#ifdef _WIN32
#include "../zlib.h"
#elif defined(__APPLE__) && (defined(__arm__) || defined(__arm64__)) && !defined(__x86_64__)
// For iOS builds, use bundled zlib
#include "../zlib.h"
#else
#include <zlib.h>
#endif

// Type definitions for callback functions
typedef int (*swift_in_func)(void *, unsigned char **, int *);
typedef int (*swift_out_func)(void *, unsigned char *, int);

// Context structure for inflateBack callbacks
typedef struct {
    swift_in_func swift_in_func;
    swift_out_func swift_out_func;
    void *swift_context;
} swift_inflateback_context_t;

// Swift-compatible wrapper functions for zlib
int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen, int level);

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen);

int swift_uncompress2(Bytef *dest, uLongf *destLen,
                      const Bytef *source, uLong *sourceLen);

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
int swift_inflateBackInit(z_streamp strm, int windowBits, unsigned char *window);
int swift_inflateBackEnd(z_streamp strm);
int swift_inflateBackWithCallbacks(z_streamp strm, swift_in_func in_func, void *in_desc, swift_out_func out_func, void *out_desc);

// Advanced stream functions
int swift_deflateParams(z_streamp strm, int level, int strategy);
int swift_deflateReset(z_streamp strm);
int swift_deflateCopy(z_streamp dest, z_streamp source);
int swift_deflatePrime(z_streamp strm, int bits, int value);
int swift_deflateReset2(z_streamp strm, int windowBits);
unsigned long swift_deflateBound(z_streamp strm, unsigned long sourceLen);
int swift_inflateReset(z_streamp strm);
int swift_inflateReset2(z_streamp strm, int windowBits);
int swift_inflateCopy(z_streamp dest, z_streamp source);
int swift_inflatePrime(z_streamp strm, int bits, int value);

// Stream introspection
long swift_inflateMark(z_streamp strm);
unsigned long swift_inflateCodesUsed(z_streamp strm);

// Dictionary support
int swift_deflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);
int swift_inflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);

// Advanced stream functions
int swift_deflatePending(z_streamp strm, unsigned *pending, int *bits);
int swift_deflateTune(z_streamp strm, int good_length, int max_lazy, int nice_length, int max_chain);
int swift_inflateSync(z_streamp strm);
int swift_inflateSyncPoint(z_streamp strm);
int swift_deflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);
int swift_inflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);
int swift_inflatePending(z_streamp strm, unsigned *pending, int *bits);

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
int swift_gzprintf(void* file, const char* format, ...);
char* swift_gzgets(void* file, char* buf, int len);
int swift_gzputc(void* file, int c);
int swift_gzgetc(void* file);
int swift_gzungetc(int c, void* file);
void swift_gzclearerr(void* file);
int swift_gzprintf_simple(void* file, const char* str);
int swift_gzgets_simple(void* file, char* buf, int len);

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
const char* swift_gzerror(void* file, int* errnum);

#endif /* ZLIB_SHIM_H */
