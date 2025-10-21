#!/bin/bash
# --------------------------------------------------------------------------------------------------------------------------------------
# ******************************************************  build_set_env_variables.sh  **************************************************
# --------------------------------------------------------------------------------------------------------------------------------------
#
# -------
# Purpose: - define depending and general env-variables 
# -------    which are accessed from the "build_<project>.sh" scripts provided within the ~/Apple/ folder.
#          - expand the PATH
#          - activate virtual environment (venv), used by all kivy-projects
#
#          - Perform: "source <this_file>.sh" in order to make depending and general env-variables available 
#                      *********************  in current terminal-session and exand the path
# Design-Idea
# -----------
#        All scripts are based on SAME environment variables ($xxx), ensuring same naming convention in all scripts.
#        These env-variables are imported via: 
#        
#             source ~/kivy_projects/<project>/__set_env_variables.sh  ... set project specific variables (project configuration)
#             |
#             +->source ~/Apple__ENV__/build_set_env_variables.sh      ... set all depending or general variables
#
#
# Input: project configuration availabe as already set env-variables 
# -----
#        $APP="kivytest"                                                        # see: "Apple-developer-portal: https://developer.apple.com/account/apps
#        $APP_NAME="kivytestapp"                                                #
#        $BUNDLE_ID="org.test.$APP_NAME"                                        # bundle-id as specified in the "Apple-developer-portal: https://appstoreconnect.apple.com/apps/6749379249/distribution/info
#        $BUNDLE_ID_PRODUCT="org.kivy.$APP_NAME"                                # bundle-id as expected in mac-Simulator    
#        $TEAM_ID="YOUR_TEAM_ID"                                                # see: "Apple-developer-portal: https://developer.apple.com/account/resources
#        $SIGN_IDENTITY="Apple Distribution: YOUR_NAME_AT_PORTAL ($TEAM_ID)"    #
#        $PROVISIONING_PROFILE="ProfileAppStore_KivyTestApp"                    # see: "Apple-developer-portal: https://developer.apple.com/account/resources/profiles/list
#        $PASSWD="__KEYCHAIN_PASSWORD__"                                        # passwd for p12-key-boundle as: my_testapp.p12, ...  
#        $API_KEY_ID="YOUR_AppStoreConnect_KEY_ID"                              # see: "App Store Connect" access data: my keyID    ... (AppStoreConnect: https://appstoreconnect.apple.com/access/users/) 
#        $API_ISSUER_ID="YOUR_AppStoreConnect_ISSUER_ID"                        # see: "App Store Connect" access data: my issuerID ...  ...  
#
#        WKDIR=`pwd`                                                            # folder of current <project>, to which will be returned in (some) error cases
#
# Note: This file must be given in "UNIX"-format 
#       => in UltraEdit apply "converted from DOS to UNIX" before it gets copied (scp) to the macOS 
#      
#      
# state      | editor  | comment
# -----------+---------+----------------------------------------------------------------------------------------------------------------
# 2025-10-06 | W.Rulka | author 
# ...        | ...     | ...
#
# --------------------------------------------------------------------------------------------------------------------------------------
# **************************************************************************************************************************************
# --------------------------------------------------------------------------------------------------------------------------------------

# inline fcn
# ----------
  require_env() {
    local name=$1 val
    eval "val=\${$name-}"          # portable Indirektion (bash/zsh/sh)
    if [ -z "$val" ]; then
      printf '** ERROR: project env-variable <%s> is not set\n' "$name" >&2
      return 1
    fi
}
  
# --------------------------------------------------------------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------------------------------------------------------------
  require_env  APP                 
  require_env  APP_NAME            
  require_env  BUNDLE_ID           
  require_env  BUNDLE_ID_PRODUCT   
  require_env  TEAM_ID             
  require_env  SIGN_IDENTITY       
  require_env  PROVISIONING_PROFILE
  require_env  PASSWD              
  require_env  API_KEY_ID
  require_env  API_ISSUER_ID
                                                                           
  require_env  WKDIR 

# --------------------------------------------------------------------------------------------------------------------------------------
# depending and general env-Variables
# --------------------------------------------------------------------------------------------------------------------------------------
  export WKDIR=`pwd`                                                         # folder to which will be returned if the ios-build scripts fail at some stages
 
# general Project Paths  
# --------------------- 
  export PROJECTS="$HOME/kivy_projects"                                      # all tools, sources and app-bundles based on python/kivy ............ for example: ~/kivy_projects/                                      
  export PROJECT_DIR="$PROJECTS/kivy-ios/${APP_NAME}-ios"                    # secific app/project: entry folder  ............. ................... ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/                                       
  export PROJECT_PATH="$PROJECT_DIR/${APP_NAME}.xcodeproj"                   # ...             ...: ............................................... ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/kivytestapp.xcodeproj/               
  export APP_DIR="$PROJECT_DIR/$APP_NAME"                                    # ...             ...: ............................................... ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/kivytestapp/  
  export EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"                   # ...             ...: path to bundle, exported to TestFlight ........ ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/ExportOptions.plist 
  export ARCHIVE_DIR="$PROJECT_DIR/archive"                                  # ...             ...: ............................................... ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/archive/
  export EXPORT_DIR="$PROJECT_DIR/export"                                    # ...             ...: ............................................... ...        : ~/kivy_projects/kivy-ios/kivytestapp-ios/export/

# Xcode Signing
# -------------                                                                             
  export MY_KEYCHAIN="$HOME/Library/Keychains/iosbuild.keychain"             # ... my Xcode key-chains enhancing user-specific "login.keychain": ~/Library/Keychains/iosbuild.keychain
  export CERTFICATES="$HOME/AppleZertifikate"                                # ... my folder, storing all certificate files loaded from "Apple-developer-portal" or as derived certificates - ~/AppleZertifikate/*.cer , *.p12, *.key, *.p8
  export IPA_PATH="$PROJECT_DIR/dist/kivytestapp.ipa"                        # ... .ipa-file as result of export by Xcode-Build)
  export P8_KEY_FILE="AuthKey_${API_KEY_ID}.p8"                              # ... .p8-file (for upload via "iTMSTransporter" or via "fastline")   
  export P8_KEY_PATH="$HOME/.appstoreconnect/private_keys/${P8_KEY_FILE}"    # ... ... note: App-Store-Connect stores the "p8"-file and "asc_api_key.json"-file at THIS folder                                         
 #export P8_KEY_PATH="$CERTFICATES/$P8_KEY_FILE"                             # ... ... note: my backup-copy                                         
  export PROFILE_PATH="$CERTFICATES/${PROVISIONING_PROFILE}.mobileprovision" # ... for example: ".../ProfileAppStore_KivyTestApp.mobileprovision" of type "App Store" as required from "TestFlight" 
  export PROFILE_NAME="${PROVISIONING_PROFILE}"                              # ... exact name as defined in the "Apple-developer portal"
  export PBXPROJ="$PROJECT_PATH/project.pbxproj"                             # ... 
  export MARKETING_VERSION="1.0.0"                                           # ... Versionierung (optional, empfehlenswert)
  export BUILD_NUMBER="01"                                                   # ... ...

# Virtual Environment
# -------------------                                                                             
  export VENV="$PROJECTS/kivy-ios-venv"                                      # virtual environment for kivy-ios
  export VENV_SITEPACKAGE="$VENV/lib/python3.10/site-packages"               # ...

# kivy-ios site packages
# ----------------------                                                                                                                                                          
  export COMMON_LIBS="$PROJECTS/common_libs"                                 # kivy side packages: entry folder      
  export COMMON_KIVYMD="$PROJECTS/common_libs/kivymd_git"                    # ...            ...: kivyMD
  
# Build by toolchain & xcodebuild()
# ---------------------------------                                                                                                                                                          
  export KIVYIOS_ROOT="$PROJECTS/kivy-ios"                                   # build the app: kivy  
  export PLIST="$KIVYIOS_ROOT/${APP_NAME}-ios/${APP_NAME}-Info.plist"        # ...       ...: kivy bug-fix (black screen and crash at launch on on macSimulator  
  export APP_PLIST="$APP_PRODUCT/Info.plist"                                 # ...       ...: ... 
  export RECIPE_DIR="$KIVYIOS_ROOT/kivy_ios/recipes/kivymd"                  # ...       ...: kivyMD: kivy-ios recipes for site package kivyMD, copied/updated with recipes from app-used kivyMD version, given with: $HOME/kivy_projects/common_libs/kivymd_git 
  export RECIPE_ADD="$HOME/AppleKivy_recipe/kivymd"                          # ...       ...: ...   : additional entry recipes: ~/AppleKivy_recipe/kivymd/__init__.py, recipe.sh, requirements.txt
  export LINK_TARGET="$APP_DIR/kivymd"                                       # ...       ...: ... 
  export KIVYMD_COMMIT="5ff9d0de78260383fae0737716879781257155a8"            # ...       ...: ...   : this is the presumed commit-id on github, from there kivyMD2.0.1.dev0 has been installed 
                                                                             # ...       ...: ...      as actual/latest/(defacto stable) version on Windows-11. 
                                                                             # ...       ...: ...      - this version is recommended to be used for new projects and mostly occuring in google or chat-gpt requests.
                                                                             # ...       ...: ...      - the commit-id="5ff...", which specifies that version has been obtained from installation-date "2025-04-01"
                                                                             # ...       ...: ...        of kivyMD-file on Window-11: 
                                                                             # ...       ...: ...           D:\Programme2\Pyhton\Lib\site-packages\kivymd\__init__.py
                                                                             # ...       ...: ...        by (ssh) shell commands: 
                                                                             # ...       ...: ...        - cd $COMMON_LIBS/kivymd_git/
                                                                             # ...       ...: ...        - git fetch origin 
                                                                             # ...       ...: ...        - git rev-list -n 1 --before="2025-04-02" origin/master ... the result is: "5ff9d0de78260383fae0737716879781257155a8"
                                                                             # ...       ...: ...        as the latest commit/version most near to "2025-04-01"    
# xcodebuild() for Simulator
# --------------------------                                                                                                                                                         
  export ARCHS="arm64"                                                       # build the app: xcodebuild: target architecture for "Simulator" 
  export PLATFORM="simulator"                                                # ...       ...: ...    ...: ...
                                                                             # ...       ...: ...    ...: ...
  export SDL_ROOT="$KIVYIOS_ROOT/dist/xcframework"                           # ...       ...: ...    ...: Linker-Flags neu setzen (Python zuerst, und -ObjC dazu)
  export OTHER_LDFLAGS="
         -Wl,-force_load,$SDL_ROOT/libpython3.11.xcframework/ios-arm64-simulator/libpython3.11.a
         -Wl,-force_load,$SDL_ROOT/libkivy.xcframework/ios-arm64-simulator/libkivy.a
                         $SDL_ROOT/libSDL2.xcframework/ios-arm64-simulator/libSDL2.a
                         $SDL_ROOT/libSDL2_image.xcframework/ios-arm64-simulator/libSDL2_image.a
                         $SDL_ROOT/libSDL2_mixer.xcframework/ios-arm64-simulator/libSDL2_mixer.a
                         $SDL_ROOT/libSDL2_ttf.xcframework/ios-arm64-simulator/libSDL2_ttf.a
         -Wl,-force_load,$SDL_ROOT/libpng16.xcframework/ios-arm64-simulator/libpng16.a
         -Wl,-force_load,$SDL_ROOT/libssl.xcframework/ios-arm64-simulator/libssl.a
         -Wl,-force_load,$SDL_ROOT/libcrypto.xcframework/ios-arm64-simulator/libcrypto.a
         -Wl,-force_load,$SDL_ROOT/libffi.xcframework/ios-arm64-simulator/libffi.a
         -Wl,-force_load,$SDL_ROOT/libios.xcframework/ios-arm64-simulator/libios.a
         -Wl,-force_load,$SDL_ROOT/libpyobjus.xcframework/ios-arm64-simulator/libpyobjus.a
         -Wl,-ObjC"                                                                 # build the app: xcodebuild: accessed object-libraries *.a (still without kivyMD)
                                                                                    # ...       ...: ...         more libraries:
                                                                                    # ...       ...: ...           OTHER_LDFLAGS_ADDITIONAL="\
                                                                                    # ...       ...: ...            -Wl,-ObjC                \
                                                                                    # ...       ...: ...            -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphonesimulator/libpillow.a     \
                                                                                    # ...       ...: ...         
                                                                                    # ...       ...: ...         Note: The OpenSSL/libcrypto/libffi--force_load paths MUST match: Simulator = ios-arm64-simulator
                                                                                    # ...       ...: ...         ----  For device "TestFlight" later-on use the "ios-arm64"-slices and folder static libraries "dist/lib/iphoneos/*.a".
                                                                                    # ...       ...: ...
  export SIM_PATH="$KIVYIOS_ROOT/$APP_NAME-ios/simulator"                           # ...       ...: ...    ...: path to the xcodebuild generated executable folder  
  export APP_PRODUCT="$SIM_PATH/Build/Products/Debug-iphonesimulator/$APP_NAME.app" # ...       ...: ...    ...: here is stored the result of codebuild, ie. executable and whatever is needed to run

  export SIMULATOR_NAME="iPhone 15"                                                 # testing the generated app-bundle on "Simulator"                                                         
  export UDID=$(xcrun simctl list devices available |                               # udid of macSimulator device
                grep -F "$SIMULATOR_NAME"           |                               # ...
                grep -oE '[0-9A-Fa-f-]{36}'         |                               # ...
                head -n1 )                                                          # ...

# xcodebuild() for TestFlight (archive-export)
# --------------------------------------------                                                                                                                                                        
  # $OTHER_LDFLAGS gives all object-libraries for the "Simulator", taken from "ios-arm64-simulator" and "iphonesimulator" folder.
  # The build for a real device require the libraries taken from "ios-arm64" and "iphoneos" folder.
  #
  # TestFlight accepts static libraries only from "dist/lib/iphoneos" - the bundle MUST NOT include libs from: "dist/xcframework" or "ios-arm64-simulator"  
  #
  export OTHER_LDFLAGS_DEVICE="
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libpython3.11.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libkivy.a
                         $KIVYIOS_ROOT/dist/lib/iphoneos/libSDL2.a
                         $KIVYIOS_ROOT/dist/lib/iphoneos/libSDL2_image.a
                         $KIVYIOS_ROOT/dist/lib/iphoneos/libSDL2_mixer.a
                         $KIVYIOS_ROOT/dist/lib/iphoneos/libSDL2_ttf.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libpng16.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libssl.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libcrypto.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libffi.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libios.a
         -Wl,-force_load,$KIVYIOS_ROOT/dist/lib/iphoneos/libpyobjus.a
         -ObjC"

###########################################################################################################################################
# Path extension for the <project> build scripts
###########################################################################################################################################
  #
  # Get folder, there THIS script is located -- (physisch), symlink-sicher
  # ----------------------------------------
  if [ -n "$ZSH_VERSION" ]; then                             # zsh: absolut + symlink-aufgelöst   
     SCRIPT_PATH="${${(%):-%N}:A}"                           # ...
     SCRIPT_DIR="${SCRIPT_PATH:h}"                           # ...

  elif [ -n "$BASH_VERSION" ]; then                          # bash: Quelle ermitteln (auch wenn nur "name" aus PATH kam)    
    SOURCE="${BASH_SOURCE[0]:-$0}"                           # ...
    if [[ "$SOURCE" != */* ]]; then                          # ...
       SOURCE="$(command -v -- "$SOURCE")"                   # ...
    fi                                                       # ...
                                                             # ...
    while [ -h "$SOURCE" ]; do                               # ... -> Symlinks auflösen
      DIR="$(cd -P "$(dirname -- "$SOURCE")" && pwd)"        # ...
      TARGET="$(readlink -- "$SOURCE")"                      # ...
      case "$TARGET" in                                      # ...
        /*) SOURCE="$TARGET" ;;                              # ...
         *) SOURCE="$DIR/$TARGET" ;;                         # ...
      esac                                                   # ...
    done                                                     # ...
    SCRIPT_DIR="$(cd -P "$(dirname -- "$SOURCE")" && pwd)"   # ...

  else                                                       # POSIX-Fallback (best effort)  
    case "$0" in                                             # ...
       /*) SCRIPT="$0" ;;                                    # ...
      */*) SCRIPT="$(cd -P "$(dirname -- "$0")" && pwd)/$(basename -- "$0")" ;;
        *) SCRIPT="$(command -v -- "$0")" ;;                 # ...
    esac                                                     # ...
    while [ -h "$SCRIPT" ]; do                               # ...
      DIR="$(cd -P "$(dirname -- "$SCRIPT")" && pwd)"        # ...
      TARGET="$(readlink -- "$SCRIPT")"                      # ...
      case "$TARGET" in                                      # ...
        /*) SCRIPT="$TARGET" ;;                              # ...
         *) SCRIPT="$DIR/$TARGET" ;;                         # ...
      esac                                                   # ...
    done                                                     # ...
    SCRIPT_DIR="$(cd -P "$(dirname -- "$SCRIPT")" && pwd)"   # ...
  fi
  #
  # expand PATH
  # -----------
  export PATH="$PATH:$SCRIPT_DIR"                            # expand PATH to THIS folder presuming that all ios-build scripts are located her as well (version for external guthub-usage)
  export PATH="$PATH:$HOME/$PROJECTS/$APP"                   # the App-folder
         
###########################################################################################################################################
# activate virtual environment
###########################################################################################################################################
  source ${PROJECTS}/kivy-ios-venv/bin/activate                                            

  