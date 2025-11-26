#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/supSugam/vlc-speed-hold-plugin/master"
PLUGIN_NAME="libspeed_hold_plugin.dylib"
ARCH=$(uname -m)

if [ "$ARCH" == "arm64" ]; then
    REMOTE_PATH="build/macos/arm64/$PLUGIN_NAME"
elif [ "$ARCH" == "x86_64" ]; then
    REMOTE_PATH="build/macos/x64/$PLUGIN_NAME"
else
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

DOWNLOAD_URL="$REPO_URL/$REMOTE_PATH"

USER_PLUGIN_DIR="$HOME/Library/Application Support/org.videolan.vlc/plugins/video_filter"
mkdir -p "$USER_PLUGIN_DIR"

echo "Installing $PLUGIN_NAME for macOS ($ARCH)..."
echo "Target: $USER_PLUGIN_DIR"

echo "Downloading from $DOWNLOAD_URL..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$USER_PLUGIN_DIR/$PLUGIN_NAME" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$USER_PLUGIN_DIR/$PLUGIN_NAME" "$DOWNLOAD_URL"
else
    echo "Error: Neither curl nor wget found."
    exit 1
fi

echo "Success! Plugin installed."
echo "Please restart VLC and enable the plugin in Preferences > All > Video > Filters."
echo "Note: If the plugin does not show up, you may need to move it to /Applications/VLC.app/Contents/MacOS/plugins/"
