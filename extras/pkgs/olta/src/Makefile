CC      ?= cc
CFLAGS  ?= -O2 -g -std=c11 -Wall -Wextra -pthread -Ivendor -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE
SRC     := $(wildcard src/*.c) vendor/cJSON.c
OBJ     := $(SRC:.c=.o)

olta: $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $@

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

vendor/%.o: vendor/%.c
	$(CC) $(CFLAGS) -c $< -o $@

run: olta
	./olta

# debug build with sanitizers (slow, catches leaks/UAB)
asan:
	$(CC) $(CFLAGS) -fsanitize=address,undefined $(SRC) -o olta-asan

clean:
	rm -f olta olta-asan $(OBJ)

.PHONY: run clean
