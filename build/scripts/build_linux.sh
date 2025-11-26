#!/bin/bash
set -e

# Build the image using Dockerfile.linux
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t vlc-speed-hold-plugin-artifacts \
    -f Dockerfile.linux \
    --load \
    .

# Create a build directory
mkdir -p build/linux

# Extract the artifacts
docker run --rm \
    -v ./build/linux:/output \
    vlc-speed-hold-plugin-artifacts \
    /bin/sh -c "cp -r /plugins/* /output/"

echo "Build complete. The plugins are in the build/linux directory."
