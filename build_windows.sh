#!/bin/bash
set -e

# Build the Windows build environment image
echo "Building Docker image..."
docker build -t vlc-speed-hold-plugin-windows-build -f Dockerfile.windows .

# Create the build directory if it doesn't exist
mkdir -p build

# Run the build
echo "Running build inside Docker container..."
# We mount the current directory to /repo
# We mount the build directory to /build
# We pass "all" to build 3.0.21 32-bit and 64-bit

docker run --rm \
    -v "$(pwd):/repo" \
    -v "$(pwd)/build:/build" \
    vlc-speed-hold-plugin-windows-build \
    all

echo "Build complete. Check the 'build' directory."
