#include <zlib.h>

int swift_inflatePending(z_stream *strm, unsigned int *pending, int *bits) {
    return inflatePending(strm, pending, bits);
}
