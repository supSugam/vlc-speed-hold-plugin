; Script for the VLC Speed Hold Plugin installer

; The name of the installer
Name "VLC Speed Hold Plugin"

; The file to write the installer to
OutFile "VLC-Speed-Hold-Plugin-Installer.exe"

; The default installation directory (not really used as we detect VLC path)
InstallDir "$PROGRAMFILES\VideoLAN\VLC"

; Request privileges for installation
RequestExecutionLevel admin

; Modern UI settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_WELCOMEFINISHPAGE_NOFUNCTION
!define MUI_FINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY ; This page will be skipped if VLC path is detected.
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Variables to store VLC paths
Var VLC32_PATH
Var VLC64_PATH
Var TARGET_VLC_PATH

; The actual installation section
Section "VLC Speed Hold Plugin (required)"

  SectionIn RO

  ; Check for 64-bit VLC
  ReadRegStr $VLC64_PATH HKLM "Software\VideoLAN\VLC" ""
  ${If} $VLC64_PATH == ""
    ReadRegStr $VLC64_PATH HKLM "Software\WOW6432Node\VideoLAN\VLC" "" ; Fallback for some systems
  ${EndIf}

  ; Check for 32-bit VLC
  ReadRegStr $VLC32_PATH HKLM "Software\VideoLAN\VLC" "" ; Check 32-bit registry view
  ${If} $VLC32_PATH == ""
    ReadRegStr $VLC32_PATH HKLM "Software\WOW6432Node\VideoLAN\VLC" "" ; Fallback for 32-bit VLC on 64-bit OS
  ${EndIf}

  ; Determine which VLC path to use
  ${If} $VLC64_PATH != ""
    StrCpy $TARGET_VLC_PATH "$VLC64_PATH"
  ${ElseIf} $VLC32_PATH != ""
    StrCpy $TARGET_VLC_PATH "$VLC32_PATH"
  ${Else}
    MessageBox MB_OK|MB_ICONSTOP "VLC installation not found. Please install VLC before installing the plugin."
    Abort
  ${EndIf}

  DetailPrint "Detected VLC installation at: $TARGET_VLC_PATH"
  
  StrCpy $0 "$TARGET_VLC_PATH\plugins\video_filter"
  CreateDirectory "$0"

  DetailPrint "Installing plugin to: $0"
  SetOutPath "$0"
  File "libspeed_hold_plugin.dll" ; This file needs to exist in the same directory as the .nsi script during compilation

  MessageBox MB_OK|MB_ICONINFORMATION "Plugin installed successfully. You now need to enable it in VLC's preferences. Refer to the plugin's documentation for instructions."

SectionEnd ; End of "VLC Speed Hold Plugin (required)" section
