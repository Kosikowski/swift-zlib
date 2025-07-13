#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

int main() {
    // Test data - a simple string
    const char* test_data = "Hello, World! This is a test string for compression.";
    uLong data_len = strlen(test_data);

    // Dictionary - use the same as the test data prefix
    const char* dict = "Hello, World! This is a test string";
    uLong dict_len = strlen(dict);

    printf("=== Zlib Dictionary Test ===\n");
    printf("Test data: %s\n", test_data);
    printf("Dictionary: %s\n", dict);
    printf("Data length: %lu\n", dict_len);
    printf("Dictionary length: %lu\n", dict_len);

    // Step 1: Compress with dictionary
    printf("\n--- Step 1: Compress with dictionary ---\n");

    z_stream c_stream;
    memset(&c_stream, 0, sizeof(z_stream));

    int ret = deflateInit(&c_stream, Z_DEFAULT_COMPRESSION);
    if (ret != Z_OK) {
        printf("deflateInit failed: %d\n", ret);
        return 1;
    }

    // Set dictionary for compression
    ret = deflateSetDictionary(&c_stream, (const Bytef*)dict, dict_len);
    if (ret != Z_OK) {
        printf("deflateSetDictionary failed: %d\n", ret);
        deflateEnd(&c_stream);
        return 1;
    }
    printf("deflateSetDictionary succeeded\n");

    // Compress
    uLong compressed_size = deflateBound(&c_stream, data_len);
    Bytef* compressed = malloc(compressed_size);

    c_stream.next_in = (Bytef*)test_data;
    c_stream.avail_in = data_len;
    c_stream.next_out = compressed;
    c_stream.avail_out = compressed_size;

    ret = deflate(&c_stream, Z_FINISH);
    if (ret != Z_STREAM_END) {
        printf("deflate failed: %d\n", ret);
        free(compressed);
        deflateEnd(&c_stream);
        return 1;
    }

    uLong actual_compressed_size = compressed_size - c_stream.avail_out;
    printf("Compression successful, size: %lu -> %lu\n", data_len, actual_compressed_size);

    deflateEnd(&c_stream);

    // Step 2: Try to decompress WITHOUT dictionary (should fail)
    printf("\n--- Step 2: Decompress WITHOUT dictionary ---\n");

    z_stream d_stream1;
    memset(&d_stream1, 0, sizeof(z_stream));

    ret = inflateInit(&d_stream1);
    if (ret != Z_OK) {
        printf("inflateInit2 failed: %d\n", ret);
        free(compressed);
        return 1;
    }

    Bytef* decompressed1 = malloc(data_len + 1);
    d_stream1.next_in = compressed;
    d_stream1.avail_in = actual_compressed_size;
    d_stream1.next_out = decompressed1;
    d_stream1.avail_out = data_len + 1;

    ret = inflate(&d_stream1, Z_FINISH);
    printf("inflate without dictionary returned: %d\n", ret);

    if (ret == Z_NEED_DICT) {
        printf("Got Z_NEED_DICT as expected\n");
    } else if (ret == Z_DATA_ERROR) {
        printf("Got Z_DATA_ERROR (also acceptable)\n");
    } else {
        printf("Unexpected return code\n");
    }

    inflateEnd(&d_stream1);
    free(decompressed1);

    // Step 3: Try to set dictionary after Z_NEED_DICT (should fail)
    printf("\n--- Step 3: Try to set dictionary after Z_NEED_DICT ---\n");

    z_stream d_stream2;
    memset(&d_stream2, 0, sizeof(z_stream));

    ret = inflateInit(&d_stream2);
    if (ret != Z_OK) {
        printf("inflateInit failed: %d\n", ret);
        free(compressed);
        return 1;
    }

    d_stream2.next_in = compressed;
    d_stream2.avail_in = actual_compressed_size;

    // Try to decompress first
    ret = inflate(&d_stream2, Z_NO_FLUSH);
    printf("First inflate call returned: %d\n", ret);

    if (ret == Z_NEED_DICT) {
        printf("Got Z_NEED_DICT, now trying to set dictionary...\n");

        // Try to set dictionary
        ret = inflateSetDictionary(&d_stream2, (const Bytef*)dict, dict_len);
        printf("inflateSetDictionary returned: %d\n", ret);

        if (ret == Z_STREAM_ERROR) {
            printf("Z_STREAM_ERROR as expected - cannot set dictionary at this point\n");
        } else if (ret == Z_OK) {
            printf("Dictionary set successfully (unexpected)\n");
        } else {
            printf("Unexpected return code: %d\n", ret);
        }
    }

    inflateEnd(&d_stream2);

    // Step 4: Decompress WITH dictionary (should succeed)
    printf("\n--- Step 4: Decompress WITH dictionary ---\n");

    z_stream d_stream3;
    memset(&d_stream3, 0, sizeof(z_stream));

    ret = inflateInit(&d_stream3);
    if (ret != Z_OK) {
        printf("inflateInit failed: %d\n", ret);
        free(compressed);
        return 1;
    }

    // Set dictionary BEFORE decompressing
    ret = inflateSetDictionary(&d_stream3, (const Bytef*)dict, dict_len);
    if (ret != Z_OK) {
        printf("inflateSetDictionary failed: %d\n", ret);
        inflateEnd(&d_stream3);
        free(compressed);
        return 1;
    }
    printf("Dictionary set successfully\n");

    Bytef* decompressed3 = malloc(data_len + 1);
    d_stream3.next_in = compressed;
    d_stream3.avail_in = actual_compressed_size;
    d_stream3.next_out = decompressed3;
    d_stream3.avail_out = data_len + 1;

    ret = inflate(&d_stream3, Z_FINISH);
    printf("inflate with dictionary returned: %d\n", ret);

    if (ret == Z_STREAM_END) {
        decompressed3[d_stream3.total_out] = '\0';
        printf("Decompression successful!\n");
        printf("Original: %s\n", test_data);
        printf("Decompressed: %s\n", decompressed3);

        if (strcmp(test_data, (char*)decompressed3) == 0) {
            printf("Data matches! ✓\n");
        } else {
            printf("Data mismatch! ✗\n");
        }
    } else {
        printf("Decompression failed: %d\n", ret);
    }

    inflateEnd(&d_stream3);
    free(decompressed3);
    free(compressed);

    printf("\n=== Test completed ===\n");
    return 0;
}
