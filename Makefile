#
# General settings
#
LD = ld
CC = cc
DESTDIR =
INSTALL = install
CFLAGS = -g0 -O3 -Wall -Wextra -std=gnu11 -fPIC -fdiagnostics-color
CPPFLAGS = -DPIC -I. -Isrc -DMODULE_STRING=\"speed_hold\"
LDFLAGS =
SOURCES = src/speed_hold.c src/osd.c src/playback.c

# Read version info from src/version.h
VERSION_MAJOR_VAL := $(shell grep -m1 "VERSION_MAJOR" src/version.h | awk '{print $$3}')
VERSION_MINOR_VAL := $(shell grep -m1 "VERSION_MINOR" src/version.h | awk '{print $$3}')
VERSION_PATCH_VAL := $(shell grep -m1 "VERSION_PATCH" src/version.h | awk '{print $$3}')
VERSION_FULL_STR := "$(VERSION_MAJOR_VAL).$(VERSION_MINOR_VAL).$(VERSION_PATCH_VAL).0"

.PHONY: all linux install uninstall clean mostlyclean win32 win64 macos

#
# Default target: Linux
#
all: linux

# --- Linux Build ---
LINUX_VLC_CFLAGS = $(shell pkg-config --cflags vlc-plugin)
LINUX_VLC_LIBS = $(shell pkg-config --libs vlc-plugin)
LINUX_PLUGINDIR = $(shell pkg-config vlc-plugin --variable=pluginsdir)
LINUX_TARGET = libspeed_hold_plugin.so

linux: $(LINUX_TARGET)

$(LINUX_TARGET): CFLAGS += $(LINUX_VLC_CFLAGS)
$(LINUX_TARGET): $(SOURCES:%.c=%.o)
	$(CC) -shared -o $@ $^ $(LDFLAGS) $(LINUX_VLC_LIBS)

# --- macOS Build ---
MACOS_TARGET = libspeed_hold_plugin.dylib

macos: $(MACOS_TARGET)

$(MACOS_TARGET): $(SOURCES:%.c=%.o)
	$(CC) -dynamiclib -undefined dynamic_lookup -o $@ $^ $(LDFLAGS) $(VLC_LIBS)

install:
	mkdir -p -- $(DESTDIR)$(LINUX_PLUGINDIR)/video_filter
	$(INSTALL) --mode 0755 $(LINUX_TARGET) $(DESTDIR)$(LINUX_PLUGINDIR)/video_filter

uninstall:
	rm -f $(DESTDIR)$(LINUX_PLUGINDIR)/video_filter/$(LINUX_TARGET)


# --- Windows Build (Makefile logic) ---
WIN_RES = packaging/windows/version.rc.o

# Generic DLL target that uses passed-in CC, RC, etc.
libspeed_hold_plugin.dll: $(SOURCES:%.c=%.o) $(WIN_RES)
	$(CC) -shared -o $@ $^ $(LDFLAGS) $(VLC_LIBS)

# --- Common rules ---
%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(VLC_CFLAGS) -c -o $@ $<

$(WIN_RES): packaging/windows/version.rc.in
	sed -e "s/@VERSION_MAJOR@/$(VERSION_MAJOR_VAL)/g" \
	    -e "s/@VERSION_MINOR@/$(VERSION_MINOR_VAL)/g" \
	    -e "s/@VERSION_PATCH@/$(VERSION_PATCH_VAL)/g" \
	    -e "s/@VERSION_FULL_STR@/$(VERSION_FULL_STR)/g" \
	    $< > packaging/windows/version.rc
	$(RC) -o $@ packaging/windows/version.rc

# --- Clean target additions for Windows ---
clean:
	rm -f -- $(LINUX_TARGET) $(MACOS_TARGET) libspeed_hold_plugin.dll $(SOURCES:%.c=%.o) $(WIN_RES) packaging/windows/version.rc

mostlyclean: clean