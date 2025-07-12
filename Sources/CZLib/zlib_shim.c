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

int swift_deflateInit(z_streamp strm, int level) {
    return deflateInit(strm, level);
}

int swift_deflate(z_streamp strm, int flush) {
    return deflate(strm, flush);
}

int swift_deflateEnd(z_streamp strm) {
    return deflateEnd(strm);
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

uLong swift_compressBound(uLong sourceLen) {
    return compressBound(sourceLen);
}

const char* swift_zlibVersion(void) {
    return zlibVersion();
} 