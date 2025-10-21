#!/bin/bash
#
# >>> Anonymized version: adjust to you (team-id, passwd, install path of "KivyApp__build_iOS"         <<<
# >>>                     and your <App>-name (here is used: kivytest)                                 <<<
# >>> Copy THIS file to the folder, there your App is located (main.py, __init__.py, app_icon1024.png) <<<
#
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ***********************************************************************  build_ios.sh  *******************************************************************************
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: - iOS-Build of a KivyMD based APP over "kivy-ios", NOT "buildozer" 
# -------- - applied is "toolchain create" and "xcodebuild"
#          - the App is build with KivyMD-2.0.1dev0 a defacto stable KivyMD as recommended for new App-projects by google-provided documents or by ChatGPT 
#            (note toolchain build kivmd per default refers to kivyMD-1.1.1, the official git-version)
#          - kivy, kivMD are taken from "github", get acutalized to versions as applied to the APP-development on Windows-11, and are stroed on central folders, available to multiple App's
#          - kivy-ios, python, kivy, kivMD, ..., all are installed into "virtual environment (venv) as "editable xxx" => modifications at "central tool folders" get immediately available to the App builds
#          - tools as "kivMD, ..., which are not supported by "kivy-ios" are provided by manual copy of their module "recipes" to "kivy-ios" folders
#          - the build is done once for the Mac-Simulator (none-signed app) and twice for testpurpose as distribution over TestFlight (signed with "distribution")
#          - the total work is done "remote" via remote terminal (via: ssh) on a headless-MAC M2-mini, rented at MAC-Stadium;
#            only for the Simulator test is used a remote GUI (via: vncviewer)
#
#          Applyng THIS script ensures all requirements and dependencies of:
#          - command option parameter values (as "team_id") of all applied "toolchain & Xcode" commands, in particular code signing for TestFlight
#          - command option parameter values and settings/definitions done in the "Apple-developer-portal"
#          
#          As well are considered/implemented here all requirements involved by "toolchain create" as 
#          - the explicit copy of kv-files into executable for site packages as kivyMD, special recipts for kivyMD, ...  
#
#          Note: For the app-build for iOS, I decided and RECOMMEND to use "toolchain create" and "xcodebuild", "codesign" directly instead of applying 
#                tool "buildozer". 
#                At least "buildozer" would also call "toolchain" and "xcodebuild", but it is a third code-level, which involves much more
#                correspondencies of "buildozer"-options not only to the certificate files or certifacate names but as well to the content of these
#                certificates as (uuid, ...). This leads to much more bugs in configuration-settings (buildozer.spec) and since that there is no
#                actual documentation provided (I found none) for necessary options, option-content, etc, and over more that there is no documentation 
#                about option settings, which conisider version changes in MAC-OS, kivy-ios, Xcode, ... and "Apple-developer-portal" 
#                I failed with "buildozer" after more than one week work with many annoying successless attemps.
#
# Build-Function Callgraph
# ------------------------  
#
#    ./main.py     ...................................................................... ... the App written with native "kivy" 
#    ./__init__.py ...................................................................... ... recipe for kivy-ios: "toolchain" 
#    ./__set_env_variables.sh ........................................................... ... set project specific env-variables 
#    ./app_icon1024.png       ........................................................... ... master icon for the App with resolution 1024x1024
#                                                                                        
#    ./build_ios.sh ..................................................................... ... build the App (all installation/build steps starting from scratch 
#      |                                                                                 
#      +-> ~/__set_env_variables.sh ..................................................... ... -> set project specific env-variables 
#      |   |                                                                                 
#      |   +-> source ~/Apple__ENV__/build_set_env_variables.sh ......................... ... -> set depending/general env-variables, expand PATH, activate virtual enironment (venv)
#      |                             ***********************                            
#      |                                                                                
#      |                                                                                
#      +-> ~/KivyApp_Build_iOS/build_install_and_build_modules.sh    .................... ... -> install packages, toolchain build <packages>, toolchain build <app>, xcodebuild <app>, <run App on macSimulator> 
#      |   |                   *******************************     
#      |   |                                                                            
#      |   +-> ~/KivyApp_Build_iOS/build_kivy_ios__setup_venv.sh     .................... ... -> copy/clone kivy-ios from Git, setup virtual environment (venv) and install kivy-ios to "venv" 
#      |   +-> ~/KivyApp_Build_iOS/build_install_kivyMD.sh.sh        .................... ... -> copy/clone kivyMD from Git and install to venv
#      |   |                                                                            
#      |   +-> ~/KivyApp_Build_iOS/build_bugfix_toolchain_missed_libs.sh             .... ... -> bug(python3): "toolchain build" is missing library <libpython3.11.a>, required from module "pillow"
#      |   +-> ~/KivyApp_Build_iOS/build_bugfix_simulator__remaining_black_screen.sh .... ... -> bug(SDL)    : remaining black screen on Simulator with runtime-iOS-17.x - the "SDL2-RGBA8-patch" (EAGL RGBA8 + retained backing + opaque)"
#      |   +-> ~/KivyApp_Build_iOS/build_bugfix_simulator__remaining_black_screen__check.sh   -> check
#      |   |
#      |   +-> toolchain build <site-packes>  ........................................... ... -> build moduls 
#      |                                                                               
#      |                                                                               
#      +-> ~/KivyApp_Build_iOS/app_build__Project.sh  ................................... ... -> allocate the App as Xcode-project (toolchain build <app>)
#      |   |                   ******************                                          
#      |   +-> toolchain build <app>               ...................................... ... -> allocate the app 
#      |                                                                               
#      |                                                                               
#      +-> ~/KivyApp_Build_iOS/app_build__Simulator.sh .................................. ... -> build App for "Simulator" (xcodebuild() -> test-run on Simulator 
#      |   |                   ********************
#      |   |
#      |   +-> ~/KivyApp_Build_iOS/build_bugfix_simulator__crash_at_start.sh ............ ... -> BugFix-A(xcodebuild-flags ): for "SDL initialisiert nicht mit Error: did you include SDL_main.h", d.h. Kivy findet keinen Window-Provider und bricht ab.
#      |   +-> ~/KivyApp_Build_iOS/build_bugfix_simulator__check_all.sh      ............ ... -> Final checks and report (check architecture of the builds && check, if the bug fixes have been applied successfully)
#      |   |
#      |   +-> xcodebuild() ............................................................. ... -> build the app-bundle for "Simulator"
#      |   |                                                                            
#      |   +-> ~/KivyApp_Build_iOS/simulator_device_UDID_and_Setup.sh  .................. ... -> look for a iPhone-Simulator with runtime iOS-17.2 and return UDID - if necessary generate and/or boot it.
#      |   +->[~/KivyApp_Build_iOS/simulator_device_list_clean.sh ]    .................. ... -> optional: clean Simulator device list with dublicate devices (keep only one of <iPhone-name> and <runtime-iOS>
#      |   |                                                                            
#      |   +-> xcrun simctl install          $UDID $APP_PRODUCT            .............. ... -> install & start the <pp> on macSimulator
#      |   +-> xcrun simctl launch --console $UDID $BUNDLE_ID_PRODUCT      .............. ... -> ...
#      |                                                                                
#      |                                                                                
#      +-> ~/KivyApp_Build_iOS/app_build__myKeyChain.sh ................................. ... -> generate private keychain if it is already not done - required for remote certifications
#      |                                                                                
#      +-> ~/KivyApp_Build_iOS/app_build__TestFlight.sh ................................. ... -> build archive -> export -> upload
#          |               *********************                                        
#          |                                                                            
#          +-> ~/KivyApp_Build_iOS/app_build__generate_png_icon.sh ...................... ... -> generate App-Icon-set
#          |                                                                            
#          +-> xcodebuild()  ............................................................ ... -> build the App "archive"  
#          |                                                                            
#          +-> xcodebuild()  ............................................................ ... -> build the app-bundle for "export"  
#          |                                                                            
#          +-> fastline()    ............................................................ ... -> upload to TestFlight (App-Store-Connect)
#
#
# Requirements:
# ------------
# - the user/app-designer must have an "Apple developer" license (99 per year), 
# - remote MAC-OS computer, here "M2-Mini", for example rented at MAC-Stadium (300 per month)
# - remote MAC-OS computer: operating system: 16GB free discspace
# - remote MAC-OS computer: operating system: MacOS 14.7.6
# - remote MAC-OS computer: ios-build by    : Xcode 16.2 .................: downloaded from Apple-Developer-Portal - note: up to now (2025-08-01) Apple allows only iOS-18-SDK which is part of Xcode-16 // 16.2 the latest running on macOS-14.7
#                                           : SDK-18.2   .................: (this part of Xcode-16)
#                                           : runtime-iOS-18.2 ...........: downloaded from Apple-Developer-Portal
# - remote MAC-OS computer: compiler        : Python 3.10.12 .............: similar to "kivy-ios" the compiler "python3" gets installed to ".../kivy-ios-venv" by THIS script 
# - remote MAC-OS computer: app base tool   : kivy-ios ... Kivi for iOS 
#                                             - cloned/downloaded from ...: "https://github.com/kivy/kivy-ios.git"
#                                             - updated to actual state by: "pip install --force-reinstall --upgrade kivy-ios"    
#                                             - compiled to virtual env   : "~/kivy_projects/kivy-ios-venv"    
#                                             - providing CLI-cmd         : "toolchain"
#                                             - note-1                    : actual state defines "year 2025";
#                                                                           this actual version uses the CLI-cmd "toolchain" directly, compared to  
#                                                                           older now none-valid kivy-versions, which were adressing: .../kivy-ios/toolchain.py 
#                                             - note-2                    : kivy-ios is applied to all user maintained app's
#                                             - note-3                    : the installation/update to actual kivy-ios state is implemented in THIS script
#                                             kivyMD as used in src-code  : 2.0.1.dev0 ... from GitHub
#                                             kivyMD tool as downloaded   : the version downloaded from git at 2025-08 is kivymd-1.1.1 and has been updated to version 2.0.1.dev0 applying a "kivymd commit-id"
# - remote MAC-OS  computer: user needs administrator rights
# - local  Windows computer: runs "Ubuntu 24.04.2" (Linux-shell available with Windows "power shell")
# - remote terminal via <ssh> ......... for example: ssh  administrator@208.83.1.102 ... here: "administrator" is the user name, 
# - remote GUI      via <vncviewer> ... for example: vncviewer 208.83.1.102                  : "208.83.1.102"  is the MAC ip-address
#
# - certification:  for app-istallation via AppStore and TestFlight the total build and the signing package must be generated with 
#                   the SAME mobile-provisioning (here typ="App Store") !!!                                                                             
# - Certificates                                                                               +----------------------------------------------------------+
#   +) Corresponding files generated on local computer (Ubuntu-shell) via command: <openssl> : | openssl req -new -newkey rsa:2048 -nodes \               |  
#                                                                                              |    -keyout my_testapp_key.key \                          |
#      - my_testapp_key.key     .....: personal key                                            |    -out    my_testapp_request.csr \                      |
#      - my_testapp_request.csr .....: certificate request (German: Zertifikat-Anforderung)    |    -subj "/CN=Wolfgang Rulka/emailAddress=rulka@web.de"  |
#                                                                                              +----------------------------------------------------------+
#
#   +) Certificates ordered via "Apple developer portal": https://developer.apple.com/account - interactively with import of: "my_testapp_request.csr":   
#
#      1) apple_deployment.cer ......: Apple distribution certificate - at least since year 2025 the "apple distribution" includes: iOS, tablets, MAC, ...
#      2) AppleWWDRCAG4.cer    ......: Apple intermediate certificates (German: Apple-Zwischenzertifikat) - since year 2025 is required "Worldwide Developer Relations G4" (older variants G2, G3, ... are invalid)
#      3) AppleIncRootCertificate.cer: Apple root certificate (optional, not really necessary)
#      4) ProfileAppStore_KivyTestApp.mobileprovision .....: app profile for export to TestFlight, which specifys: 
#                                                            - platform (iOS), 
#                                                            - Typ="App Store" for export to TestFlight 
#                                                            location: ~/Library/MobileDevice/Provisioning\ Profiles
#   +) Derived/Combined Certificates , build on remote MAC: 
#
#      1) my_testapp.p12 ............: personal p12-key-boundle, combining: apple_deployment.cer, AppleWWDRCAG4.cer, my_testapp_key.key enhanced by: "passwd"  
#      2) iosbuild.keychain .........: additional "keychain" for tools: "xcodebuild","codesign","security", 
#                                      - build  by: .p12>-boundle and keychain: "passwd"   
#                                      - stored as: ~/Library/Keychains/iosbuild.keychain 
#                                      - note     : on remote shell (ssh) MAC security specs does not allow to modify the user login-keychain, 
#                                                   we need to add and maintain an additional keychain 
#
#      Note: certificates from "Apple developer portal" must be provided in advance, the derived key-boundle and key-chain are updated in THIS script
#
# - distribution over "TestFlight": 
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
# Global design idea
# ------------------ 
# *) Python and Kivy are installed into a "virtual" environment, identical for all kivy projects
#
# *) Folder structure, where multiple Kivy-projects are located under folder: "~/kivy_projects"
# 
#       $HOME
#       |
#       +-> kivy_projects/ 
#       |   +-> kivytest/      .......................... project-1: kivy-test: "hello world"
#       |   |   +-> main.py    .......................... - app entry src-file
#       |   |   +-> ...        .......................... - ...
#       |   |   +-> kivymd     .......................... - symbolic link to  ../common_libs/kivymd
#       |   +-> ...            .......................... project-x
#       |   |   +-> main.py    .......................... - app entry src-file
#       |   |   +-> ...        .......................... - ...
#       |   |   |                                      
#       |   +-> kivy-ios/      .......................... actual kivy-ios as clode of: https://github.com/kivy/kivy-ios.git
#       |   |   +-> ...        .......................... - kivy-ios folders from git and folders generated by "toolchain build" later-on
#       |   |   +-> kivy_ios   .......................... - ...
#       |   |   |   |
#       |   |   |   +-> recipes/.../        ............. recipes for all kivy-ios python packages
#       |   |   |   +-> recipes/sdl2/       ............. recipe  for sdl2
#       |   |   |   |   +-> __init__.py     ............. -> this recipe gets PATCHED - bug: remaining black screen on Simulator runtime-iOS-17.2
#       |   |   |   |                                  
#       |   |   |   +-> recipes/python3/    ............. recipe  for python3
#       |   |   |   |   +-> __init__.py     ............. -> this recipe gets PATCHED - bug: library "libpython3.11.a", which is accessed from module "pillow"
#       |   |   |   |                                  
#       |   |   |   +-> recipes/kivymd/     ............. recipe  for kivymd - this folder is allocated manually
#       |   |   |       +-> __init__.py     ............. -> this kvymd-MASTER-recipe is GENERATED MANUALLY - copy from: ~/AppleKivy_recipe/kivymd  
#       |   |   |       +-> recipe.sh       ............. -> this file is GENERATED MANUALLY .............. - copy from: ...
#       |   |   |       +-> requirements.txt............. -> .............................................. - copy from: ...
#       |   |   |       +-> kivymd/         ............. this folder is a MANUALLY COPY of "*.py, *.kv, subfolders" from kivymd github-folder: ~/kivy_projects/common_libs/kivymd_git/kivymd
#       |   |   |           +-> __init__.py ............. ... recipe for kivymd widgets 
#       |   |   |           +-> uix/        ............. ... gui widgets
#       |   |   |               +-> button  ............. ... ...
#       |   |   |               |   +-> __init__.py ..... ... ...
#       |   |   |               |   +-> button.py   ..... ... ...
#       |   |   |               |   +-> button.kv   ..... ... ...
#       |   |   |               +-> ...        .......... ... ...
#       |   |   | 
#       |   |   +-> kivytestapp-ios/ .................... ... project-1: result of "toolchain build <project_1>"
#       |   |       +-> kivytestapp/ .................... ... ... only Xcode-project, not a "bundle"
#       |   |       +-> simulator/   .................... ... ... Xcode-result
#       |   |           +-> Build/                        ... ...
#       |   |               +-> Products/                 ... ...
#       |   |                   +-> Debug-iphonesimulator/... ...
#       |   |                       +-> kivytestapp.app/  ... ... bundle <==> APP_PRODUCT="$SIM_PATH/Build/Products/Debug-iphonesimulator/$APP_NAME.app"
#       |   |                           +-> kivytestapp   ... ... exe-file
#       |   |                           +-> YourApp/      ... ... pre-compiled App: main.pyc, build_ios.sh, build_ios_*.sh
#       |   |                           +-> icon.png
#       |   |                           +-> ...
#       |   |                           +-> kivymd/  ........ ... manually copied kv-file for none-default side-package "kivymd"
#       |   |                               +-> uix/ ........ ... - gui widgets
#       |   |                                   +-> button/         ...
#       |   |                                       +-> button.kv   ...
#       |   |                                       +-> ...         ...
#       |   |     
#       |   +-> kivy-ios-venv/  ......................... virtual environment, established for all kivy/python projects  
#       |   +-> common_libs/    ......................... common libs available to all projects
#       |       +-> kivymd_git/ ......................... - actual kivyMD as clode of: hgit clone https://github.com/kivymd/KivyMD.git 
#       |           +-> kivymd/                             ...
#       |               +-> fonts/                          ...
#       |               +-> icon_definitions/               ...
#       |               +-> theming/                        ...
#       |               +-> toast/                          ...
#       |               +-> uix/                            ...
#       |               |   +-> button/                     ...
#       |               |   +-> label/                      ...
#       |               |   +-> screen/                     ...
#       |               |   +-> ...                         ...
#       |               +-> utils/                          ...
#       |
#       +-> AppleZertifikate  ... save of all apple certificates, downloaded from: "https://developer.apple.com/account/resources/" 
#       |
#       +-> Library/Keychains/iosbuild.keychain .................................................. ... accessed from Xcode
#       +-> Library/MobileDevice/Provisioning Profiles/ProfileAppStore_KivyTestApp.mobileprovision ... accessed from Xcode
#        
# 
# Notes to some global environment variables
# ------------------------------------------
#
#   ---------------------------------------------------------------------+------+----------------------+----------------------------------------------------------------
#   folder/file                                                          | type | shell variable       | comment
#   ---------------------------------------------------------------------+------+----------------------+----------------------------------------------------------------
#   ~/kivy_projects  ................................................... | dir  | ...                  | all kivy projects and their dependencies
#   ~/kivy_projects/kivytest/main.py ................................... | file | ...                  | kivy/python project-1: kivy-test: "hello world"
#   ~/kivy_projects/kivy-ios/ .......................................... | dir  | $KIVYIOS_ROOT        | actual kivy-ios as clode of: https://github.com/kivy/kivy-ios.git 
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/ .......................... | dir  | $PROJECT_DIR         | Xcode: project folder of: "~/kivy_projects/kivytest/main.py"
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/build/kivytestapp.xcarchive | dir  | $ARCHIVE_PATH        | Xcode: archive, holding the signed app-executable
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/dist ...................... | dir  | $EXPORT_PATH         | Xcode: archive, holding the signed app-executable       
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/ExportOptions.plist ....... | file | $EXPORT_OPTIONS      | Xcode: option file (generated by this script or provided manually)       
#   ---------------------------------------------------------------------+------+----------------------+----------------------------------------------------------------
#   ~/kivy_projects/kivy-ios-venv/   ................................... | dir  | $VENV                | virtual environment, established for all kivy/python projects 
#   ~/kivy_projects/kivy-ios-venv/lib/python3/site-packages/ ........... | dir  | $VENV_SITEPACKAGE    | - python side packages libs: kivy, kivymd, materialyoucolor, pillow, ...  
#   ---------------------------------------------------------------------+------+----------------------+----------------------------------------------------------------
#   "kivytestapp" ...................................................... | env  | $APP_NAME            | see: https://developer.apple.com/account/resources/identifiers/list
#   "com.example.yourapp" .............................................. | env  | $BUNDLE_ID           | see: https://developer.apple.com/account/resources/identifiers/list
#   "YOUR_TEAM_ID" ..................................................... | env  | $TEAM_ID             | see: https://developer.apple.com/account/resources/identifiers/list  ... seen on top/right - note: this MUST be the value as seen in brackits of $SIGN_IDENTITY-value
#   "Apple Distribution: YOUR_NAME (YOUR_TEAM_ID)" ..................... | env  | $SIGN_IDENTITY       | see: https://developer.apple.com/account/resources/certificates/list ... where it is generated - the value of $SIGN_IDENTITY is taken from MAC-cmd: "security find-identity -v -p codesigning"
#   "ProfileAppStore_KivyTestApp" ...................................... | file | $PROVISIONING_PROFILE| see: https://developer.apple.com/account/resources/profiles/list ....... for signing for export to TestFlight (Typ=App Store) 
#   "ProfileDeployment_KivyTestApp" .................................... | file | $PROVISIONING_PROFILE| see: https://developer.apple.com/account/resources/profiles/list ....... for signing for direct installation  (Typ=ad hoc) 
#   ---------------------------------------------------------------------+------+----------------------+----------------------------------------------------------------
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/simulator/                                                     | dir | $SIM_PATH    | Xcode-Simulator: generated files/folders for macSimulator
#   ~/kivy_projects/kivy-ios/kivytestapp-ios/simulator/Build/Products/Debug-iphonesimulator/kivytestapp.app | dir | $APP_PRODUCT | Xcode-Simulator: generated App bundle for macSimulator as installed to the Simulator by: xcrun simctl launch --console "$UDID" "$BUNDLE_ID_PRODUCT"
#   --------------------------------------------------------------------------------------------------------+-----+-----------------------------------------------------
#
#
# Execution of own (bash)-scripts from $PATH-extension
# ----------------------------------------------------
# These can be executed directly as  "<script>.sh <par1> <par2>"  or as  "bash <script>.sh <par1> <par2>", but "<script>.sh ..." works only, when:
# - the file is executable (chmod +x script.sh),
# - the Shebang-line (header line) is: ("#!/usr/bin/env bash"  or  "#!/bin/bash"),
# - line ending is LF (no CRLF).
# "bash <script>.sh" ignors the executable-bit & Shebang and enforces Bash this avoids errors as "zsh: bad substitution" & EOL-traps.
# This is the reason that I recommand to execute as: "bash <script>.sh ..."
#     
# 
# state      | editor  | comment
# -----------+---------+------------------------------------------------------------------------------------------------------------------------------------------------
# 2025-07-31 | W.Rulka | author (with support of Chat-GPT)
# ...        | ...     | ...
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
#
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# **********************************************************************************************************************************************************************
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
set -Eeuo pipefail
  
# Configuration (import environment variables, expand the path and activate virtual environment (venv))
# ------------- 
  source $HOME/kivy_projects/kivytest/__set_env_variables.sh  # set project env-variables -> [set depending env, expand path, activate (venv)]

# Copy from Git-Server: kivy-ios, kivyMD && Build Modules:  TOOLCHAIN BUILD: python3, kivy-ios, kivyMD, materialyoucolor, pillow, ... 
# --------------------------------------------------------  patched modules: sdl2, [ sdl2_image, sdl2_mixer, sdl2_ttf ] & python3
  bash build_install_and_build_modules.sh 
 
# APP - TOOLCHAIN: Allocate the Xcode project for the Kivy-App ( $PROJECTS/$APP/main.py ) 
# -------------------------------------------
  bash app_build__Project.sh    # Allocate the App as Xcode-project via: toolchain build <app>.
                                # This is done only once for a new project and is ignored, when folder $PROJECT_PATH exists
                                # with steps:
                                # - clean ..: rm -rf "$KIVYIOS_ROOT/${APP_NAME}-ios" 
                                # - toolchain clean  <app>                           
                                # - toolchain create <app>                           
                                # - toolchain build  <app>                           

# APP - XCODEBUILD: Build & Test iOS-executable for Simulator (arm64)
# -------------------------------------------------------------------
  bash app_build__Simulator.sh  # XcodeBuild for Simulator -> test run on Simulator
                                # with steps:
                                # - safety: ensure in project Info.plist: Bundle-ID = default = $BUNDLE_ID_PRODUCT = org.kivy.$APP_NAME
                                # - clean xcodebuild derived data & old artifacts: rm -rf "$KIVYIOS_ROOT/$APP_NAME-ios/simulator" "~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*"                  # clean (avoiding problems with older artifact's) -  SIM_PATH="$KIVYIOS_ROOT/$APP_NAME-ios/simulator" = "/Users/administrator/kivy_projects/kivy-ios/kivytestapp-ios/simulator" 
                                # - apply bug-fixes/patches, in particular if necessary for the Simulator
                                # - build <app> for Simulator via xcodebuild()
                                # - check for successful build and required bug-fixes/patches
                                # - start Simulator
                                # - boot  Simulator device
                                # - install and launch the <app> to the Simulator device
 
# APP - XCODEBUILD: Build & Certificate for distribution via TestFlight
# ---------------------------------------------------------------------
  bash app_build__myKeyChain.sh # build private keychain if already not available - required for remote archive build/certification
                                #
  bash app_build__TestFlight.sh # XcodeBuild for Archive -> Export -> Upload
                                # with steps:
                                # - activate private Keychain - unlock $MY_KEYCHAIN, increase timeout, use $MY_KEYCHAIN login.keychain 
                                # - verify signature identity - find "$SIGN_IDENTITY" in "$MY_KEYCHAIN" 
                                # - customize of project Info.plist with Bundle-ID & IconName
                                # - build AppIcon-set with all required icon-sizes 
                                # - clean xcodebuild derived data & old artifacts 
                                # - build App-archive via xcodebuild()
                                # - cleanup archive: remove static libraries <.a> (these are linked to the executable) 
                                #                    and dynamic libraries <.so> which are explictly not accepted from Upload/Apple-Store-Connect   
                                # - customize ExportOptions.plist
                                # - generate export (.ipa) for App-Store-Connect
                                # - upload to TestFlight via tool "fastlane"
  