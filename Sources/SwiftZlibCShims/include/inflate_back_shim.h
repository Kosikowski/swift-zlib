#ifndef SWIFT_ZLIB_INFLATE_BACK_SHIM_H
#define SWIFT_ZLIB_INFLATE_BACK_SHIM_H

#include <zlib.h>

int swift_inflateBackInit(z_stream *strm, int windowBits, unsigned char *window);
int swift_inflateBackEnd(z_stream *strm);
typedef int (*swift_inflate_input_cb)(void *context, unsigned char **buffer, int *length);
typedef int (*swift_inflate_output_cb)(void *context, unsigned char *buffer, int length);
int swift_inflateBackWithCallbacks(z_stream *strm,
                                   swift_inflate_input_cb input,
                                   void *input_context,
                                   swift_inflate_output_cb output,
                                   void *output_context);

#endif // SWIFT_ZLIB_INFLATE_BACK_SHIM_H
