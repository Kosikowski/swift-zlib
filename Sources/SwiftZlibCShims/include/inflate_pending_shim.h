#ifndef SWIFT_ZLIB_INFLATE_PENDING_SHIM_H
#define SWIFT_ZLIB_INFLATE_PENDING_SHIM_H

#include <zlib.h>

int swift_inflatePending(z_stream *strm, unsigned int *pending, int *bits);

#endif // SWIFT_ZLIB_INFLATE_PENDING_SHIM_H
