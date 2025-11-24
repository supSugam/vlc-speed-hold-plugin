#!/bin/bash

# This script automates the installation of the vlc-speed-hold-plugin.

make

# --- Configuration ---
PLUGIN_NAME="vlc-speed-hold-plugin"
SO_FILE="libspeed_hold_plugin.so"
VLC_PLUGIN_TYPE="video_filter"

# --- Functions ---

log_info() {
    echo "INFO: $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

# --- Main Script ---

log_info "Starting $PLUGIN_NAME installation..."

# 1. Check for necessary tools
if ! command -v pkg-config &> /dev/null; then
    log_error "pkg-config is not installed. Please install it (e.g., sudo apt-get install pkg-config) and try again."
    exit 1
fi

if ! command -v make &> /dev/null; then
    log_error "make is not installed. Please install it (e.g., sudo apt-get install make build-essential) and try again."
    exit 1
fi

if ! command -v gcc &> /dev/null; then
    log_error "GCC (C compiler) is not installed. Please install build-essential (e.g., sudo apt-get install build-essential) and try again."
    exit 1
fi

# 2. Locate VLC plugin directory
VLC_PLUGINS_DIR=$(pkg-config vlc-plugin --variable=pluginsdir)

if [ -z "$VLC_PLUGINS_DIR" ]; then
    log_error "Could not find VLC plugin directory using pkg-config. Make sure 'vlc-plugin-dev' or equivalent development package is installed."
    log_error "You might need to install 'vlc-plugin-dev' (Debian/Ubuntu) or 'vlc-devel' (Fedora) or similar for your distribution."
    exit 1
fi

TARGET_PLUGIN_DIR="$VLC_PLUGINS_DIR/$VLC_PLUGIN_TYPE"

log_info "VLC plugin directory detected: $TARGET_PLUGIN_DIR"

# 3. Compile the plugin
log_info "Compiling the plugin..."
make clean > /dev/null 2>&1
if ! make; then
    log_error "Plugin compilation failed."
    exit 1
fi
log_info "Plugin compiled successfully."

# 4. Install the plugin
log_info "Installing the plugin. This requires sudo privileges."
log_info "You will be prompted for your password."

sudo mkdir -p "$TARGET_PLUGIN_DIR"

if ! sudo install -m 0755 "$SO_FILE" "$TARGET_PLUGIN_DIR"; then
    log_error "Failed to install the plugin to $TARGET_PLUGIN_DIR."
    log_error "Please check permissions or try to install manually."
    exit 1
fi

log_info "Plugin '$SO_FILE' installed successfully to '$TARGET_PLUGIN_DIR'."
log_info "Installation complete!"

log_info "To enable the plugin in VLC:"
log_info "1. Open VLC."
log_info "2. Go to 'Tools > Preferences' and select 'All' for 'Show settings'."
log_info "3. Under 'Interface > Control Interfaces', check 'Pause/Speed Hold'."
log_info "4. Under 'Video > Filters', check 'Pause/Speed Hold'."
log_info "5. Save and restart VLC."
