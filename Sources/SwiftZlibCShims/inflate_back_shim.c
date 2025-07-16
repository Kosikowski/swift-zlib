#include <zlib.h>
#include "include/inflate_back_shim.h"

int swift_inflateBackInit(z_stream *strm, int windowBits, unsigned char *window) {
    return inflateBackInit_(strm, windowBits, window, ZLIB_VERSION, (int)sizeof(z_stream));
}

int swift_inflateBackEnd(z_stream *strm) {
    return inflateBackEnd(strm);
}

int swift_inflateBackWithCallbacks(z_stream *strm,
                                   swift_inflate_input_cb input,
                                   void *input_context,
                                   swift_inflate_output_cb output,
                                   void *output_context) {
    // Bridge the C callbacks to zlib's inflateBack
    return inflateBack(strm,
                      (in_func)input, input_context,
                      (out_func)output, output_context);
}
