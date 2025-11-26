#!/usr/bin/env bash
set -euo pipefail

# This script is designed to run inside the Docker container

# 1. Locate VLC Source/Headers
# We downloaded the tarball to /vlc-3.0.21
VLC_SRC_DIR="/vlc-3.0.21"

if [ ! -d "$VLC_SRC_DIR" ]; then
    echo "Error: VLC source directory not found at $VLC_SRC_DIR"
    exit 1
fi

echo "Using VLC headers from: $VLC_SRC_DIR/include"

# Generate libvlc_version.h manually since we are using raw source
VERSION_HEADER="$VLC_SRC_DIR/include/vlc/libvlc_version.h"
if [ ! -f "$VERSION_HEADER" ]; then
    echo "Generating $VERSION_HEADER..."
    cp "$VLC_SRC_DIR/include/vlc/libvlc_version.h.in" "$VERSION_HEADER"
    sed -i 's/@VERSION_MAJOR@/3/g' "$VERSION_HEADER"
    sed -i 's/@VERSION_MINOR@/0/g' "$VERSION_HEADER"
    sed -i 's/@VERSION_REVISION@/21/g' "$VERSION_HEADER"
    sed -i 's/@VERSION_EXTRA@/0/g' "$VERSION_HEADER"
fi

# 2. Configure Zig Environment
# Zig is in PATH
echo "Zig version: $(zig version)"

# 3. Build for macOS (Intel)
# Target: x86_64-macos
# We use -I for headers
# We rely on -undefined dynamic_lookup to avoid needing libvlccore.dylib

export CC="zig cc -target x86_64-macos"
export CFLAGS="-I$VLC_SRC_DIR/include -I$VLC_SRC_DIR/include/vlc/plugins -D__PLUGIN__"
# Additional CFLAGS usually needed for VLC plugins
export CFLAGS="$CFLAGS -std=gnu11 -O3"

cd /repo

echo "Cleaning..."
make clean

echo "Building for macOS (x86_64)..."
# Pass CC and CFLAGS to make
# We might need to manually set VLC_CFLAGS because pkg-config won't work for cross-compile here easily
# without setting up a .pc file, but passing flags directly is easier.
make macos CC="$CC" VLC_CFLAGS="$CFLAGS" VLC_LIBS=""

# Move artifact
mkdir -p /build/macos/x64
mv libspeed_hold_plugin.dylib /build/macos/x64/

echo "macOS Build (x64) Complete."

# Ideally we would also build for arm64 (Apple Silicon)
echo "Building for macOS (arm64)..."
make clean

export CC="zig cc -target aarch64-macos"
make macos CC="$CC" VLC_CFLAGS="$CFLAGS" VLC_LIBS=""

mkdir -p /build/macos/arm64
mv libspeed_hold_plugin.dylib /build/macos/arm64/

echo "macOS Build (arm64) Complete."
