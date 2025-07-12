#include "zlib_shim.h"

int swift_compress(Bytef *dest, uLongf *destLen,
                   const Bytef *source, uLong sourceLen,
                   int level) {
    return compress2(dest, destLen, source, sourceLen, level);
}

int swift_uncompress(Bytef *dest, uLongf *destLen,
                     const Bytef *source, uLong sourceLen) {
    return uncompress(dest, destLen, source, sourceLen);
}

int swift_uncompress2(Bytef *dest, uLongf *destLen,
                      const Bytef *source, uLong *sourceLen) {
    return uncompress2(dest, destLen, source, sourceLen);
}

int swift_deflateInit(z_streamp strm, int level) {
    return deflateInit(strm, level);
}

int swift_deflate(z_streamp strm, int flush) {
    return deflate(strm, flush);
}

int swift_deflateEnd(z_streamp strm) {
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

int swift_inflateInit(z_streamp strm) {
    return inflateInit(strm);
}

int swift_inflate(z_streamp strm, int flush) {
    return inflate(strm, flush);
}

int swift_inflateEnd(z_streamp strm) {
    return inflateEnd(strm);
}

// Advanced stream decompression wrappers
int swift_inflateInit2(z_streamp strm, int windowBits) {
    return inflateInit2(strm, windowBits);
}

int swift_inflateReset(z_streamp strm) {
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

// InflateBack with Swift callback support
static int swift_in_wrapper(void* desc, unsigned char** buf) {
    // Extract the Swift callback and buffer from desc
    // This is a simplified version - in practice we'd need more complex memory management
    return 0; // Placeholder
}

static int swift_out_wrapper(void* desc, unsigned char* buf, unsigned len) {
    // Extract the Swift callback from desc and call it
    // This is a simplified version - in practice we'd need more complex memory management
    return 0; // Placeholder
}

int swift_inflateBackWithCallbacks(z_streamp strm, swift_in_func in_func, void *in_desc, swift_out_func out_func, void *out_desc) {
    // For now, we'll use a simplified approach
    // In a full implementation, we'd need to create proper wrapper functions
    // that can bridge between Swift closures and zlib's callback expectations
    return Z_STREAM_ERROR; // Placeholder - full implementation would be complex
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
    return adler32(adler, buf, len);
}

uLong swift_crc32(uLong crc, const Bytef *buf, uInt len) {
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

uLong swift_deflateBound(z_streamp strm, uLong sourceLen) {
    return deflateBound(strm, sourceLen);
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

// Gzip header manipulation
int swift_deflateSetHeader(z_streamp strm, gz_headerp head) {
    return deflateSetHeader(strm, head);
}

int swift_inflateGetHeader(z_streamp strm, gz_headerp head) {
    return inflateGetHeader(strm, head);
} 