# Installation script for Windows (PowerShell)
# Usage: Run in PowerShell as Administrator

$ErrorActionPreference = "Stop"

function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "This script requires Administrator privileges to write to the VLC installation directory. Please run PowerShell as Administrator."
    exit 1
}

$RepoUrl = "https://raw.githubusercontent.com/ctrlcat/vlc-speed-hold-plugin/master"
$PluginName = "libspeed_hold_plugin.dll"

$Vlc64Path = "C:\Program Files\VideoLAN\VLC"
$Vlc32Path = "C:\Program Files (x86)\VideoLAN\VLC"
$TargetDir = $null
$Bits = "64"

if (Test-Path $Vlc64Path) {
    Write-Host "Detected 64-bit VLC installation at $Vlc64Path"
    $TargetDir = "$Vlc64Path\plugins\video_filter"
    $Bits = "64"
} elseif (Test-Path $Vlc32Path) {
    Write-Host "Detected 32-bit VLC installation at $Vlc32Path"
    $TargetDir = "$Vlc32Path\plugins\video_filter"
    $Bits = "32"
} else {
    Write-Error "VLC installation not found in standard locations. Please install the plugin manually."
    exit 1
}

$RemotePath = "build/windows/3.0.21/$Bits/$PluginName"
$DownloadUrl = "$RepoUrl/$RemotePath"

Write-Host "Installing $PluginName for Windows ($Bits-bit)..."
Write-Host "Target: $TargetDir"
Write-Host "Downloading from $DownloadUrl"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
}

$OutputFile = Join-Path $TargetDir $PluginName

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutputFile
    Write-Host "Success! Plugin installed to $OutputFile"
    Write-Host "Please restart VLC and enable the plugin in Preferences > All > Video > Filters."
} catch {
    Write-Error "Failed to download plugin: $_"
    exit 1
}
