#ifndef ZLIB_SIMPLE_H
#define ZLIB_SIMPLE_H

typedef unsigned char Bytef;
typedef unsigned int uInt;
typedef unsigned long uLong;
typedef unsigned long uLongf;
typedef long z_off_t;

#define Z_OK 0
#define Z_STREAM_END 1
#define Z_NEED_DICT 2
#define Z_ERRNO (-1)
#define Z_STREAM_ERROR (-2)
#define Z_DATA_ERROR (-3)
#define Z_MEM_ERROR (-4)
#define Z_BUF_ERROR (-5)
#define Z_VERSION_ERROR (-6)

#define Z_NO_FLUSH 0
#define Z_PARTIAL_FLUSH 1
#define Z_SYNC_FLUSH 2
#define Z_FULL_FLUSH 3
#define Z_FINISH 4
#define Z_BLOCK 5
#define Z_TREES 6

#define Z_FILTERED 1
#define Z_HUFFMAN_ONLY 2
#define Z_RLE 3
#define Z_FIXED 4
#define Z_DEFAULT_STRATEGY 0
#define Z_DEFLATED 8

#define Z_DEFAULT_COMPRESSION (-1)
#define Z_DEFAULT_LEVEL (-2)
#define Z_NULL 0

typedef struct z_stream_s {
    const Bytef *next_in;
    uInt avail_in;
    uLong total_in;
    Bytef *next_out;
    uInt avail_out;
    uLong total_out;
    const char *msg;
    struct internal_state *state;
    void *zalloc;
    void *zfree;
    void *opaque;
    int data_type;
    uLong adler;
    uLong reserved;
} z_stream;

typedef z_stream *z_streamp;

typedef struct gz_header_s {
    int text;
    uLong time;
    int xflags;
    int os;
    Bytef *extra;
    uInt extra_len;
    uInt extra_max;
    Bytef *name;
    uInt name_max;
    Bytef *comment;
    uInt comm_max;
    int hcrc;
    int done;
} gz_header;

typedef gz_header *gz_headerp;
typedef int (*in_func)(void *, unsigned char **);
typedef int (*out_func)(void *, unsigned char *, unsigned int);

int compress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);
int uncompress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);
int compress2(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen, int level);

int deflateInit(z_streamp strm, int level);
int deflate(z_streamp strm, int flush);
int deflateEnd(z_streamp strm);
int deflateInit2(z_streamp strm, int level, int method, int windowBits, int memLevel, int strategy);
int deflateParams(z_streamp strm, int level, int strategy);
int deflateReset(z_streamp strm);
int deflateCopy(z_streamp dest, z_streamp source);
int deflatePrime(z_streamp strm, int bits, int value);
int deflateBound(z_streamp strm, unsigned long sourceLen);
int deflateSetHeader(z_streamp strm, gz_headerp head);

int inflateInit(z_streamp strm);
int inflate(z_streamp strm, int flush);
int inflateEnd(z_streamp strm);
int inflateInit2(z_streamp strm, int windowBits);
int inflateReset(z_streamp strm);
int inflateCopy(z_streamp dest, z_streamp source);
int inflatePrime(z_streamp strm, int bits, int value);
int inflateGetHeader(z_streamp strm, gz_headerp head);
int inflateBack(z_streamp strm, in_func in, void *in_desc, out_func out, void *out_desc);
int inflateBackInit(z_streamp strm, int windowBits, unsigned char *window);
int inflateBackEnd(z_streamp strm);

uLong adler32(uLong adler, const Bytef *buf, uInt len);
uLong crc32(uLong crc, const Bytef *buf, uInt len);
uLong compressBound(uLong sourceLen);

const char* zlibVersion(void);
const char* zError(int err);

// Additional missing functions
int inflateMark(z_streamp strm);
unsigned long inflateCodesUsed(z_streamp strm);
int deflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);
int inflateSetDictionary(z_streamp strm, const Bytef *dictionary, uInt dictLength);
int deflatePending(z_streamp strm, unsigned *pending, int *bits);
int deflateTune(z_streamp strm, int good_length, int max_lazy, int nice_length, int max_chain);
int inflateSync(z_streamp strm);
int inflateSyncPoint(z_streamp strm);
int deflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);
int inflateGetDictionary(z_streamp strm, Bytef *dictionary, uInt *dictLength);
int inflatePending(z_streamp strm, unsigned *pending, int *bits);
uLong adler32_combine(uLong adler1, uLong adler2, z_off_t len2);
uLong crc32_combine(uLong crc1, uLong crc2, z_off_t len2);
uLong zlibCompileFlags(void);

// Gzip file operations
typedef struct gzFile_s *gzFile;
gzFile gzopen(const char* path, const char* mode);
int gzclose(gzFile file);
int gzread(gzFile file, void* buf, unsigned int len);
int gzwrite(gzFile file, void* buf, unsigned int len);
long gzseek(gzFile file, long offset, int whence);
long gztell(gzFile file);
int gzflush(gzFile file, int flush);
int gzrewind(gzFile file);
int gzeof(gzFile file);
int gzsetparams(gzFile file, int level, int strategy);
int gzprintf(gzFile file, const char* format, ...);
char* gzgets(gzFile file, char* buf, int len);
int gzputc(gzFile file, int c);
int gzgetc(gzFile file);
int gzungetc(int c, gzFile file);
void gzclearerr(gzFile file);
const char* gzerror(gzFile file, int* errnum);

#endif /* ZLIB_SIMPLE_H */
