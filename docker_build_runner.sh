#!/usr/bin/env bash
set -euo pipefail

build()
{
    VERSION=$1
    BITS=$2

    # 4.0 handling (Nightly)
    if [[ "$VERSION" == "4.0" ]]
    then
        LATEST_DIR_URL=$(lynx -listonly -nonumbers -dump "https://artifacts.videolan.org/vlc/nightly-win${BITS}-llvm/" | grep -P '\d{8}-\d+' | LC_COLLATE=C sort --stable --ignore-case | tail -n1)
        echo "Downloading 4.0 SDK from: $LATEST_DIR_URL"
        LATEST_FILE_URL=$(lynx -listonly -nonumbers -dump "$LATEST_DIR_URL" | grep ".7z$" | grep -v "debug" | tail -n1)
        
        if [ "$(echo "$LATEST_FILE_URL" | wc -l)" != "1" ]; then
            echo "Error: Weren't able to find the .7z file for VLC $VERSION"
            exit 1
        fi
        wget "$LATEST_FILE_URL" -O vlc-$VERSION.0-win${BITS}.7z
        7zr x "vlc-$VERSION.0-win${BITS}.7z" -o* "*/sdk"
    fi

    if [[ $BITS == "32" ]]
    then
        TOOLCHAIN=i686-w64-mingw32
    elif [[ $BITS == "64" ]]
    then
        TOOLCHAIN=x86_64-w64-mingw32
    fi
    
    # Destination inside the mounted build volume
    DESTDIR="/build/windows/$VERSION/$BITS"
    
    # Locate the extracted SDK
    # We search for a directory matching the pattern vlc-<version>*-win<bits>
    # This handles both vlc-3.0.0-win64 and vlc-3.0.21-win64
    
    SDK_BASE=$(find / -maxdepth 1 -name "vlc-${VERSION}*-win${BITS}" -type d | head -n 1)
    
    if [ -z "$SDK_BASE" ]; then
        echo "Error: Could not find SDK directory for version $VERSION and bits $BITS"
        echo "Expected pattern: /vlc-${VERSION}*-win${BITS}"
        ls -d /vlc*
        exit 1
    fi
    
    echo "Using SDK at: $SDK_BASE"
    
    cd "$SDK_BASE"/*/sdk

    sed -i "s|^prefix=.*|prefix=$PWD|g" lib/pkgconfig/*.pc
    export PKG_CONFIG_PATH="${PWD}/lib/pkgconfig"
    
    # Capture flags
    export VLC_CFLAGS=$(pkg-config --cflags vlc-plugin)
    export VLC_LIBS=$(pkg-config --libs vlc-plugin)

    if [ ! -f lib/vlccore.lib ]
    then
        echo "INPUT(libvlccore.lib)" > lib/vlccore.lib
    fi

    cd /repo
    
    # Clean previous builds
    make clean 

    # Build
    make libspeed_hold_plugin.dll CC=$TOOLCHAIN-gcc LD=$TOOLCHAIN-ld RC=$TOOLCHAIN-windres VLC_CFLAGS="$VLC_CFLAGS" VLC_LIBS="$VLC_LIBS"
    
    # Strip
    $TOOLCHAIN-strip libspeed_hold_plugin.dll

    mkdir -p $DESTDIR
    cp libspeed_hold_plugin.dll $DESTDIR
    
    if [[ "$VERSION" == "4.0" ]]
    then
        echo "$LATEST_DIR_URL" > $DESTDIR/VLC_DOWNLOAD_URL.txt
    fi
    chmod 777 -R "/build/windows/$VERSION"

    make clean

    cd /
}

if [[ "$1" == "all" ]]
then
    build 3.0.21 32
    build 3.0.21 64
else
    VERSION=$1
    BITS=$2

    if [ -z "$VERSION" ]
    then
        echo "Error: No VLC version specified."
        exit 1
    fi
    
    if [ -z "$BITS" ]
    then
        echo "Error: No bitness specified."
        exit 1
    fi

    build $VERSION $BITS
fi
