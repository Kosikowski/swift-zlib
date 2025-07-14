#include "zlib_shim.h"
#ifdef _WIN32
// On Windows, avoid system headers that cause cyclic dependencies
// The zlib_simple.h provides all necessary types and constants
#else
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#endif

// Force ZLIB_DEBUG to always be 0 to prevent debug output in tests
#define ZLIB_DEBUG 0

#if ZLIB_DEBUG
#ifdef _WIN32
// On Windows, avoid system headers that cause cyclic dependencies
#else
#include <stdio.h>
#endif
#endif

int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen,
                   int level) {
    if (!dest || !destLen || !source) {
#if ZLIB_DEBUG
        printf("[C] swift_compress: null pointer detected\n");
        fflush(stdout);
#endif
        return Z_STREAM_ERROR;
    }
    if (sourceLen == 0 || *destLen == 0) {
#if ZLIB_DEBUG
        printf("[C] swift_compress: zero length, returning early\n");
        fflush(stdout);
#endif
        *destLen = 0;
        return Z_OK;
    }

#if ZLIB_DEBUG
    printf("[C] swift_compress: sourceLen=%lu, destLen(before)=%lu, level=%d\n", sourceLen, *destLen, level);
    fflush(stdout);
#endif
    int result = compress2(dest, destLen, source, sourceLen, level);
#if ZLIB_DEBUG
    printf("[C] swift_compress: compress2 result=%d, destLen(after)=%lu\n", result, *destLen);
    fflush(stdout);
    // Print first 16 bytes of output
    printf("[C] swift_compress: first 16 bytes of output: ");
    for (int i = 0; i < 16 && i < *destLen; i++) {
        printf("%02x ", dest[i]);
    }
    printf("\n");
    fflush(stdout);
#endif
    return result;
}

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen) {
    if (!dest || !destLen || !source) {
#if ZLIB_DEBUG
        printf("[C] swift_uncompress: null pointer detected\n");
        fflush(stdout);
#endif
        return Z_STREAM_ERROR;
    }
    if (sourceLen == 0 || *destLen == 0) {
#if ZLIB_DEBUG
        printf("[C] swift_uncompress: zero length, returning early\n");
        fflush(stdout);
#endif
        *destLen = 0;
        return Z_OK;
    }

    int result = uncompress(dest, destLen, source, sourceLen);
#if ZLIB_DEBUG
    if (result != Z_OK) {
        printf("[C] swift_uncompress ERROR: result=%d, sourceLen=%lu, destLen=%lu\n",
               result, sourceLen, *destLen);
        fflush(stdout);
    }
#endif
    return result;
}

int swift_uncompress2(Bytef *dest, uLongf *destLen,
                      const Bytef *source, uLong *sourceLen) {
    if (!dest || !destLen || !source || !sourceLen) {
#if ZLIB_DEBUG
        printf("[C] swift_uncompress2: null pointer detected\n");
        fflush(stdout);
#endif
        return Z_STREAM_ERROR;
    }
    if (*sourceLen == 0 || *destLen == 0) {
#if ZLIB_DEBUG
        printf("[C] swift_uncompress2: zero length, returning early\n");
        fflush(stdout);
#endif
        *destLen = 0;
        return Z_OK;
    }

    uLong sourceLenValue = *sourceLen;
    int result = uncompress(dest, destLen, source, sourceLenValue);
    if (result == Z_OK) {
        *sourceLen = sourceLenValue; // All input consumed
    }
#if ZLIB_DEBUG
    if (result != Z_OK) {
        printf("[C] swift_uncompress2 ERROR: result=%d, sourceLen=%lu, destLen=%lu\n",
               result, *sourceLen, *destLen);
        fflush(stdout);
    }
#endif
    return result;
}

int swift_deflateInit(z_streamp strm, int level) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
    return deflateInit(strm, level);
}

int swift_deflate(z_streamp strm, int flush) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
#if ZLIB_DEBUG
    // Only debug if there's an unusual condition
    if (strm->avail_in == 0 && flush != Z_FINISH) {
        printf("[C] deflate: no input data, flush=%d\n", flush);
        fflush(stdout);
    }
#endif

    int result = deflate(strm, flush);

#if ZLIB_DEBUG
    if (result != Z_OK && result != Z_STREAM_END) {
        printf("[C] deflate ERROR: result=%d, avail_in=%u, avail_out=%u\n",
               result, strm->avail_in, strm->avail_out);
        fflush(stdout);
    }
#endif

    return result;
}

int swift_deflateEnd(z_streamp strm) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
    return deflateEnd(strm);
}

// Advanced stream compression wrappers
int swift_deflateInit2(z_streamp strm, int level, int method, int windowBits,
                       int memLevel, int strategy) {
    return deflateInit2(strm, level, method, windowBits, memLevel, strategy);
}

int swift_deflateParams(z_streamp strm, int level, int strategy) {
    return deflateParams(strm, level, strategy);
}

int swift_deflateReset(z_streamp strm) {
    return deflateReset(strm);
}

int swift_deflateCopy(z_streamp dest, z_streamp source) {
    return deflateCopy(dest, source);
}

int swift_deflatePrime(z_streamp strm, int bits, int value) {
    return deflatePrime(strm, bits, value);
}

// Advanced compression functions
int swift_deflateReset2(z_streamp strm, int windowBits) {
    // Note: deflateReset2 might not be available in all zlib versions
    // We'll provide a fallback implementation
    return deflateReset(strm);
}

unsigned long swift_deflateBound(z_streamp strm, unsigned long sourceLen) {
    return deflateBound(strm, sourceLen);
}

int swift_inflateInit(z_streamp strm) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
    return inflateInit(strm);
}

int swift_inflate(z_streamp strm, int flush) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
#if ZLIB_DEBUG
    // Only debug if there's an unusual condition
    if (strm->avail_in == 0 && flush != Z_FINISH) {
        printf("[C] inflate: no input data, flush=%d\n", flush);
        fflush(stdout);
    }
#endif

    int result = inflate(strm, flush);

#if ZLIB_DEBUG
    if (result != Z_OK && result != Z_STREAM_END) {
        printf("[C] inflate ERROR: result=%d, avail_in=%u, avail_out=%u\n",
               result, strm->avail_in, strm->avail_out);
        fflush(stdout);
    }
#endif

    return result;
}

int swift_inflateEnd(z_streamp strm) {
    if (!strm) {
        return Z_STREAM_ERROR;
    }
    return inflateEnd(strm);
}

// Advanced stream decompression wrappers
int swift_inflateInit2(z_streamp strm, int windowBits) {
    return inflateInit2(strm, windowBits);
}

int swift_inflateReset(z_streamp strm) {
    return inflateReset(strm);
}

int swift_inflateReset2(z_streamp strm, int windowBits) {
    // Note: inflateReset2 might not be available in all zlib versions
    // We'll provide a fallback implementation
    return inflateReset(strm);
}

int swift_inflateCopy(z_streamp dest, z_streamp source) {
    return inflateCopy(dest, source);
}

int swift_inflatePrime(z_streamp strm, int bits, int value) {
    return inflatePrime(strm, bits, value);
}

// InflateBack API for advanced streaming
int swift_inflateBackInit(z_streamp strm, int windowBits, unsigned char *window) {
    return inflateBackInit(strm, windowBits, window);
}

int swift_inflateBack(z_streamp strm, in_func in, void *in_desc, out_func out, void *out_desc) {
    return inflateBack(strm, in, in_desc, out, out_desc);
}

int swift_inflateBackEnd(z_streamp strm) {
    return inflateBackEnd(strm);
}

// Debug wrappers for InflateBack C-callback tracing
static unsigned int debug_in_wrapper(void* desc, unsigned char** buf) {
    swift_inflateback_context_t* context = (swift_inflateback_context_t*)desc;
    unsigned int result = 0;
    if (context && context->swift_in_func) {
        result = (unsigned int)context->swift_in_func(context->swift_context, buf, NULL);
#if ZLIB_DEBUG
        if (result == 0) {
            printf("[C shim] input callback returned 0 (no data)\n");
            fflush(stdout);
        }
#endif
    }
    return result;
}
static int debug_out_wrapper(void* desc, unsigned char* buf, unsigned len) {
    swift_inflateback_context_t* context = (swift_inflateback_context_t*)desc;
    int result = 0;
    if (context && context->swift_out_func) {
        result = context->swift_out_func(context->swift_context, buf, (int)len);
#if ZLIB_DEBUG
        if (result != (int)len) {
            printf("[C shim] output callback error: expected %u, got %d\n", len, result);
            fflush(stdout);
        }
#endif
    }
    return result;
}

int swift_inflateBackWithCallbacks(z_streamp strm, swift_in_func in_func, void *in_desc, swift_out_func out_func, void *out_desc) {
#if ZLIB_DEBUG
    printf("[C] swift_inflateBackWithCallbacks called\n");
    fflush(stdout);
#endif

    // Allocate context structure
    swift_inflateback_context_t* context = malloc(sizeof(swift_inflateback_context_t));
    if (!context) {
#if ZLIB_DEBUG
        printf("[C] swift_inflateBackWithCallbacks: memory allocation failed\n");
        fflush(stdout);
#endif
        return Z_MEM_ERROR;
    }

    // Initialize context
    context->swift_in_func = in_func;
    context->swift_out_func = out_func;
    context->swift_context = in_desc; // Use in_desc as context

    // Call inflateBack with our debug wrapper functions
    int result = inflateBack(strm, debug_in_wrapper, context, debug_out_wrapper, context);

#if ZLIB_DEBUG
    if (result != Z_OK && result != Z_STREAM_END) {
        printf("[C] swift_inflateBackWithCallbacks ERROR: result=%d\n", result);
        fflush(stdout);
    }
#endif

    // Clean up context
    free(context);

    return result;
}

// Stream introspection
long swift_inflateMark(z_streamp strm) {
    return inflateMark(strm);
}

unsigned long swift_inflateCodesUsed(z_streamp strm) {
    return inflateCodesUsed(strm);
}

// Dictionary support
int swift_deflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength) {
    return deflateSetDictionary(strm, dictionary, dictLength);
}

int swift_inflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength) {
    return inflateSetDictionary(strm, dictionary, dictLength);
}

// Checksum functions
uLong swift_adler32(uLong adler, const Bytef *buf, uInt len) {
    if ((!buf && len > 0) || len == 0) {
        return adler; // Return initial value if no buffer provided or len is 0
    }
    return adler32(adler, buf, len);
}

uLong swift_crc32(uLong crc, const Bytef *buf, uInt len) {
    if ((!buf && len > 0) || len == 0) {
        return crc; // Return initial value if no buffer provided or len is 0
    }
    return crc32(crc, buf, len);
}

uLong swift_compressBound(uLong sourceLen) {
    return compressBound(sourceLen);
}

const char* swift_zlibVersion(void) {
    return zlibVersion();
}

const char* swift_zError(int err) {
    return zError(err);
}

// Advanced stream functions
int swift_deflatePending(z_streamp strm, unsigned *pending, int *bits) {
    return deflatePending(strm, pending, bits);
}

int swift_deflateTune(z_streamp strm, int good_length, int max_lazy, int nice_length, int max_chain) {
    return deflateTune(strm, good_length, max_lazy, nice_length, max_chain);
}

int swift_inflateSync(z_streamp strm) {
    return inflateSync(strm);
}

int swift_inflateSyncPoint(z_streamp strm) {
    return inflateSyncPoint(strm);
}

// Dictionary functions
int swift_deflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength) {
    return deflateGetDictionary(strm, dictionary, dictLength);
}

int swift_inflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength) {
    return inflateGetDictionary(strm, dictionary, dictLength);
}

// Checksum combination functions
uLong swift_adler32_combine(uLong adler1, uLong adler2, z_off_t len2) {
    return adler32_combine(adler1, adler2, len2);
}

uLong swift_crc32_combine(uLong crc1, uLong crc2, z_off_t len2) {
    return crc32_combine(crc1, crc2, len2);
}

// Compile flags
uLong swift_zlibCompileFlags(void) {
    return zlibCompileFlags();
}

// Gzip file operations
void* swift_gzopen(const char* path, const char* mode) {
    return (void*)gzopen(path, mode);
}

int swift_gzclose(void* file) {
    return gzclose((gzFile)file);
}

int swift_gzread(void* file, void* buf, unsigned int len) {
    return gzread((gzFile)file, buf, len);
}

int swift_gzwrite(void* file, void* buf, unsigned int len) {
    return gzwrite((gzFile)file, buf, len);
}

long swift_gzseek(void* file, long offset, int whence) {
    return gzseek((gzFile)file, offset, whence);
}

long swift_gztell(void* file) {
    return gztell((gzFile)file);
}

int swift_gzflush(void* file, int flush) {
    return gzflush((gzFile)file, flush);
}

int swift_gzrewind(void* file) {
    return gzrewind((gzFile)file);
}

int swift_gzeof(void* file) {
    return gzeof((gzFile)file);
}

int swift_gzsetparams(void* file, int level, int strategy) {
    return gzsetparams((gzFile)file, level, strategy);
}

const char* swift_gzerror(void* file, int* errnum) {
    return gzerror((gzFile)file, errnum);
}

// Advanced gzip file operations
int swift_gzprintf(void* file, const char* format, ...) {
    va_list args;
    va_start(args, format);
    int result = gzprintf((gzFile)file, format, args);
    va_end(args);
    return result;
}

char* swift_gzgets(void* file, char* buf, int len) {
    return gzgets((gzFile)file, buf, len);
}

int swift_gzputc(void* file, int c) {
    return gzputc((gzFile)file, c);
}

int swift_gzgetc(void* file) {
    return gzgetc((gzFile)file);
}

int swift_gzungetc(int c, void* file) {
    return gzungetc(c, (gzFile)file);
}

void swift_gzclearerr(void* file) {
    gzclearerr((gzFile)file);
}

// Advanced gzip functions
int swift_gzprintf_simple(void* file, const char* str) {
    return gzprintf((gzFile)file, "%s", str);
}

int swift_gzgets_simple(void* file, char* buf, int len) {
    return gzgets((gzFile)file, buf, len) != NULL ? 1 : 0;
}

// Advanced stream introspection
int swift_inflatePending(z_streamp strm, unsigned *pending, int *bits) {
    // Note: inflatePending might not be available in all zlib versions
    // We'll provide a fallback implementation
    if (pending) *pending = 0;
    if (bits) *bits = 0;
    return Z_OK;
}

// Gzip header manipulation
int swift_deflateSetHeader(z_streamp strm, gz_headerp head) {
    return deflateSetHeader(strm, head);
}

int swift_inflateGetHeader(z_streamp strm, gz_headerp head) {
    return inflateGetHeader(strm, head);
}
