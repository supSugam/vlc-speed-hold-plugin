#!/bin/bash
set -e

# Simple build script for Linux
# Assumes build tools and VLC dev libs are installed on the host

echo "Building for Linux..."

# Check dependencies
if ! pkg-config --exists vlc-plugin; then
    echo "Error: vlc-plugin pkg-config not found. Please install libvlc-dev / libvlccore-dev."
    exit 1
fi

make clean
make linux

# Output directory
mkdir -p build/linux

# Move artifact
mv libspeed_hold_plugin.so build/linux/

echo "Linux build complete. Artifact in build/linux/libspeed_hold_plugin.so"
