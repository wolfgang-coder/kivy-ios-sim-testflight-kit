#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# **********************************************************  app_build__Simulator.sh   *************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: XcodeBuild for Simulator
# -------- with steps: 
#          - safety: ensure in project Info.plist: Bundle-ID = default = $BUNDLE_ID_PRODUCT = org.kivy.$APP_NAME
#          - clean xcodebuild derived data & old artifacts: rm -rf "$KIVYIOS_ROOT/$APP_NAME-ios/simulator" "~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*"                  # clean (avoiding problems with older artifact's) -  SIM_PATH="$KIVYIOS_ROOT/$APP_NAME-ios/simulator" = "/Users/administrator/kivy_projects/kivy-ios/kivytestapp-ios/simulator" 
#          - apply bug-fixes/patches, in particular if necessary for the Simulator
#          - build <app> for Simulator via xcodebuild()
#          - check for successful build and required bug-fixes/patches
#          - start Simulator
#          - boot  Simulator device
#          - install and launch the <app> to the Simulator device
#
# REQUIREMENTS: 
# -------------
# - MUST: toolchain build sld2 MUST have been performed before all other site-packages were build via "toolchain build python3, kivy, ...
#         with previous DEEP-CLEAN of sdl2 -> IMPORTANT so that really everything gets installed from scratch 
# - NICE: the SDL2-RGBA8-patch is nice to be applied but not abosluely necessary.
#
# proofed with environment: 
# ------------------------ 
# - state 2025-10-19:
#   - Host               : Apple M2-Mini gemietet bei MAC-Stadium (16GB)
#   - macOS              : 14.7.6 (23H626)
#   - Xcode              : 16.2, mit: SDK: iOS 18.2, simulator-SDK 18.2 
#   - Simulator SDK      : 18.2
#   - Python (for build) : 3.10.12
#   - Cython             : 0.29.37
#   - SDL2               : 2.28.5 (rebuilt locally via recipe – this is one of the Simulator patches)
#   - kivy-ios           : in venv ist die aktuelle GitHub-Version: 2025.5.17 @ cce9545
#   - Kivy               : (wird automatisch aus kivy-ios gebaut – ebenfalls v2.3.1)
#   - KivyMD             : 2.0.1dev0 - selbst eingebunden via Recipe (manuell kopiert)
#   - Simulator runtimes : iOS 18.2 (ok: stable), iOS 17.2 (ok: stable), iOS 17.5 (??: problematic)
#
# - state 2025-10-15:
#   - Host               : Apple M2-Mini gemietet bei MAC-Stadium (16GB)
#   - macOS              : 14.7.6 (23H626)
#   - Xcode              : 15.4, mit: SDK: iOS 17.5, simulator-SDK 17.5 
#   - Simulator SDK      : 17.5
#   - Python (for build) : 3.10.12
#   - Cython             : 0.29.37
#   - SDL2               : 2.28.5 (rebuilt locally via recipe – this is one of the Simulator patches)
#   - kivy-ios           : in venv ist die aktuelle GitHub-Version: 2025.5.17 @ cce9545
#   - Kivy               : (wird automatisch aus kivy-ios gebaut – ebenfalls v2.3.1)
#   - KivyMD             : 2.0.1dev0 - selbst eingebunden via Recipe (manuell kopiert)
#   - Simulator runtimes : iOS 17.2 (ok: stable), iOS 17.5 (??: problematic)
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
# 2025-10-15 | W.Rulka | author (with support of chatGPT)
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
# APP_NAME="yourapp"                                 # app-name  as defined in Apple-Developer-portal .............................. ... "https://developer.apple.com/account/resources/identifiers/list"
# BUNDLE_ID="com.example.yourapp"                    # bundle-id as defined in Apple-Developer-portal ......... (org.****.$APP_NAME) ... ...
# BUNDLE_ID_PRODUCT="com.example.yourapp.dev"        # bundle-id as pre-defined by xcodebuild for the Simulator (org.kivy.$APP_NAME) ... ...
# PROJECT_DIR="$KIVYIOS_ROOT/${APP_NAME}-ios"        
                                                     
# Build-Flags                                        
# -----------                                        
# OTHER_LDFLAGS="<list of static libs>"              # List of accessed static libs for Simulator taken from: .../kivy_projects/kivy-ios/dist/xcframework/<site-package>/*.a 

# run on Simulator
# ---------------- 
# SIM_PATH="$KIVYIOS_ROOT/$APP_NAME-ios/simulator"   # result of xcodebuild generated for Simulator 
# APP_PRODUCT="$SIM_PATH/Build/Products/Debug-iphonesimulator/$APP_NAME.app" 

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

# ####################################################################################################################################################
# APP-XCODEBUILD: Build & Test iOS-executable for Simulator (arm64) ##################################################################################
# ####################################################################################################################################################

# ----------------------------------------------------------------------
# Baue Simulator-Version (arm64)...  -----------------------------------
# ----------------------------------------------------------------------
  echo ""
  echo ""
  echo "**) Build App: for Simulator-Architecture (arm64) -> run on Simulator..."
  echo ""
  echo ""

  # In Info.plist: Ensure the bundle-id (org.kivy.$APP_NAME) as expected from Simulator 
  #                This is the default as generated with "toolchain build <app>"
  #                but in praxis it might be overwritten by xcodebuild() for Archive/TestFlight/...        
  #                There it is required the bundle-id as allocated in the Apple-Developer-portal (http:...);
  #                for example: as (org.test.$APP_NAME).
  #                => With following savety-settings it is not necessary to perform "toolchain build <app>"
  #                   before each new Simulator build after modifications of the <app>: main.py
  #
    PROJ_PLIST="$PROJECT_DIR/${APP_NAME}-Info.plist"    # this is the Info.plist file for the project in "kivy-ios" 
    require_file "$PROJ_PLIST"
    if [[ "$(plist_get   CFBundleIdentifier "$PROJ_PLIST")" != "$BUNDLE_ID_PRODUCT" ]]; then
       say          "Set CFBundleIdentifier -> $BUNDLE_ID_PRODUCT"
       plist_set_string "CFBundleIdentifier"  "$BUNDLE_ID_PRODUCT" "$PROJ_PLIST"
    fi
   
  # Bug Fixes
    bash build_bugfix_simulator__crash_at_start.sh                 # BugFix-A( iOS17.x ): for "SDL initialisiert nicht mit Error: did you include SDL_main.h", d.h. Kivy findet keinen Window-Provider und bricht ab.
   #bash build_bugfix_simulator__exit_at_start_ios_17_2__before.sh # BugFix-B( iOS17.5 ): Simulator device-screen crashes with "assertation"-error
   #bash build_bugfix_simulator__exit_at_start_ios_17_5.sh         # BugFix-C( iOS17.5 ): App exits directly after the start with error code "=0" on Simulator iPhone with runtime-iOS-17.5
   
  # Clean
    rm -rf "$KIVYIOS_ROOT/$APP_NAME-ios/simulator"                 # clean (avoiding problems with older artifact's) -  SIM_PATH="$KIVYIOS_ROOT/$APP_NAME-ios/simulator" = "/Users/administrator/kivy_projects/kivy-ios/kivytestapp-ios/simulator" 
    rm -rf ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*     # clean derived data, in particular when a recompile is performed after previous troubled runs 

  # ---------------------------------------------------  
  # xcodebuild: generate executable for macOS-Simulator
  # ---------------------------------------------------  
    # with:                       #
    # -DEPLOYMENT_TARGET=16.0     # since year 2024/2024 it is required: IPHONEOS_DEPLOYMENT_TARGET >= 12 
    #                             # - to pass that setting as xcodebuild-argument is ok
    #                             #   but more substaniable it is to edit this setting in the projekt/xcconfig file. 
    #                             # - for the Mac-Simulator this value is less critical as for the iPhine device,
    #                             #   here it is IMPORTANT that: DEPLOYMENT_TARGET <= Runtime-Version (for example: 16.0 with iOS 17.4-Runtime is ok).
    #                             #
    # - $BUNDLE_ID_PRODUCT        # MUST be the default kivy-ios bundle-id "org.kivy.$APP_NAME" - it is a good idea to ensure that in Info.plist as edited above
    #                             # Note: usually the default kivy-ios bundle-id is different to the bundle-id $BUNDLE_ID as specified in Apple-Developer-Portal  
    #                             #
    # -OTHER_LDFLAGS              # list of static object libraries (*.a) for pre-compiled C-files from modules: kivy, python, ...: see: ~/kivy_projects/kivytest/__set_env_variables.sh
    # -OTHER_CFLAGS               # BugFix-A( iOS17.x ): this flag <OTHER_CFLAGS="-Umain -DSDL_MAIN_HANDLED"> MUST be removed totally from the xcodebuild flag list, else the App exits on Simulator  
    #                             #                      with RuntimeError: "Application didn't initialize properly, did you include SDL_main.h in the file containing your main() function?" - see: .../build_bugfix_simulator__crash_at_start.sh   
    cd ${PROJECT_DIR}
    xcodebuild \
      -project         "$KIVYIOS_ROOT/$APP_NAME-ios/$APP_NAME.xcodeproj" \
      -scheme          "$APP_NAME"                             \
      -configuration    Debug                                  \
      -sdk              iphonesimulator                        \
      -destination     "generic/platform=iOS Simulator"        \
      -derivedDataPath "$KIVYIOS_ROOT/$APP_NAME-ios/simulator" \
      ONLY_ACTIVE_ARCH=YES                                     \
      EXCLUDED_ARCHS="i386 x86_64"                             \
      PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID_PRODUCT             \
      IPHONEOS_DEPLOYMENT_TARGET=16.0                          \
      OTHER_LDFLAGS="$OTHER_LDFLAGS"                           \
      clean build

   #build_bugfix_simulator__exit_at_start_ios_17_2__after.sh   # BugFix-B( iOS17.5 ): after xcodebuild() applied to the generated APP-Bundle $APP_PLIST="$APP_PRODUCT/Info.plist"
    bash build_bugfix_simulator__check_all.sh                  # Final checks and report (check architecture of the builds && check, if the bug fixes have been applied successfully)
      
         
# ####################################################################################################################################################
# Test run on macSimulator  ##########################################################################################################################
# ####################################################################################################################################################

  # -----------------------
  # UDID of macOS-Simulator
  # -----------------------    
    UDID_METHODE="script" # methode for getting UDID of iPhone device

    # open the macSimulator - this is necessary for getting the Simulator visible in the remote GUI (vncviewer) and to show the App later-on                                                                                                                                                                                    
    # ---------------------
    if ! /usr/bin/pgrep -xq Simulator; then                              # Simulator-GUI nur starten, wenn sie noch nicht läuft // pgrep -xq Simulator prüft leise (-q) auf exakten Prozessnamen (-x).      
       SIM_APP="$(/usr/bin/xcode-select -p)/Applications/Simulator.app"  # - xcode-select -p erwischst du genau den Simulator der aktuell ausgewählten Xcode-Version.       
       if [ -d "$SIM_APP" ]; then                                        # Bevorzugt die zum aktuell ausgewählten Xcode gehörende App öffnen:   
          /usr/bin/open -ga "$SIM_APP"                                   # - open -ga … startet die App im Hintergrund (-g) und vermeidet Fokuswechsel; mit dem Pfad aus
       else                                                              #
          /usr/bin/open -ga Simulator                                    # Fallback: über den App-Namen 
       fi      
       for _ in {1..10}; do                                              # Kurz warten, bis der Prozess sichtbar ist (max. ~5s)               
           /usr/bin/pgrep -xq Simulator && break                         # ...
           /bin/sleep 0.5                                                # ...
       done
    fi
    
    echo "**) display info about all available Simulator iPhone devices and their state (booted or shutdown)"
    echo "**) ----------------------------------------------------------------------------------------------"
    xcrun simctl list devices
    echo ""
    echo ""
    echo ""
        
    if [ $UDID_METHODE = "fromList" ]; then
       # List of booted devices by: xcrun simctl list devices
       # ----------------------  
       # -iOS 17.2 
       #  iPhone 15 (DE8DB560-5842-4F2B-AECD-FA0FEB2846ED) (Booted)
       # -iOS 17.5 
       #  Kivy iPhone 14 (17.5) (76A0F823-E8FD-4D4C-8F1E-97D00584CF2E) (Booted)
       # -iOS 18.2 
       #  iPhone 16 Pro     (9B9C5EC2-35E6-48BF-BD8E-E8F355DC04A0) (Shutdown)
       #  iPhone 16 Pro Max (1F6281AC-1704-4A70-8195-E692327B0799) (Shutdown)
       #  iPhone 16         (58D08AE5-3C22-44BC-BA1F-12A72E300BFE) (Booted)
       # ----------------------  
       # UDID="76A0F823-E8FD-4D4C-8F1E-97D00584CF2E"  # udid for iPhone, runntime-iOS 17.5 - hier tritt mit simplen Kivy-App (Hello World) das Problem der Crashes beim Start auf - macOS: 14.7.6 // xcode: 15.4 // sdk: iphonesimulator17.5 // python: 3.10.12 // kivy-ios: 2025.5.17 // kivy: 2.3.1 // kivymd: 2.0.1.dev0 
       # UDID="DE8DB560-5842-4F2B-AECD-FA0FEB2846ED"  # udid for iPhone, runntime-iOS 17.2 - erfolgreicher Lauf einer einfachen TestApp ......................................... - macOS: 14.7.6 // xcode: 15.4 // sdk: iphonesimulator17.5 // python: 3.10.12 // kivy-ios: 2025.5.17 // kivy: 2.3.1 // kivymd: 2.0.1.dev0  
         UDID="58D08AE5-3C22-44BC-BA1F-12A72E300BFE"  # udid for iPhone, runntime-iOS 18.2 - erfolgreicher Lauf einer einfachen TestApp ......................................... - macOS: 14.7.6 // xcode: 16.2 // sdk: iphonesimulator18.2 // python: 3.10.12 // kivy-ios: 2025.5.17 // kivy: 2.3.1 // kivymd: 2.0.1.dev0  
    else
       # Get UDID of iPhone in terms of Xcode-version
       # --------------------------------------------
       xv=$(xcodebuild  -version | grep "Xcode")      # Xcode-version
       if [ "$xv" = "Xcode 16.2" ]; then
          #
          # Get UDID from first iPhone device, which runs iOS-18.2 // example: iOS 18.2 -- iPhone 16 (58D08AE5-3C22-44BC-BA1F-12A72E300BFE) (Booted)
          #
          UDID="$(bash simulator_device_UDID_and_Setup.sh "iOS 18.2" "iPhone 16")" # get UDID (if necessary generate and/or boot it // if generation failed stop total build (inclusive calling shell))
       else
          #
          # Get UDID from first iPhone device, which runs iOS-17.2 // example: iOS 17.2 -- iPhone 15 (9546E5E7-5F0E-4B48-ADD4-49BC8592B575) (Booted)
          #
          UDID="$(bash simulator_device_UDID_and_Setup.sh "iOS 17.2" "iPhone 15")" # get UDID (if necessary generate and/or boot it // if generation failed stop total build (inclusive calling shell))
       fi
    fi
     
    # Info/commented list of some useful device commands
    # --------------------------------------------------
    # xcrun simctl list devices                                                   # -> return list of available iPhone devices
    #                                                                             #
    # MODEL_NAME="iPhone 15"                                                      # -> create a new device    
    # RUNTIME_ID="com.apple.CoreSimulator.SimRuntime.iOS-17-2"                    # -> ... 
    # DTYPE="com.apple.CoreSimulator.SimDeviceType.$(echo "$MODEL_NAME" | tr ' ' '-')"
    # udid="$(xcrun simctl create "$MODEL_NAME" "$DTYPE" "$RUNTIME_ID")"          # -> ... 
    #                                                                             #
    # xcrun simctl shutdown         "$UDID"                                       # -> shutdown but let the iPhone on the GUI-screen
    # xcrun simctl erase            "$UDID" || true                               # -> remove the Phone from the GUI-screen 
    # xcrun simctl delete           "$UDID" || true                               # -> delete the Phone from the simctl-list         
    # xcrun simctl boot             "$UDID"                                       # -> boot the Phone                        
    # xcrun simctl terminate        "$UDID" "$BUNDLE_ID_PRODUCT" || true          # -> stop the App running on iPhone                        
    # xcrun simctl uninstall        "$UDID" "$BUNDLE_ID_PRODUCT" || true          # -> uninstall the App from the iPhone (App-icon gets removed)  
    # xcrun simctl install          "$UDID" "$APP_PRODUCT"                        # -> install   the App on   the iPhone (App-icon gets generated/visible)
    # xcrun simctl launch --console "$UDID" "$BUNDLE_ID_PRODUCT" ; echo "EXIT=$?" # -> start     the App 
  
  # ----------------------
  # Run on macOS-Simulator - Simulator sauber installieren & starten
  # ----------------------
    echo "**) run generated App on iPhone device with UDID: $UDID"
    
    xcrun simctl terminate        "$UDID" "$BUNDLE_ID_PRODUCT" || true
    xcrun simctl uninstall        "$UDID" "$BUNDLE_ID_PRODUCT" || true
    xcrun simctl install          "$UDID" "$APP_PRODUCT"
    xcrun simctl launch --console "$UDID" "$BUNDLE_ID_PRODUCT" ; echo "EXIT=$?"

    ### echo ""
    ### echo "** Read/Show trace if implemented in the App (main.py)"
    ### #        ---------------------------------------------------
    ### DATA_DIR=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID_PRODUCT" data)
    ### TRACE="$DATA_DIR/Documents/kivy_trace.txt"
    ### if [ -f "$TRACE" ]; then
    ###   echo ""
    ###   echo "---- kivy_trace.txt ----"
    ###   sed -n '1,200p' "$TRACE"
    ### else
    ###   echo "   - no trace-file <kivy_trace.txt> found (ie. not implemented in main.py)"
    ### fi

  # ----------------------------  
  # Trouble-Shootings at runtime:
  # ---------------------------- 
    ### # Error-Codes und typische Ursachen
    ### # - err=3 beim simctl launch: meist falsche Bundle-ID (App unter anderer ID gebaut/installs), App nicht vorhanden, 
    ### #                             oder sehr früher Abbruch mit Status 3. In deinem Szenario fast immer ID-Mismatch.
    ### # - err=4 ..................: häufig SIGILL -> falscher Slice (Device-Code in Simulator) oder sehr früher Crash ohne Logs.     
    ### #
    ### # Start online-Log in ssh-terminal with filtering of "$APP_NAME" 
    ### # --------------------------------------------------------------
    ###  #xcrun simctl spawn "$UDID" log stream --style compact --level debug --predicate 'process == "'$APP_NAME'"'       
    ###   xcrun simctl spawn "$UDID" log stream --style syslog  --level debug \
    ###         --predicate '(process == "kivytestapp")              OR \
    ###                      (subsystem == "com.apple.runningboard") OR \
    ###                      (eventMessage CONTAINS "watchdog")      OR \
    ###                      (eventMessage CONTAINS "Jetsam")        OR \
    ###                      (process == "SpringBoard")              OR \
    ###                      (process == "ReportCrash")'                # - sauberes Live-Log mit starkem Filter (RunningBoard, Jetsam, Watchdog, CrashReporter, SpringBoard, unser Prozess)
    ###   #
    ###   # and show last logs:
    ###     xcrun simctl spawn "$UDID" log show --last 2m --predicate 'processImagePath CONTAINS[c] "'$APP_NAME'.app" OR subsystem == "com.apple.dyld"' 
    ###     #
    ###     # Important: dyld-messages ("Library not loaded...", "image not found", "no suitable image found") are the important keys/issues.        
    ### 
    ### # gezielte Ausgabe des online-Logs im Fall des Crash, direkt beim Start der App
    ### # -----------------------------------------------------------------------------
    ###   # Vorherige Instanz sicher beenden    
    ###     xcrun simctl terminate "$UDID" "$BUNDLE_ID_PRODUCT" 2>/dev/null || true     
    ###  
    ###   # Starten, PID mitschneiden       
    ###     OUT=$(xcrun simctl launch --console "$UDID" "$BUNDLE_ID_PRODUCT" 2>&1 | tee /tmp/kivy_launch.out) 
    ###     PID=$(echo "$OUT" | awk -F': ' '/^org\.kivy\./{print $2}')  
    ### 
    ###   # Auf Prozess-Ende warten (kurz), dann relevante Logs der letzten 3 Minuten holen    
    ###     while ps -p "$PID" >/dev/null 2>&1; do sleep 0.2; done                                 
    ### 
    ###     PRED='((process == "runningboardd") OR (process == "assertiond") OR (process == "SpringBoard") OR (processID == '"$PID"')) AND (eventMessage CONTAINS[c] "exited" OR eventMessage CONTAINS[c] "termination" OR eventMessage CONTAINS[c] "watchdog" OR eventMessage CONTAINS[c] "Jetsam" OR eventMessage CONTAINS[c] "killed")'
    ### 
    ###     log show --style syslog --last 3m --predicate "$PRED" | tail -n 120
    ### 
    ###     rm -rf /tmp/kivy_launch.out
    ###     
    ### # Get crash-report of the Mac-Simulator
    ### # -------------------------------------
    ### # (here is reported the real cause – for example: none-resolved symbol-import, a python traceback, singal-11, etc)
    ### 
    ### SIM_CRASH_DIR="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Logs/CrashReporter"
    ### ls -lt "$SIM_CRASH_DIR" | head
    ### tail -200 "$SIM_CRASH_DIR/$(ls -t "$SIM_CRASH_DIR" | head -1)"
    ### 
    ### # Crashreport from Host-Mac, (for 99% the errors are found here) in particular when crash occured 
    ### # -------------------------   in native code immediately after the first frame)
    ### #
    ### # show list of reports with their time stamps
    ###   ls -lt ~/Library/Logs/DiagnosticReports | egrep -i 'kivy|kivytestapp|YourApp|simulator' | head
    ### 
    ### # open all or most recent one as selected manually from list above
    ###   open -a TextEdit "$(ls -t ~/Library/Logs/DiagnosticReports/*kivy* 2>/dev/null | head -1)"
    ###  
    ### # or show first lines in the remote (ssh)-terminal 
    ###   CR="$(ls -t ~/Library/Logs/DiagnosticReports/kivytestapp-2025-08-16-171101.ips 2>/dev/null | head -1)"; \
    ###   echo "== $CR =="; egrep -i 'Exception Type|Termination Reason|Crashed Thread|Thread|Binary Images' -n "$CR" | head -100 # example for most recent one
    ###   
    ###   CR="$(ls -t ~/Library/Logs/DiagnosticReports/*kivy* 2>/dev/null | head -1)"; \
    ###   echo "== $CR =="; egrep -i 'Exception Type|Termination Reason|Crashed Thread|Thread|Binary Images' -n "$CR" | head -100 # example with all 
    ### 
    ### # Check Kivy-Log from App-container
    ### # (At icon-start Kivy writes its <log>  to the data container - also in cases wher no ".ips" gets generated)
    ### #
    ###   DATA_DIR=$(xcrun simctl get_app_container "$UDID" "$PRODUCT_BUNDLE_ID" data)
    ###   LOG_DIR="$DATA_DIR/Documents/.kivy/logs"
    ###   ls -lt "$LOG_DIR" | head
    ###   tail -200 "$(ls -t "$LOG_DIR"/*.txt | head -1)"
    ### 
    ### # Selectively extract of Crash-Report fields 
    ### #
    ###   $PROJECTS/$APP/build_ios__bugfix_crash_report.sh
    ###       
    ### # Start/launch with GL-Debug, which gives more info in the ssh-terminal log
    ### # -------------------------- 
    ###   xcrun simctl spawn "$UDID" launchctl setenv KIVY_GL_DEBUG 1
    ###   xcrun simctl launch --console "$UDID" "$PRODUCT_BUNDLE_ID"
