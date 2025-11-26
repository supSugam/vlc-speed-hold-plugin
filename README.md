# Speed Hold Plugin for VLC

VLC plugin that allows you to speed up playback while holding down a mouse button. 

When you release the button, playback speed returns to normal. This is useful for quickly fast-forwarding through boring parts of a video.

---

**Important Notes:**

*   This plugin is currently **designed and tested only for VLC 3.0.21**. Compatibility with other VLC versions is not guaranteed.
*   This project is very closely inspired by [nurupo/vlc-pause-click-plugin](https://github.com/nurupo/vlc-pause-click-plugin).
*   If you have the `vlc-pause-click-plugin` by nurupo installed, you **must disable it** for this plugin to function correctly, as they both utilize similar control interface mechanisms.
*   The plugin files and installation scripts have been generated and tested in a controlled environment but **have not been extensively tested on all target machines (Windows, macOS, Linux)**. If you encounter any issues, please report them!

---

## 🚀 Installation

### Automatic Installation (Recommended)

You can use the following one-liner commands to automatically download and install the plugin for your system.

**Heads up!** For these automatic installers to work, the pre-compiled plugin binaries (`.dll`, `.dylib`, `.so`) **must be available** at the specified GitHub raw content URLs. This usually means either:
1.  **Committing the `build/` directory** directly to your repository (make sure it's not ignored by `.gitignore`!). This is generally suitable for smaller projects or testing.
2.  **Creating a GitHub Release** and uploading the binaries as assets. If you choose this, remember to update the `REPO_URL` variable inside the respective installer scripts to point to your release assets.

#### For Linux 🐧

Open a terminal and run:
```bash
curl -sL https://raw.githubusercontent.com/supSugam/vlc-speed-hold-plugin/master/installer/install_linux.sh | bash
```

#### For macOS 🍎

Open a terminal and run:
```bash
curl -sL https://raw.githubusercontent.com/supSugam/vlc-speed-hold-plugin/master/installer/install_macos.sh | bash
```

#### For Windows 🪟

Open PowerShell **as Administrator** and run:
```powershell
irm https://raw.githubusercontent.com/supSugam/vlc-speed-hold-plugin/master/installer/install_windows.ps1 | iex
```

### Manual Installation

If automatic installation isn't your style or doesn't work, here's how to do it by hand:

#### Windows

1.  Download the appropriate `.dll` file for your VLC version and architecture (32-bit or 64-bit) from the [Releases page](../../releases).
2.  Go to your VLC installation directory (usually `C:\Program Files\VideoLAN\VLC` or `C:\Program Files (x86)\VideoLAN\VLC`).
3.  Navigate to the `plugins\video_filter` subfolder.
4.  Copy `libspeed_hold_plugin.dll` into this folder.

#### macOS

1.  Download `libspeed_hold_plugin.dylib` from the [Releases page](../../releases).
2.  Open Finder and navigate to `/Applications/VLC.app`.
3.  Right-click VLC and select **Show Package Contents**.
4.  Browse to `Contents/MacOS/plugins/` (create the `plugins` folder if it doesn't exist).
5.  Copy `libspeed_hold_plugin.dylib` into this folder.

#### Linux

**Building from source (Debian/Ubuntu example):**

If you prefer to build the plugin yourself:

```bash
# 1. Install necessary build tools and VLC development libraries
sudo apt-get update
sudo apt-get install build-essential pkg-config libvlccore-dev libvlc-dev git

# 2. Clone the repository
git clone https://github.com/supSugam/vlc-speed-hold-plugin.git
cd vlc-speed-hold-plugin

# 3. Build and install the plugin
make
sudo make install
```

## 🖥️ Usage

Once installed, follow these steps to activate and configure the plugin in VLC:

1.  **Restart VLC** completely to load the newly added plugin.
2.  Go to **Tools -> Preferences** (or `VLC -> Preferences` on macOS).
3.  At the bottom left, set **Show settings** to **All**.
4.  In the left sidebar, navigate to **Interface -> Control Interfaces**.
5.  Check the box for **Speed Hold**.
6.  In the left sidebar, navigate to **Video -> Filters**.
7.  Check the box for **Speed Hold**.
8.  Still under **Video -> Filters**, expand the section and click on **Speed Hold** to access its specific settings.
9.  Configure your desired **Fast Forward Speed** (default is 3.0x) and choose the **Mouse Button** you want to use for activation.
10. **Save** your changes and **restart VLC** one more time for the settings to take full effect.

Now, play any video and experiment with holding down your chosen mouse button to experience the speed hold!

## ❓ Troubleshooting

*   **Plugin not showing up?**
    *   Ensure you downloaded the correct version (32-bit vs 64-bit) matching your VLC installation.
    *   Verify the plugin file is in the correct directory.
    *   Try running VLC with `--reset-plugins-cache` once from your terminal to force a plugin refresh.
*   **Settings not saving?**
    *   Make sure to click "Save" in the preferences window and restart VLC.
*   **Facing a bug or unexpected behavior?**
    *   Please open an issue on the [GitHub repository](https://github.com/supSugam/vlc-speed-hold-plugin) with details about your operating system, VLC version, and the steps to reproduce the issue.

## 📄 License

This project is licensed under the LGPL-2.1-or-later License. See the [LICENSE](LICENSE) file for details.
