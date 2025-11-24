#!/bin/bash

# This script automates the installation of the vlc-speed-hold-plugin for macOS.

PLUGIN_NAME="vlc-speed-hold-plugin"
DYLIB_FILE="libspeed_hold_plugin.dylib"
VLC_APP_BUNDLE="/Applications/VLC.app"
TARGET_PLUGIN_DIR="$VLC_APP_BUNDLE/Contents/MacOS/plugins/"

log_info() {
    echo "INFO: $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

log_info "Starting $PLUGIN_NAME installation for macOS..."

# 1. Check if VLC.app exists
if [ ! -d "$VLC_APP_BUNDLE" ]; then
    log_error "VLC application not found in $VLC_APP_BUNDLE."
    log_error "Please ensure VLC is installed in the Applications folder."
    exit 1
fi

# 2. Ensure the dylib file exists before attempting to install
if [ ! -f "$DYLIB_FILE" ]; then
    log_error "Plugin file '$DYLIB_FILE' not found in the current directory."
    log_error "Please place the compiled plugin file (e.g., 'libspeed_hold_plugin.dylib') in the same directory as this script."
    exit 1
fi

# 3. Create target directory if it doesn't exist
log_info "Creating target plugin directory: $TARGET_PLUGIN_DIR"
sudo mkdir -p "$TARGET_PLUGIN_DIR"

# 4. Install the plugin
log_info "Installing the plugin. This requires sudo privileges."
log_info "You will be prompted for your password."

if ! sudo cp "$DYLIB_FILE" "$TARGET_PLUGIN_DIR"; then
    log_error "Failed to copy the plugin to $TARGET_PLUGIN_DIR."
    log_error "Please check permissions or try to install manually."
    exit 1
fi

log_info "Plugin '$DYLIB_FILE' installed successfully to '$TARGET_PLUGIN_DIR'."
log_info "Installation complete!"

log_info "To enable the plugin in VLC:"
log_info "1. Open VLC."
log_info "2. Go to 'Tools > Preferences' and select 'All' for 'Show settings'."
log_info "3. Under 'Interface > Control Interfaces', check 'Pause/Speed Hold'."
log_info "4. Under 'Video > Filters', check 'Pause/Speed Hold'."
log_info "5. Save and restart VLC."
