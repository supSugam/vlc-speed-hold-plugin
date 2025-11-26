#!/bin/bash
set -e

echo "Building Docker image for macOS cross-compilation..."
docker build --no-cache -t vlc-plugin-builder-macos -f Dockerfile.macos .

echo "Running build inside Docker container..."
mkdir -p build/macos

docker run --rm \
    -v "$(pwd):/repo" \
    -v "$(pwd)/build:/build" \
    vlc-plugin-builder-macos

echo "Build complete. Check build/macos/"
