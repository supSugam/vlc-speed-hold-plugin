#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/supSugam/vlc-speed-hold-plugin/master"
PLUGIN_NAME="libspeed_hold_plugin.so"

DOWNLOAD_URL="$REPO_URL/build/linux/$PLUGIN_NAME"

INSTALL_DIR="$HOME/.local/share/vlc/plugins/video_filter"

echo "Installing $PLUGIN_NAME for Linux..."

mkdir -p "$INSTALL_DIR"

echo "Downloading from $DOWNLOAD_URL..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$INSTALL_DIR/$PLUGIN_NAME" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$INSTALL_DIR/$PLUGIN_NAME" "$DOWNLOAD_URL"
else
    echo "Error: Neither curl nor wget found. Please install one of them."
    exit 1
fi

chmod 755 "$INSTALL_DIR/$PLUGIN_NAME"

echo "Success! Plugin installed to $INSTALL_DIR/$PLUGIN_NAME"
echo "Please restart VLC and enable the plugin in Preferences > All > Video > Filters."
