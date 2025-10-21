#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ****************************************************  build_bugfix_simulator__check_all.sh  *******************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: Check if all BugFixes have been applied successful
# -------- 
#
# Inputs
# ------
# - global env-variables: $HOME/kivy_projects/<app>/__set_env_variables.sh
#      
#      
# state      | editor  | comment
# -----------+---------+-----------------------------------------------------------------------------------------------------------------------------
# 2025-10-02 | W.Rulka | author 
# ...        | ...     | ...
#
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ***************************************************************************************************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
  
# Requirement /Configuration (import environment variables and activate virtual environment (venv))
# -------------------------- 
  # source ~/kivy_projects/kivytest/__set_env_variables.sh # presumed to be performed in calling shell: set project specific env-variables
  # source ~/Apple__ENV__/build_set_env_variables.sh       # .........................................: set depending env-variables, expand path, activate (venv)
#
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# Examine libraries and config-files 
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# --------------------------
# Check kivyMD-installation:
# --------------------------
  # check if kivyMD kv-files are part of the package:
    #
    if [ -f $APP_PRODUCT/lib/python3.11/site-packages/kivymd/uix/button/button.py ]; then
       :
    else
       echo "**) ERROR in build for Simulator: kivyMD kv-files missed in the generated app -> exit"; exit 1
    fi


# ---------------------------------
# Check architecture of the builds:
# ---------------------------------    
  ARCH_INFO=$(lipo -info "$APP_PRODUCT/$APP_NAME")  # get architecture of the generated app, for example: "arm64"


# ------------------------------------------------------------------------------------------
# Check: if SDL2 RGBA8-Patch has been appled, solving the Bug: "App shows only black screen"
# ------------------------------------------------------------------------------------------
  # toolchain-result <build> - check if m-files have been patched on both platform builds:
    info_fix_bs_m="ok  : file SDL_uikitopenglview.m is patched on both platforms"
    for f in $KIVYIOS_ROOT/build/sdl2/iphonesimulator-arm64/SDL2-*/src/video/uikit/SDL_uikitopenglview.m \
             $KIVYIOS_ROOT/build/sdl2/iphoneos-arm64/SDL2-*/src/video/uikit/SDL_uikitopenglview.m;       \
    do
      echo ">> Check $f"
      egrep -q 'eaglLayer\.opaque\s*=\s*YES'                                  "$f" && echo "  ok  : opaque=YES"    || { echo "  fail: opaque missed"  ; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
      egrep -q 'kEAGLDrawablePropertyRetainedBacking\s*:\s*@YES'              "$f" && echo "  ok  : retained=@YES" || { echo "  fail: retained missed"; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
      egrep -q 'kEAGLDrawablePropertyColorFormat\s*:\s*kEAGLColorFormatRGBA8' "$f" && echo "  ok  : RGBA8 found"   || { echo "  fail: RGBA8 missed"   ; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
    done
  
  # toolchain-result <dist> - check generated object library if SDL2 RGBA8-patch was successful: 
    #
    # - Wir extrahieren exakt das eine Objekt, in dem wir den Patch setzen.
    # - Wir suchen nach den Schlüssel-Konstanten (kEAGLColorFormatRGBA8, kEAGLDrawablePropertyRetainedBacking).
    # - Strings wie "opaque = YES" können vom Compiler wegge-optimiert werden; Symbole nicht.
    #
    # - Was machen die folgenden cmd's?
    #   - splittet die Fat-Lib auf arm64
    #   - zieht SDL_uikitopenglview.o raus
    #   - sucht Strings, die unser Patch erzeugt (einer reicht)
    #   - gibt "Patch erfolgreich"/"Patch unklar" aus.
    #
    LIB="$KIVYIOS_ROOT/dist/lib/iphonesimulator/libSDL2.a"
    ARCH=arm64 
    THIN=$(mktemp) && lipo -thin "$ARCH" "$LIB" -output "$THIN" \
    && OBJ=$(ar -t "$THIN" | grep -m1 'SDL_uikitopenglview\.o') \
    && TMP=$(mktemp -d)                                         \
    && (cd "$TMP" && ar -x "$THIN" "$OBJ")  
    nm -m "$TMP/$OBJ" 2>/dev/null | egrep -q '_kEAGLColorFormatRGBA8|_kEAGLDrawablePropertyRetainedBacking' \
    && info_fix_bs="ok  : Patch successful" || info_fix_bs="??  : Patch state not unique"  
    rm -rf "$TMP" "$THIN"

# ------------------------ 
# Check PLIST-custimizings - since we stay on Simulator runtime-iOS-17.2 the PLIST customizing is not needed -> commented out by "##"
# ------------------------ 
  ## #
  ## # Check: Kein Launch-Storyboard mehr? - correct is "none/removed"
  ## # -----------------------------------
  ##   if plutil-extract UILaunchStoryboardName raw -o - "$PLIST" >/dev/null 2>&1; then           # ... check on $KIVYIOS_ROOT/$APP_NAME-ios/kivytestapp-Info.plist, which is input to xcodebuild
  ##      info_fix1a="fail: UILaunchStoryboardName is still defined in <input>-plist "            # ...                                      **********************
  ##   else                                                                                       # ...
  ##      info_fix1a="ok  : UILaunchStoryboardName is removed in <input>-plist "                  # ...
  ##   fi                                                                                         
  ##   if plutil -extract UILaunchStoryboardName raw -o - "$APP_PLIST" >/dev/null 2>&1; then      # ... check on $APP_PRODUCT/Info.plist, which is generated by xcodebuild 
  ##      info_fix2a="fail: UILaunchStoryboardName still part of <generated> bundle-plist"        # ...                       **********                                             
  ##   else                                                                                       # ...                                                                    
  ##      info_fix2a="ok  : UILaunchStoryboardName is removed from <generated> bundle-plist"      # ...                                                                    
  ##   fi                                                                                         # ...
  ## 
  ## # Check: Kein Scene-Manifest mehr - correct is "none/removed"
  ## # -------------------------------              
  ##   # SceneManifest vorhanden? - correct is "yes/defined/added"                                                                                                                            
  ##   if plutil -extract UIApplicationSceneManifest json -o - "$PLIST" >/dev/null 2>&1; then     # ... check on $KIVYIOS_ROOT/$APP_NAME-ios/kivytestapp-Info.plist, which is input to xcodebuild
  ##      info_fix1b="fail: UIApplicationSceneManifest is defined in <input>-plist"               # ...                                      **********************
  ##   else                                                                                       # ...
  ##      info_fix1b="ok  : UIApplicationSceneManifest not defined in <input>-plist as expected"  # ...
  ##   fi                                                                                         
  ##   if plutil -extract UIApplicationSceneManifest json -o - "$APP_PLIST" >/dev/null 2>&1; then # ... check on $APP_PRODUCT/Info.plist, which is generated by xcodebuild
  ##      info_fix2b="fail: UIApplicationSceneManifest is still defined in <generated>-plist"     # ...                       **********
  ##   else                                                                                       # ...
  ##      info_fix2b="ok  : UIApplicationSceneManifest is not defined in <generated>-plist"       # ...
  ##   fi                                                                                         # ...
  ##                                                                                              
  ##   # Mehrere Szenen ausgeschaltet, No leave after <suspended>? - Flags prüfen (0|false => NO)                                                           
  ##   get_no(){                                                                                  # internal fcn
  ##     v=$(plutil -extract "$1" raw -o - "$APP_PLIST" 2>/dev/null || echo false)                # ...         
  ##     case "$v" in 0|false) echo 1;; *) echo 0;; esac                                          # ...         
  ##   }                                                                                          # ...         
  ##   [ "$(get_no UIApplicationSupportsMultipleScenes)" = 1 ] && info_fix2d="ok  : UIApplicationSupportsMultipleScenes = NO" || info_fix2d="fail: UIApplicationSupportsMultipleScenes = YES"
  ##   [ "$(get_no UIApplicationExitsOnSuspend)"         = 1 ] && info_fix2e="ok  : UIApplicationExitsOnSuspend = NO"         || info_fix2e="fail: UIApplicationExitsOnSuspend = YES"
  ## 
  ## # Check: if SDL2 RGBA8-Patch has been appled, solving the Bug: "App shows only black screen"
  ## # ------------------------------------------------------------------------------------------
  ##   # toolchain-result <build> - check if m-files have been patched on both platform builds:
  ##     info_fix_bs_m="ok  : file SDL_uikitopenglview.m is patched on both platforms"
  ##     for f in $KIVYIOS_ROOT/build/sdl2/iphonesimulator-arm64/SDL2-*/src/video/uikit/SDL_uikitopenglview.m \
  ##              $KIVYIOS_ROOT/build/sdl2/iphoneos-arm64/SDL2-*/src/video/uikit/SDL_uikitopenglview.m;       \
  ##     do
  ##       echo ">> Check $f"
  ##       egrep -q 'eaglLayer\.opaque\s*=\s*YES'                                  "$f" && echo "  ok  : opaque=YES"    || { echo "  fail: opaque missed"  ; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
  ##       egrep -q 'kEAGLDrawablePropertyRetainedBacking\s*:\s*@YES'              "$f" && echo "  ok  : retained=@YES" || { echo "  fail: retained missed"; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
  ##       egrep -q 'kEAGLDrawablePropertyColorFormat\s*:\s*kEAGLColorFormatRGBA8' "$f" && echo "  ok  : RGBA8 found"   || { echo "  fail: RGBA8 missed"   ; info_fix_bs_m="fail: file SDL_uikitopenglview.m is NOT patched on both platforms"; }
  ##     done
  ##   
  ##   # toolchain-result <dist> - check generated object library if SDL2 RGBA8-patch was successful: 
  ##     #
  ##     # - Wir extrahieren exakt das eine Objekt, in dem wir den Patch setzen.
  ##     # - Wir suchen nach den Schlüssel-Konstanten (kEAGLColorFormatRGBA8, kEAGLDrawablePropertyRetainedBacking).
  ##     # - Strings wie "opaque = YES" können vom Compiler wegge-optimiert werden; Symbole nicht.
  ##     #
  ##     # - Was machen die folgenden cmd's?
  ##     #   - splittet die Fat-Lib auf arm64
  ##     #   - zieht SDL_uikitopenglview.o raus
  ##     #   - sucht Strings, die unser Patch erzeugt (einer reicht)
  ##     #   - gibt "Patch erfolgreich"/"Patch unklar" aus.
  ##     #
  ##     LIB="$KIVYIOS_ROOT/dist/lib/iphonesimulator/libSDL2.a"
  ##     ARCH=arm64 
  ##     THIN=$(mktemp) && lipo -thin "$ARCH" "$LIB" -output "$THIN" \
  ##     && OBJ=$(ar -t "$THIN" | grep -m1 'SDL_uikitopenglview\.o') \
  ##     && TMP=$(mktemp -d)                                         \
  ##     && (cd "$TMP" && ar -x "$THIN" "$OBJ")  
  ##     nm -m "$TMP/$OBJ" 2>/dev/null | egrep -q '_kEAGLColorFormatRGBA8|_kEAGLDrawablePropertyRetainedBacking' \
  ##     && info_fix_bs="ok  : Patch successful" || info_fix_bs="??  : Patch state not unique"  
  ##     rm -rf "$TMP" "$THIN"


# ----------------------------------------------------------------------------------
# DOCUMENTATION of installed & applied tool versions (in venv) and applied Bug-Fixes:
# ----------------------------------------------------------------------------------
  echo ""
  echo ""
  echo ""
  echo "========================="
  echo "=== Build Environment ==="
  echo "========================="
  echo "- macOS   : $(sw_vers    -productVersion)"                         
  echo "- xcode   : $(xcodebuild -version       | grep Xcode             | awk '{print $2}')"                         
  echo "- sdk     : $(xcodebuild -showsdks      | grep 'iphonesimulator' | awk '{print $NF}' | paste -sd "," -) ... as taken from: xcodebuild -showsdk"                         
  echo "- python  : $(python     --version      | grep Python            | awk '{print $2}')" 
  echo "- cython  : $(cython     --version 2>&1 | grep Cython            | awk '{print $3}')"             
  echo "- kivy-ios: $(pip show kivy-ios         | grep Version           | awk '{print $2}') @ $(git -C ~/kivy_projects/kivy-ios rev-parse --short HEAD)"
  echo "- kivy    : $(pip show kivy             | grep Version           | awk '{print $2}')"
  echo "- kivymd  : $(pip show kivymd           | grep Version           | awk '{print $2}')"                         
  echo "- sdl2    : "$(basename "$(find "$KIVYIOS_ROOT/build/sdl2" -maxdepth 2 -type d -name 'SDL2-*' | head -n1)" | sed -E 's/^SDL2-//')
  echo "- sim-iOS : $(xcrun simctl list runtimes | sed -nE 's/^iOS[[:space:]]+[0-9.]+[[:space:]]+\(([0-9.]+)[[:space:]]+-.*$/\1/p' | paste -sd ' ' -)"
  echo ""
  echo "============================="
  echo "=== Summary of build-info ==="
  echo "============================="
  echo ""
  echo "- successful build of Simulator-App: $APP_PRODUCT"
  echo "  - with target architecture as extracted from the build App:"
  echo "    $ARCH_INFO"
  echo ""
  echo "======================================================"
  echo "=== Check if BugFixes have been applied successful ==="
  echo "======================================================"
  echo "- Bug on Simulator with runtime-iOS 17.2+: App shows only black screen"
  echo "  - Fix-1: apply SDL2 RGBA8-patch"
  echo "           - check if m-files have been patched on both build-platforms <iphoneos-arm64> $ <iphonesimulator-arm64>"
  echo "             - $info_fix_bs_m"
  echo "           - check generated object library"
  echo "             - $info_fix_bs"
##echo "  - Fix-2: no Screen-Manifest in <generated> Plist"
##echo "           - $info_fix2b"
##echo ""
##echo "- Bug on Simulator with runtime-iOS 17.2: App crashes after start with assertation-error"
##echo "  - Fix-3: dont leave after <suspended> and remove SceneManifest on xcodebuild <input> and <generated> Plist"
##echo "           - $info_fix2b"
##echo "           - $info_fix2e"
##echo "  - Fix-4: more senseful Flags?"
##echo "           - $info_fix2d"
  echo ""
  echo "- Bug on Simulator with runtime-iOS 17.5: App closes directly after start (exit-code=0)"
  echo "  - chatGPT tells: For Kivy-Apps the Simulator runtime-iOS17.5 is the problem." 
  echo "                   Workarounds are to use an older runtime-iOS or a real iPhone device." 
  echo "                   For runtime iOS-17.5 there still no clean Kivy workaround is available,"
  echo "                   Kivy is rendering by using OpenGL ES."
  echo "                   We have to wait for a Metal-Support in Kivy/iOS."
  echo ""
  echo "  - Info: following patch actions on runtime-iOS-17.5 were not successful" 
  echo "          - remove Launch-Storyboard on xcodebuild <input> and <generated> Plist."
  echo "          - generate a minimal LaunchScreen.storyboard (XML) and compile it with <ibtool>."
  echo "          - additionally generate a minimal Scene-Manifest into the boundle."
  echo ""
  echo ""
