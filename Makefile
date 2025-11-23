LD = ld
CC = cc
OS = Linux
DESTDIR =
INSTALL = install
CFLAGS = -g0 -O3 -Wall -Wextra
LDFLAGS =
VLC_PLUGIN_CFLAGS := $(shell pkg-config --cflags vlc-plugin)
VLC_PLUGIN_LIBS := $(shell pkg-config --libs vlc-plugin)

plugindir := $(shell pkg-config vlc-plugin --variable=pluginsdir)

override CC += -std=gnu11
override CPPFLAGS += -DPIC -I. -Isrc
override CFLAGS += -fPIC -fdiagnostics-color

override CPPFLAGS += -DMODULE_STRING=\"speed_hold\"
override CFLAGS += $(VLC_PLUGIN_CFLAGS)
override LDFLAGS += $(VLC_PLUGIN_LIBS)

ifeq ($(OS),Linux)
  EXT := so
else ifeq ($(OS),Windows)
  EXT := dll
  RES := packaging/windows/version.rc.o
else ifeq ($(OS),macOS)
  EXT := dylib
else
  $(error Unknown OS specified, please set OS to either Linux, Windows or macOS)
endif

TARGETS = libspeed_hold_plugin.$(EXT)

all: libspeed_hold_plugin.$(EXT)

install: all
	mkdir -p -- $(DESTDIR)$(plugindir)/video_filter
	$(INSTALL) --mode 0755 libspeed_hold_plugin.$(EXT) $(DESTDIR)$(plugindir)/video_filter

install-strip:
	$(MAKE) install INSTALL="$(INSTALL) -s"

uninstall:
	rm -f $(DESTDIR)$(plugindir)/video_filter/libspeed_hold_plugin.$(EXT)

clean:
	rm -f -- libspeed_hold_plugin.$(EXT) src/*.o packaging/windows/*.o

mostlyclean: clean

SOURCES = src/speed_hold.c

$(SOURCES:%.c=%.o): %: src/speed_hold.c src/version.h

%.rc.o: %.rc
	$(RC) -o $@ $< $(VLC_PLUGIN_CFLAGS) -I.

%.rc:

libspeed_hold_plugin.$(EXT): $(SOURCES:%.c=%.o) $(RES)
	$(CC) -shared -o $@ $^ $(LDFLAGS)

.PHONY: all install install-strip uninstall clean mostlyclean
