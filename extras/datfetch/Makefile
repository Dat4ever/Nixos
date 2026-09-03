CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra
PREFIX ?= /usr/local

SRC = \
	src/main.c \
	src/util.c \
	src/distro.c \
	src/config.c \
	src/sysinfo.c \
	src/render.c \
	src/modules/host.c \
	src/modules/kernel.c \
	src/modules/uptime.c \
	src/modules/packages.c \
	src/modules/shell.c \
	src/modules/desktop.c \
	src/modules/terminal.c \
	src/modules/font.c \
	src/modules/resolution.c \
	src/modules/cpu.c \
	src/modules/gpu.c \
	src/modules/memory.c \
	src/modules/disk.c \
	src/modules/local_ip.c \
	src/modules/installed.c

OBJ = $(SRC:.c=.o)

datfetch: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean install

clean:
	rm -f datfetch $(OBJ)

install: datfetch
	install -Dm755 datfetch $(DESTDIR)$(PREFIX)/bin/datfetch
