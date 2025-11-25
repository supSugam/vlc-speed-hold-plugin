#!/bin/bash
set -e

# Build the Windows build environment
docker build --no-cache -t vlc-plugin-builder-windows -f Dockerfile.windows .

# Create the output directory
mkdir -p build/windows/x86
mkdir -p build/windows/x64

build_windows_target() {
    VERSION="3.0.21" # Using the version from the downloaded SDKs
    BITS=$1

    if [[ $BITS == "32" ]]
    then
        TOOLCHAIN=i686-w64-mingw32
        SDK_PATH=/opt/vlc-${VERSION}-win32
    elif [[ $BITS == "64" ]]
    then
        TOOLCHAIN=x86_64-w64-mingw32
        SDK_PATH=/opt/vlc-${VERSION}-win64
    fi
    
    echo "Building for Windows ${BITS}-bit..."

    # Navigate to SDK directory within the container for pkg-config setup
    docker run --rm -v $(pwd):/repo vlc-plugin-builder-windows bash -c " 
        cd ${SDK_PATH}/sdk && 
        sed -i 's|^prefix=.*|prefix=$PWD|g' lib/pkgconfig/*.pc && 
        export PKG_CONFIG_PATH='${PWD}/lib/pkgconfig' && 
        [ ! -f lib/vlccore.lib ] && echo 'INPUT(libvlccore.lib)' > lib/vlccore.lib && 
        cd /repo && 
        make clean OS=Windows && 
        make CC=${TOOLCHAIN}-gcc LD=${TOOLCHAIN}-ld RC=${TOOLCHAIN}-windres OS=Windows && 
        cp libspeed_hold_plugin.dll /repo/libspeed_hold_plugin_${BITS}.dll && 
        make clean OS=Windows 
    "

    mv libspeed_hold_plugin_${BITS}.dll build/windows/x${BITS}/libspeed_hold_plugin.dll
}

# Perform 32-bit build
build_windows_target 32

# Perform 64-bit build
build_windows_target 64

echo "Windows builds complete. The plugins are in the build/windows directory."
