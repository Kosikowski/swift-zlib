CC ?= cc
CFLAGS ?= -O2 -Wall
LDFLAGS ?= -lz

TESTS = \
	test_zlib_dict \
	test_zlib_dict_checksum \
	test_zlib_example \
	test_zlib_simple

all: $(TESTS)

%: %.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

run: all
	@for t in $(TESTS); do \
		echo "Running $$t..."; \
		./$$t || exit 1; \
	echo; \
	done

clean:
	rm -f $(TESTS)
