#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# **********************************************************  app_build__TestFlight.sh  *************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: XcodeBuild for Archive -> Export -> Upload
# -------- with steps: 
#          - activate private Keychain - unlock $MY_KEYCHAIN, increase timeout, use $MY_KEYCHAIN login.keychain 
#          - verify signature identity - find "$SIGN_IDENTITY" in "$MY_KEYCHAIN" 
#          - customize of project Info.plist with Bundle-ID & IconName
#          - build AppIcon-set with all required icon-sizes 
#          - clean xcodebuild derived data & old artifacts 
#          - build App-archive via xcodebuild()
#          - cleanup archive: remove static libraries <.a> (these are linked to the executable) 
#                             and dynamic libraries <.so> which are explictly not accepted from Upload/Apple-Store-Connect   
#          - customize ExportOptions.plist
#          - generate export (.ipa) for App-Store-Connect
#          - upload to TestFlight via tool "fastlane"
#
# proofed with environment: 
# ------------------------ 
# - state 2025-10-19:
#   - Host                   : Apple M2-Mini gemietet bei MAC-Stadium (16GB)
#   - macOS                  : 14.7.6 (23H626)
#   - Xcode                  : 16.2, mit: SDK: iOS 18.2, simulator-SDK 18.2 
#   - Simulator SDK          : 18.2
#   - Python (for build) : 3.10.12
#   - Cython             : 0.29.37
#   - SDL2               : 2.28.5 (rebuilt locally via recipe – this is one of the Simulator patches)
#   - kivy-ios           : in venv ist die aktuelle GitHub-Version: 2025.5.17 @ cce9545
#   - Kivy                   : (wird automatisch aus kivy-ios gebaut – ebenfalls v2.3.1)
#   - KivyMD             : 2.0.1dev0 - selbst eingebunden via Recipe (manuell kopiert)
#   - Simulator runtimes : iOS 18.2 (ok: stable), iOS 17.2 (ok: stable), iOS 17.5 (??: problematic)
#   - Archive-build      : ok
#   - Export-build       : ok
#   - Upload (fastline)  : ok
#
# - state 2025-10-15:
#   - Host                   : Apple M2-Mini gemietet bei MAC-Stadium (16GB)
#   - macOS                  : 14.7.6 (23H626)
#   - Xcode                  : 15.4, mit: SDK: iOS 17.5, simulator-SDK 17.5 
#   - Simulator SDK          : 17.5
#   - Python (for build) : 3.10.12
#   - Cython             : 0.29.37
#   - SDL2               : 2.28.5 (rebuilt locally via recipe – this is one of the Simulator patches)
#   - kivy-ios           : in venv ist die aktuelle GitHub-Version: 2025.5.17 @ cce9545
#   - Kivy                   : (wird automatisch aus kivy-ios gebaut – ebenfalls v2.3.1)
#   - KivyMD             : 2.0.1dev0 - selbst eingebunden via Recipe (manuell kopiert)
#   - Simulator runtimes : iOS 17.2 (ok: stable), iOS 17.5 (??: problematic)
#   - Archive-build      : ok
#   - Export-build       : ok
#   - Upload (fastline)  : failed because of none-accepted SDK-17.5: App-Storce-Connect requires SDK-18.x, provided with Xcode-16.x 
#                          
# REQUIREMENTS
# ------------
# - xcodebuild() ......... for archive/export works only, if the keychain is unlocked 
#                         (in case of remote execution the private keychain needs to be the default one and unlocked)
# - xcodebuild() ......... requires the Info.plist customized to the Bundle-ID as specified in the Apple-Developer-Portal 
#                         (here "org.test.$APP_NAME" instead of default id: "org.kivy.$APP_NAME") 
# - xcodebuild() ......... requires a valid App-Icon-Set
#
# - distribution over "TestFlight": 
#
#   - the user must have admin-rights  in "Apple Developer Account" (https://developer.apple.com/account)
#   - the app must be registered ..... in "App Store Connect" ..... (https://appstoreconnect.apple.com/apps) 
#   - distribution key (p8), generated in "Apple Developer Account" (https://appstoreconnect.apple.com/access/integrations/api) -> Integration -> (+)
#   - folder ~/.appstoreconnect/private_keys/ must exist and has to provide the p8-file
#     name       : "Test Flight Distribution Key"
#     role       : "administrator"
#     => keyID   : "69PGG943A8"
#     => issuerID: "bdb74395-af94-4e10-8826-09dd680ea1cc"
#     => p8-file : AuthKey_69PGG943A8.p8
#     location   : ~/.appstoreconnect/private_keys/
#
# Inputs
# ------
# - global env-variables: $HOME/kivy_projects/<app>/__set_env_variables.sh
# 
# important Hints / Checks:    
# ------------------------
# - CFBundleIdentifier  : Für Device/Upload muss die in Info.plist exakt deinem App-Store-Bundle-ID entsprechen (z. B. com.example.yourapp). 
#                         Der Simulator kann parallel mit org.kivy.* laufen, App Store aber nicht.
#
# - Provisioning Profile: Für den Export muss das App Store-Profil gemappt werden (provisioningProfiles in ExportOptions.plist -> BUNDLE_ID: PROFILE_NAME).
#
# - SDK-Pflicht         : Uploads verlangen iOS 18 SDK (Xcode 16.x). Das Skript prüft xcrun --sdk iphoneos --show-sdk-version.
# 
# - Icons               : Ohne Asset-Catalog mit den Pflichtgrößen meckert App Store Connect (fehlende 120/152/167/180). 
#                         Das Helfer-Skript erzeugt ein minimalistisches, gültiges Set. 
#
# - Keine <.a> or <.xcframework> im <.app>: statische Libs und ganze XCFrameworks dürfen nicht im finalen .app liegen. 
#                                           Das Skript bricht ab, falls es doch welche findet.
#
#
# Note: Häufige Stolpersteine (kurz)
# ----------------------------------
# - Bundle ID ? Provisioning Profile (Name/UUID) ? "No matching provisioning profile"
# - TEAM_ID falsch ? Signieren schlägt "still" fehl
# - Keychain nicht Default/locked ? Codesign findet Identität nicht
# - Simulator-Flags in Release (z. B. -Umain -DSDL_MAIN_HANDLED) ? App startet nicht
# - Icons/LaunchScreen: App Store Connect meckert bei fehlenden Assets (kannst du fürs erste minimal halten; Kivy-Vorlagen nutzen)
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
# KIVYIOS_ROOT="$HOME/kivy_projects/kivy-ios"
#
# APP_NAME="kivytestapp"
# PROJECT_DIR="$KIVYIOS_ROOT/${APP_NAME}-ios"
# ARCHIVE_DIR="$PROJECT_DIR/archive"
# EXPORT_DIR="$PROJECT_DIR/export"
#
# PLIST="$KIVYIOS_ROOT/${APP_NAME}-ios/${APP_NAME}-Info.plist"
# APP_PLIST="$APP_PRODUCT/Info.plist"

# Signing
# -------
# TEAM_ID="YOUR_TEAM_ID"
# SIGN_IDENTITY="Apple Distribution: YOUR_NAME (YOUR_TEAM_ID)"
# PROFILE_NAME="ProfileAppStore_YourApp"                    # App Store-Profil (ohne .mobileprovision)
# MY_KEYCHAIN="$HOME/Library/Keychains/iosbuild.keychain"   # private keychain, required in case of REMOTE xcodebuild-signing (Apple security policity does not allow remote opening of login-keychain)
  KEYCHAIN_PW="$PASSWD"                                     # keychain password

# Bundle-ID (for real device and App-Store)
# ----------------------------------------- 
# BUNDLE_ID="com.example.yourapp"                           # MUST be IDENTICAL to the "App-Store-Profil" defined with Apple-Developer-Portal: "https://developer.apple.com/account/resources/identifiers/list"

# Build-Flags
# -----------
# OTHER_LDFLAGS_DEVICE="<list of static libs>"              # List of accessed static libs -- TestFlight accepts static libraries ONLY from "dist/lib/iphoneos" - the bundle MUST NOT include libs from: "dist/xcframework" or "ios-arm64-simulator"   
  APPICON_NAME="AppIcon"                                    # App Icon Set Name (muss im Asset Catalog existieren)
  SRC_ICON_1024="$PROJECTS/$APP/$APP_ICON_1024"             # the App master-icon in App-Store required resoulution 1024x1024 and of required type "png"

# Upload (fastlane/pilot via App Store Connect API-Key)
# -----------------------------------------------------
  ASC_API_KEY_JSON="$HOME/.appstoreconnect/private_keys/asc_api_key.json"

# ---------------------------------------------------------------------------------------------------------------------------------------------------
# local functions
# ---------------------------------------------------------------------------------------------------------------------------------------------------
  die(){ echo "? $*" >&2; exit 1; }
  say(){ echo "? $*"; }

  require_file(){ [[ -f "$1" ]] || die "file missed: $1";   }
  require_dir(){  [[ -d "$1" ]] || die "folder missed: $1"; }

  plist_get() {                                                                     # for customizing Info.plist: small helper function for getting CFBundle*-strings
    local key="$1" file="$2"                                                        # ...
    /usr/libexec/PlistBuddy -c "Print :$key" "$file" 2>/dev/null || echo "?"        # ...
  }
  plist_set_string () {                                                             # for customizing Info.plist: small helper function for setting (or adding) the string-keys
    local key="$1" val="$2" file="$3"                                               # ...
    /usr/libexec/PlistBuddy -c "Set :${key}        ${val}" "$file" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :${key} string ${val}" "$file"                  # ...
  }                                                                                 # ...

# ---------------------------------------------------------------------------------------------------------------------------------------------------
# Build-WorkFlow
# ---------------------------------------------------------------------------------------------------------------------------------------------------
main(){
  echo ""
  echo ""
  echo "**) Build App: XcodeBuild for Archive -> Export -> Upload to <TestFlight> ..."
  echo ""
  echo ""

  require_dir "$PROJECT_DIR"
  mkdir -p    "$ARCHIVE_DIR" "$EXPORT_DIR"

  # 0) Xcode / SDK checks (iOS 18 SDK is mandatory for upload to TestFlight)
  # ------------------------------------------------------------------------
  local sdkver
  sdkver="$(xcrun --sdk iphoneos --show-sdk-version || true)"
  [[ -n "$sdkver"             ]] || say "WARNING: Was not able to get iPhoneOS SDK-version."
  [[   "${sdkver%%.*}" -ge 18 ]] || say "WARNING: Found iPhoneOS SDK=$sdkver (<18). Please install/select Xcode 16.x."

  # 1) activate private Keychain 
  # ---------------------------- 
  if [[ -f "${MY_KEYCHAIN}-db" ]]; then
     say "Unlock private KeyChain: $MY_KEYCHAIN"
     security  unlock-keychain -p                  "$KEYCHAIN_PW" "$MY_KEYCHAIN" || true   # unlock keychain + increase timeout (for example: 6h)
     security     set-keychain-settings -lut 21600 "$MY_KEYCHAIN"                || true   # ...
     security    list-keychains -s                 "$MY_KEYCHAIN" login.keychain || true   # set keychain-search sequence: private one before login.keychain
     security default-keychain -s                  "$MY_KEYCHAIN"                || true   # set private keychain as default (important for xcodebuild)
     security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PW" "$MY_KEYCHAIN" || true   # expand key-partition-list (rights for tools)
  fi

  # 2) verify signature identity
  # ----------------------------
  security find-identity -v -p codesigning "$MY_KEYCHAIN" | grep -F "$SIGN_IDENTITY" >/dev/null \
           || die "signature identity not found: $SIGN_IDENTITY"

  # 3) Customize of Info.plist as input to xcodebuild(): Bundle-ID & IconName
  # -------------------------------------------------------------------------
    local PROJ_PLIST="$PROJECT_DIR/${APP_NAME}-Info.plist"                                       # this is the Info.plist file for the project in "kivy-ios" 
    require_file "$PROJ_PLIST"                                                                   # ...
    #
    CAMERA_TEXT="Your app uses the camera to capture images for testing the Kivy pipeline."      # descriptions required by AppStoreConnect
    MIC_TEXT="Your app may use the microphone when recording videos or audio within Kivy demos." # ...
    #
    # Bundle-ID double-check in Info.plist (should be $BUNDLE_ID, else adjust)
    # ------------------------------------   
    if [[ "$(plist_get   CFBundleIdentifier "$PROJ_PLIST")" != "$BUNDLE_ID" ]]; then
       say          "Set CFBundleIdentifier -> $BUNDLE_ID"
       plist_set_string "CFBundleIdentifier"  "$BUNDLE_ID"   "$PROJ_PLIST"
    fi
    if [[ "$(plist_get   CFBundleIconName "$PROJ_PLIST")" != "$APPICON_NAME" ]]; then
       say          "Set CFBundleIconName   -> $APPICON_NAME"
       plist_set_string "CFBundleIconName"    "$APPICON_NAME" "$PROJ_PLIST"
    fi
    if [[ "$(plist_get   NSCameraUsageDescription     "$PROJ_PLIST")" != "$CAMERA_TEXT" ]]; then 
       say          "Set NSCameraUsageDescription   -> $CAMERA_TEXT"
       plist_set_string "NSCameraUsageDescription"    "$CAMERA_TEXT" "$PROJ_PLIST"
    fi
    if [[ "$(plist_get   NSMicrophoneUsageDescription     "$PROJ_PLIST")" != "$MIC_TEXT" ]]; then 
       say          "Set NSMicrophoneUsageDescription   -> $MIC_TEXT"
       plist_set_string "NSMicrophoneUsageDescription"    "$MIC_TEXT" "$PROJ_PLIST"
    fi
    say "-> CFBundleIdentifier:           $(plist_get CFBundleIdentifier           "$PROJ_PLIST")"
    say "-> CFBundleIconName:             $(plist_get CFBundleIconName             "$PROJ_PLIST")"
    say "-> NSCameraUsageDescription:     $(plist_get NSCameraUsageDescription     "$PROJ_PLIST")"
    say "-> NSMicrophoneUsageDescription: $(plist_get NSMicrophoneUsageDescription "$PROJ_PLIST")"
    #
    # App-Icon-handling: generate if necessary and ensure the <set> in Info.plist
    # ------------------ note: Xcode nutzt den Katalog des Targets unter "$PROJECT_DIR/$APP_NAME/Images.xcassets/AppIcon.appiconset"
    #  
    # -> generate AppIcon-set if necessary
    #
    TARGET_DIR="$PROJECT_DIR/$APP_NAME/Images.xcassets/AppIcon.appiconset"
    REQUIRED_PNGS=("Icon-60@2x.png" "Icon-60@3x.png" "Icon-76@2x.png" "Icon-83.5@2x.png")

    need_icons=false
    for f in "${REQUIRED_PNGS[@]}"; do
        [[ -f "$TARGET_DIR/$f" ]] || { need_icons=true; break; }
    done
    if $need_icons; then
       say "AppIcon.appiconset uncomplete -> (re)generate"
       require_file "$SRC_ICON_1024"
       bash app_build__generate_png_icon.sh "$SRC_ICON_1024" "$PROJECT_DIR" "$APP_NAME"  
    fi
    #
    # CFBundleIconName sicher auf 'AppIcon' setzen
    #
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon"        "$PROJ_PLIST" || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$PROJ_PLIST"
    #
    # Optional: actool-Vorabcheck (liefert ein Assets.car in einen Temp-Ordner)
    #
    TMP_OUT="$(mktemp -d)"
    if ! xcrun actool "$PROJECT_DIR/$APP_NAME/Images.xcassets" \
           --compile "$TMP_OUT"                                \
           --platform iphoneos                                 \
           --minimum-deployment-target 16.0                    \
           --app-icon "AppIcon"                                \
           --output-partial-info-plist "$TMP_OUT/Assets.plist" >/dev/null 2>&1; then
      die "actool: Asset-Katalog not valid – please check the Icon-Set."
    fi
    rm -rf "$TMP_OUT"   
                         
  # 4) Clenup 
  # ---------
  say    "Clean DerivedData & old artifacts"
  rm -rf "$HOME/Library/Developer/Xcode/DerivedData/${APP_NAME}-*"
  rm -rf "$ARCHIVE_DIR/$APP_NAME.xcarchive"
  rm -rf "$EXPORT_DIR"/*

  # 5) build ARCHIVE (Release/iphoneos)
  # ----------------------------------
  say "xcodebuild archive ..."
  xcodebuild clean archive                             \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj"        \
    -scheme "$APP_NAME"                                \
    -configuration Release                             \
    -sdk iphoneos                                      \
    -destination "generic/platform=iOS"                \
    -archivePath "$ARCHIVE_DIR/$APP_NAME"              \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"             \
    DEVELOPMENT_TEAM="$TEAM_ID"                        \
    CODE_SIGN_STYLE=Manual                             \
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY"                \
    PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME"     \
    IPHONEOS_DEPLOYMENT_TARGET="16.0"                  \
    ENABLE_BITCODE="NO"                                \
    ONLY_ACTIVE_ARCH="YES"                             \
    EXCLUDED_ARCHS="i386 x86_64"                       \
    ASSETCATALOG_COMPILER_APPICON_NAME="$APPICON_NAME" \
    OTHER_CODE_SIGN_FLAGS="--keychain $MY_KEYCHAIN"    \
    OTHER_LDFLAGS="$OTHER_LDFLAGS_DEVICE"          
    #
    # Important:
    # ---------
    # - Kein OTHER_CFLAGS="-Umain -DSDL_MAIN_HANDLED" (das war der Simulator-Crash-Auslöser).
    # - ENABLE_BITCODE=NO (Bitcode ist obsolet).
    # - Wenn du Entitlements brauchst (z. B. Push), müssen Zertifikat/Profil/Capabilities zueinander passen.
    # - $BUNDLE_ID is the bundle-id as specified in http-Apple-Developer-Portal and 
    #   usually is not equal to the bundle-id $BUNDLE_ID_PRODUCT required by Simulator
    # - removed: OTHER_LDFLAGS_DEVICE='${OTHER_LDFLAGS_DEVICE} -ObjC -lc++ -lsqlite3 -lz -lbz2 -ljpeg -lfreetype'
    #
    # Remarks: 
    # - BITCODE="NO" is deprecated (veraltet); avoids link or upload problems
   
   
    # 6) Check generated archive
    # --------------------------
    APP_PROD_DIR="$ARCHIVE_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app" # the App-bundle
    require_dir "$APP_PROD_DIR"    
    
    say "Quick-check if Icons/Plist is part of archiv"
    
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIconName'             "$APP_PLIST" || true   # check if IconName is correct in final Plist? -> expected is: "AppIcon"
    ls -l "$APP_PROD_DIR/Assets.car"                                                        # check if Asset-Kompilat exists?
    /usr/libexec/PlistBuddy -c 'Print :NSCameraUsageDescription'     "$APP_PLIST" || true   # check if NSCameraUsageDescription     is set in final Plist 
    /usr/libexec/PlistBuddy -c 'Print :NSMicrophoneUsageDescription' "$APP_PLIST" || true   # check if NSMicrophoneUsageDescription ...
    
    # 6a) Check App-Bundle about forbidden content - check and clean (before Export!)
    # -------------------------------------------------------------------------------
    # Static-Libs are linked and are expected by upload-tools NOT to be copied to the archive (.app). 
    # If they are found in <.app> in the processes before has been done a "Copy Files/Resources" 
    # or a wrong reference to "dist/xcframework" instead of "dist/lib/iphoneos/*.a." 
    # The following "cleanup" is a workaround 
    # [ note: a correct solution needs corrections in the object-links in the Xcode-project. 
    #         (most of them we alreay have done with specification of "$OTHER_LDFLAGS_DEVICE")
    # ]
    
    say "Check for disallowed content (.a/.xcframework) in app bundle..."
    
    if find "$APP_PROD_DIR" \( -name '*.a' -o -name '*.xcframework' \) -print | grep -q . ; then
       say "=> Disallowed files found in app bundle -> remove .a and .xcframework entries from app bundle..."
       find "$APP_PROD_DIR" \( -name '*.a' -o -name '*.xcframework' \) -print
       
       find "$APP_PROD_DIR" -type f -name '*.a' -delete || true                             # remove <.a> separately    
       find "$APP_PROD_DIR" -type d -name '*.xcframework' -prune -exec rm -rf {} + || true  # remove total .xcframework-folder
       #
       # Re-check after clean:
       #
       if find "$APP_PROD_DIR" \( -name '*.a' -o -name '*.xcframework' \) -print | grep -q . ; then
          die "Still disallowed files present – please fix your Xcode project references (these are NOT allowed to be copied into the bundle)."
       else
          say "OK: all .a/.xcframework are removed from the app bundle."
       fi
    else
       say "OK: no .a/.xcframework inside app bundle."
    fi
    #
    # 6b) Clean the archive from files not accepted by the upload (App Store Connect) 
    # -------------------------------------------------------------------------------
    # Dynamic libs (.so) are accepted from Apple, if they already have a valid signing  
    # ( The Kivy-/PyObjus-/Pillow-.so-libraries under folder $KIVYIOS_ROOT/dist/root/python3/lib/python3.11/site-packages
    #   are necessary CPython-extensions and have a valid signing. Don't remove them, else the App will not run on the real iPhone
    # ) . 
    # Up to now (2025-10), the ONLY <.so> which is NOT accepted by the upload (App Store Connect) is ".../materialyoucolor/quantize/celebi.cpython-...-darwin.so".
    # To remove this library before xcodebuild() is called to generate the archive failed - a toochain build materialyoucolor as pure Python-installation 
    # withput binaries has been done, but <.so> still was there
    # => we need to be removed it from the generated archive, else the "export" stops and hope that the execution on the real iPhone will not crash....
    # 
    # remove only dynamic libraries from module "materialyoucolor", which are not accepted by "Upload", ie. "App Store Connect"
    #    
    PY_BASE_DIR="$APP_PROD_DIR/lib"                               # Basis-Pfade (robust für 3.11/3.12 etc.) 
    SITE_PACK_DIR=$(echo "$PY_BASE_DIR"/python3.*/site-packages)  # ...
    MYC_DIR="$SITE_PACK_DIR/materialyoucolor"                     # ...
        
    if [[ -d "$MYC_DIR" ]]; then                                  # materialyoucolor: remove only "native accelerators" BUT KEEP the package 
       if find "$MYC_DIR" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.pyd' \) -print -quit | grep -q .; then
          say "WARN: in generated App-bundle the site package <materialyoucolor> includes native extensions"
          say "      as dynamic libraries (.so/.dylib/.pyd), not accepted from (App-Store-Connect)"
       
          find "$MYC_DIR" -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.pyd' \) -print -delete
          say "OK: native extensions (.so,...) removed from site-package <materialyoucolor> in the generated App-bundle"
       else
          say "OK: site-packe <materialyoucolor> in the generated App-bundle already represents pure-Python (with no dynamic libraries (.so,...)."
       fi
    else
       say "site-package <materialyoucolor> not found in the App-Bundle."
    fi
    
    # code for more/all site-packages
      #
      # DYNL_DIR=$(echo "$PY_BASE_DIR"/python3.*/lib-dynload)         # ...
      #
      # say "Scan for native extensions in app bundle..."
      # find $SITE_PACK_DIR -type f -name '*.so' -print           \
      #    | sed 's#^.*/site-packages/##' | cut -d/ -f1 | sort -u \
      #    | awk '{print "   " $0}'                                  # diagnose: show which packages come up with <.so> dynamic libraries   
      #
      #
      # say "Strip remaining native extensions from site-packages..." # Genereller Sweep: alle verbleibenden .so/.dylib/.pyd in site-packages entfernen              
      # find $SITE_PACK_DIR -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.pyd' \) -print -delete || true
      #     
      # if [[ -d "$DYNL_DIR" ]]; then                                 # (Optional) lib-dynload ebenfalls säubern – auf iOS werden C-Ext statisch gelinkt          
      #   say "Strip lib-dynload (.so) ..."                           # ...
      #   find $DYNL_DIR -type f -name '*.so' -print -delete || true  # ...
      # fi                                                            # ...
      # #
      # # Guard: sicherstellen, dass wirklich keine .so mehr im Bundle sind
      # #
      # if find "$APP_PROD_DIR" -type f -name '*.so' -print | grep -q . ; then
      #    say "WARN: leftover .so files exist (see above) – App Store wird meckern."
      #    die "Please adjust packaging before export."
      # else
      #    say "OK: no .so left in app bundle."
      # fi
            
  # 7) ExportOptions.plist (App Store Connect, manual signing)
  # ---------------------------------------------------------- 
  # Here two methods - both are ok, important is: "method=app-store-connect", "signingStyle=manual", "provisioningProfiles[{BUNDLE_ID}]=PROFILE_NAME"
    #
    # methode-A: generate ExportOptions.plist 
    # ---------------------------------------  
    say "Generate ExportOptions.plist (manual signing, ASC)"
    local EXPORT_PLIST="$PROJECT_DIR/ExportOptions.plist"
    cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>${BUNDLE_ID}</key>
    <string>${PROFILE_NAME}</string>
  </dict>
  <key>compileBitcode</key><false/>
  <key>stripSwiftSymbols</key><true/>
  <key>thinning</key><string>&lt;none&gt;</string>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
    #
    # methode-B: stay with existing ExportOptions.plist + sed 
    # -------------------------------------------------------
    # /usr/bin/sed -i '' "s|__TEAM_ID__|$TEAM_ID|g"            "$EXPORT_OPTIONS"
    # /usr/bin/sed -i '' "s|__BUNDLE_ID__|$BUNDLE_ID|g"        "$EXPORT_OPTIONS"
    # /usr/bin/sed -i '' "s|__PROFILE_NAME__|$PROFILE_NAME|g"  "$EXPORT_OPTIONS" 

  # 7) Export (.ipa)
  # ----------------
  say "Export .ipa ..."
  xcodebuild -exportArchive                         \
    -archivePath "$ARCHIVE_DIR/$APP_NAME.xcarchive" \
    -exportPath  "$EXPORT_DIR"                      \
    -exportOptionsPlist "$EXPORT_PLIST"             \
    OTHER_CODE_SIGN_FLAGS="--keychain $MY_KEYCHAIN"

  local IPA="$EXPORT_DIR/${APP_NAME}.ipa"
  require_file "$IPA"

  # 8) Quick check: NO <.a> or <.xcframework> are accepted in <.app> for the "export"
  # ---------------------------------------------------------------------------------
  IPA="$EXPORT_DIR/${APP_NAME}.ipa"
  say "Scan .ipa for .a/.xcframework (should be none):"
  zipinfo -1 "$IPA" | egrep '\.a$|\.xcframework/' || true

  # 9) Upload via fastlane/pilot (API-Key JSON)
  # -------------------------------------------
  [[ -n "$sdkver"             ]] || die "ERROR: Was not able to get iPhoneOS SDK-version ==> App-Store-Connect REQUIRES SDK >18 ==> NO upload performed (please install Xcode16.x)"
  [[   "${sdkver%%.*}" -ge 18 ]] || die "ERROR: Found iPhoneOS SDK=$sdkver (<18). ==> App-Store-Connect REQUIRES SDK >18 ==> NO upload performed (please install Xcode16.x)"
  
  require_file "$ASC_API_KEY_JSON"
  say          "Upload to App Store Connect (fastlane pilot)..."
  fastlane pilot upload                    \
    --api_key_path "$ASC_API_KEY_JSON"     \
    --ipa          "$IPA"                  \
    --skip_waiting_for_build_processing true

  say "Ready. <.ipa>: $IPA"
}

main "$@"
