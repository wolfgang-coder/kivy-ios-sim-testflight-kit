#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# **********************************************************   app_build__Project.sh   **************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: Allocate the App as Xcode-project via: toolchain build <app>.
# -------- This is done only once for a new project and is ignored, when folder $PROJECT_PATH exists
#          with steps 
#          - clean ..: rm -rf "$KIVYIOS_ROOT/${APP_NAME}-ios" 
#          - toolchain clean  <app>
#          - toolchain create <app>
#          - toolchain build  <app>
#
# proofed with environment: 
# ------------------------ 
# - state 2025-10-15:
#   - Host               : Apple M2-Mini gemietet bei MAC-Stadium (16GB)
#   - macOS              : 14.7.6 (23H626)
#   - Xcode              : 15.4, mit: SDK: iOS 17.5, simulator-SDK 17.5, macOS 14.5, ...
#   - Simulator SDK      : 17.5
#   - Python (for build) : 3.10.12
#   - Cython             : 0.29.37
#   - SDL2               : 2.28.5 (rebuilt locally via recipe – this is one of the Simulator patches)
#   - kivy-ios           : in venv ist die aktuelle GitHub-Version: 2025.5.17 @ cce9545
#   - Kivy                   : (wird automatisch aus kivy-ios gebaut – ebenfalls v2.3.1)
#   - KivyMD             : 2.0.1dev0 - selbst eingebunden via Recipe (manuell kopiert)
#   - Simulator runtimes : iOS 17.2 (ok: stable), iOS 17.5 (??: problematic)
#
# generated folder structure: 
# --------------------------
#          -> ${PROJECTS}
#             |
#             +-> common_libs/kivymd_git/kivmd ......... central storage of downloaded kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)
#             |                                        
#             +-> kivy-ios-venv ........................ virtual environment for compiled: python3, kivy, kivymd, ...
#             +-> kivy-ios ............................. actualized with version, which provides command "toolchain" as: ${PROJECTS}/kivy-ios-venv/bin/toolchain
#             +-> kivy_ios/recipes/kivymd .............. default "kiv-ios" site-packes enhanced with kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)       
#             +-> kivy-ios/kivytestapp-ios/ ............ NEW: iOS App-project
#                          |                             ***           
#                          +-> main.m   ................ App main.py converted to C-code for xcodebuild()
#                          +-> kivytestapp-Info.plist .. defines the iOS framework for the App
#                          +-> kivytestapp.xcodeproj/*.. ...
#                          +-> kivytestapp/  ........... ... - only Xcode-project folder with , not a "bundle"
#                          |   +->/Images.xcassets/*/*/  ...
#                          +-> YourApp/* ..............  ...
#                          +-> Storyboards/* ..........  ...
#                          +-> icon.png ...............  ...
#
# Inputs
# ------
# - global env-variables: $HOME/kivy_projects/<app>/__set_env_variables.sh
#
#
# Note: Execution of own (bash)-scripts from $PATH-extension
# ----------------------------------------------------------
# These can be executed directly as  "<script>.sh <par1> <par2>"  or as  "bash <script>.sh <par1> <par2>", but "<script>.sh ..." works only, when:
# - the file is executable (chmod +x script.sh),
# - the Shebang-line (header line) is: ("#!/usr/bin/env bash"  or  "#!/bin/bash"),
# - line ending is LF (no CRLF).
# "bash <script>.sh" ignors the executable-bit & Shebang and enforces Bash – this avoids errors as "zsh: bad substitution" & EOL-traps.
# This is the reason that I recommand to execute as: "bash <script>.sh ..."
#      
#      
# state      | editor  | comment
# -----------+---------+-----------------------------------------------------------------------------------------------------------------------------
# 2025-10-15 | W.Rulka | author 
# ...        | ...     | ...
#
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ***************************************************************************************************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
  
# Requirement /Configuration (import environment variables and activate virtual environment (venv))
# -------------------------- 
  # source ~/kivy_projects/kivytest/__set_env_variables.sh # presumed to be performed in calling shell: set project specific env-variables
  # source ~/Apple__ENV__/build_set_env_variables.sh       # .........................................: set depending env-variables, expand path, activate (venv)
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# Configuration (commented env-variables are expected to be available as "global", ie.: as already exported by ".../build_set_env_variables.sh")
# ---------------------------------------------------------------------------------------------------------------------------------------------------
set -Eeuo pipefail
#
# Project/Sceleton
# ----------------
# APP="kivytest"                                             # the Kivy-App name, where: $PROJECTS/$APP/main.py
# APP_NAME="kivytestapp"                                     # App-name as defined in Apple-Developer-portal ("https://developer.apple.com/account/resources/identifiers/list")
# PROJECTS="$HOME/kivy_projects"                             # entry folder for all tools, sources and app-bundles based on python/kivy                                     
# PROJECT_DIR="$KIVYIOS_ROOT/${APP_NAME}-ios"                # ...
# PROJECT_PATH="$PROJECT_DIR/${APP_NAME}.xcodeproj"          # ...
 
########################################################################################################################################################################
# APP - TOOLCHAIN: Allocate the Xcode project for the Kivy-App ( $PROJECTS/$APP/main.py ) ##############################################################################
########################################################################################################################################################################

  # create the toolchain/Xcode project (base)                # -> virtual environment is already activated by .../build_install_and_build_modules.sh
  # -----------------------------------------
  if [ -d $PROJECT_PATH ]; then                              # -> folder exists (for example: ~/kivy_projects/kivy-ios/kivytestapp-ios/kivytestapp.xcodeproj)
     :                                                       #
  else                                                       # -> xcode project needs to be allocated
     echo ""                                                 #
     echo ""                                                 #
     echo "**) allocate Xcode-project"                       #
     echo ""                                                 #
     echo ""                                                 #
     
     rm -rf "$KIVYIOS_ROOT/${APP_NAME}-ios"                  # -> clean first (here for the toolchain & xcodebuild 
                                                             #
     cd ${PROJECTS}/kivy-ios                                 # -> implicit requirement for "toolchain"
     toolchain clean  $APP_NAME                              # -> clean generate app-folders - for example with: $APP_NAME= kivytestapp     
     toolchain create $APP_NAME ${PROJECTS}/${APP}           # -> allocate app (folders, ...)                  : $APP     = kivytest        
                                                             #    -> result is: ~/kivy_projects/kivy-ios/kivytestapp-ios/ 
                                                             #                  ~/kivy_projects/kivy-ios/kivytestapp-ios/kivytestapp.xcodeproj/* 
                                                             #
     mkdir ${PROJECTS}/kivy-ios/kivy_ios/recipes/${APP_NAME} # -> provide recipe for the App with: depends = ['python3', 'kivy', 'kivymd', 'pillow', 'materialyoucolor']
     cp ${PROJECTS}/kivytest/__init__.py \
        ${PROJECTS}/kivy-ios/kivy_ios/recipes/${APP_NAME}/   #
                                                             #
     toolchain build  $APP_NAME                              # TOOLCHAIN BUILD for the App  
  fi             
    
