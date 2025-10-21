#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# *************************************************  build_install_and_build_modules.sh  ************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: App-Build: install and build modules/packages, accessed from the App, written in Kivy or KivyMD
# --------            
#          - the implemented site-package (module) build is performed only if it is presumed as "already not done" 
#            or if it gets enforced by project specific env-variable: $CLEAN 
#
#          - build is done by: toolchain build"
#
#          - modules/packages: python3, kivy-ios, kivyMD, materialyoucolor, pillow, ...
#           
#          - following kivy-ios modules get patched: sdl2, [ sdl2_image, sdl2_mixer, sdl2_ttf ] 
#
# Inputs/Requirement
# ------------------
# - import environment variables and activate virtual environment (venv), by: 
# 
#     source ~/kivy_projects/kivytest/__set_env_variables.sh 
#     |
#     +-> source ~/Apple__ENV__/build_set_env_variables.sh
#
# Notes:
# -----
# - the project-specific env-variable $CLEAN defines the depth of the environment build
#   - CLEAN="none"          ....... no re-builds of build-environment requresetd
#                                   => perform xcodebuild() directly after modification of main.py,.... 
#
#   - CLEAN="clean_all"     ....... total reload of kivy-ios & kivyMD from Git, rebuild of kivy and its site packages, 
#                                   allocation of the project and project build
#                                     rm -rf ${PROJECTS}/common_libs  
#                                     rm -rf ${PROJECTS}/kivy-ios  
#                                     rm -rf ${PROJECTS}/kivy-ios-venv
#
#   - CLEAN="clean_kivymd"  ....... reload and rebuild kivyMD only
#                                     rm -rf ${PROJECTS}/common_libs/kivymd_git  
#                                     rm -rf ${PROJECTS}/kivy-ios/kivy_ios/recipes/kivymd
#                                     rm -rf ${PROJECTS}/kivy-ios/build/kivymd/
#                                    #rm -rf ${PROJECTS}/kivy-ios/dist/????/kivymd  
#                                    #rm -rf ${PROJECTS}/kivy-ios/build/???/kivymd  
#
#   - CLEAN="clean_kivyios" ....... perform reload of kivy-ios from Git, install, activate virtual env 
#
#   - CLEAN="clean_kivyios_site"... remove and rebuild kivy-ios site packages (kivy, kivymd, ...)
#                                     rm -rf ${PROJECTS}/kivy-ios/build/sdl2                      
#                                     rm -rf ${PROJECTS}/kivy-ios/build/python                      
#                                     rm -rf ${PROJECTS}/kivy-ios/build/kivy                      
#                                     rm -rf ${PROJECTS}/kivy-ios/build/kivymd                      
#                                     rm -rf ${PROJECTS}/kivy-ios/build/pillow
#                                     rm -rf ${PROJECTS}/kivy-ios/build/materialyoucolor                       
#                                   
#                                   note: the big-fix-script "build_bugfix_simulator__remaining_black_screen.sh", which is applied before "toolchain build ...",  
#                                         performs as well a DEEP-remove of "artefacs" and "state" (required for invoking a full re-build of sdl2) 
#                                   
#                                         rm -rf "$KIVYIOS_ROOT/build/sdl2"                           \
#                                                "$KIVYIOS_ROOT/dist/sdl2"                            \
#                                                "$KIVYIOS_ROOT/kivytestapp-ios/build/sdl2"           \
#                                                "$KIVYIOS_ROOT/kivytestapp-ios/dist/sdl2"            \
#                                                "$KIVYIOS_ROOT/dist/lib/iphoneos/libSDL2.a"          \
#                                                "$KIVYIOS_ROOT/dist/lib/iphonesimulator/libSDL2.a"   \
#                                                "$KIVYIOS_ROOT/dist/xcframework/libSDL2.xcframework" \
#                                                "$KIVYIOS_ROOT/.kivy-ios-state"                      \
#                                                "$KIVYIOS_ROOT/.kivy-ios-state.json"                 \
#                                                "$KIVYIOS_ROOT/.kivy-ios-state.sqlite"               \
#                                            "$HOME/.kivy-ios"
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
  
# --------------------------------------------------------
# Clean first, enforcing rebuilds
# --------------------------------------------------------
  if [ "$CLEAN" = "clean_all" ]; then
     rm -rf ${PROJECTS}/common_libs  
     rm -rf ${PROJECTS}/kivy-ios  
     rm -rf ${PROJECTS}/kivy-ios-venv
  
  elif [ "$CLEAN" = "clean_kivyios" ]; then
     rm -rf ${PROJECTS}/kivy-ios 

  elif [ "$CLEAN" = "clean_kivyios_site" ]; then 
     rm -rf ${PROJECTS}/kivy-ios/build/sdl2                      
     rm -rf ${PROJECTS}/kivy-ios/build/python                      
     rm -rf ${PROJECTS}/kivy-ios/build/kivy                      
     rm -rf ${PROJECTS}/kivy-ios/build/kivymd                      
     rm -rf ${PROJECTS}/kivy-ios/build/pillow
     rm -rf ${PROJECTS}/kivy-ios/build/materialyoucolor                       
     
  elif [ "$CLEAN" = "clean_kivymd" ]; then 
     rm -rf ${PROJECTS}/common_libs/kivymd_git           
     rm -rf ${PROJECTS}/kivy-ios/kivy_ios/recipes/kivymd 
     rm -rf ${PROJECTS}/kivy-ios/build/kivymd/           
  fi     

# --------------------------------------------------------
# Clone/Copy Kivy (kivy-ios) from Git-Server  ------------
# --------------------------------------------------------
  if [ -d ${KIVYIOS_ROOT} ]; then
     :
  else  
     build_kivy_ios__setup_venv.sh                       # Copy/Clone Kivy-IOS from Git, setup virtual environment (venv) and install kivy-ios to "venv" 
  fi
  source ${PROJECTS}/kivy-ios-venv/bin/activate          # activate virtual env (venv)
  
  # folder structure at this state is:
  # ==============================
  # -> ${PROJECTS}
  #    |
  #    +-> kivy-ios-venv ............................... virtual environment with link to: "${PROJECTS}/kivy-ios" - this is our local CLI-Tool-Environment executed on macOS, not on iOS!!!
  #    |   +-> bin/*  .................................. - executables as: "toolchain", pip*, python*, kivymd.add_view, kivymd.create_project, kivymd.make_release, rst*,  ... 
  #    |   +-> lib/python3.10/site-packages/ ........... - python paths with links to: ${PROJECTS}/kivy-ios  
  #    |
  #    +-> kivy-ios .................................... actualized with version, which provides command "toolchain" as: ${PROJECTS}/kivy-ios-venv/bin/toolchain
  #    +-> kivy_ios/recipes/<default_sitepackages> ..... - site-packes, supported by "kiv-ios" per default

# --------------------------------------------------------
# Clone/Copy KivyMD from Git-Server  --------------------- 
# --------------------------------------------------------
  if [ -d ${KIVYIOS_ROOT}/build/kivymd/ ]; then 
     :
  else
     build_install_KivyMD.sh                             # -> Copy/Clone KivyMD from Git
  fi                                                    
                                                        
  # folder structure at this state is:
  # ==============================
  # -> ${PROJECTS}
  #    |
  #    +-> common_libs/kivymd_git/kivmd ............. central storage of downloaded kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)
  #    |
  #    +-> kivy-ios-venv ............................ virtual environment with link to: "${PROJECTS}/kivy-ios" - this is our local CLI-Tool-Environment executed on macOS, not on iOS!!!
  #    |   +-> bin/*  ............................... - executables as: "toolchain", pip*, python*, kivymd.add_view, kivymd.create_project, kivymd.make_release, rst*,  ... 
  #    |   +-> lib/python3.10/site-packages/
  #    |       +-> __editable__.kivymd-*.pth ........ - NEW (by pip install -e) with link to: "${PROJECTS}/common_libs/kivymd_git/kivmd"
  #    |
  #    +-> kivy-ios ................................. actualized with version, which provides command "toolchain" as: ${PROJECTS}/kivy-ios-venv/bin/toolchain
  #        +-> kivy_ios/recipes/<*>  ................ default "kiv-ios" site-packes      
  #        +-> kivy_ios/recipes/kivymd .............. NEW (manual): site-packes enhanced with kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)       
  #                             +-> __init__.py       - our customized recipe for none-standard kivyMD-2.0.1.dev0 recipe ........................ file  manually copied from: ~/AppleKivy_recipe/kivymd/
  #                             +-> recipe.sh         - dummy, when "kivy-ios" is calling this script ........................................... file  manually copied from: ~/AppleKivy_recipe/kivymd/ 
  #                             +-> requirements.txt  - additional python dependencies of KivyMD-2.0.1.dev0 as: materialdesign, pygments, etc ... file  manually copied from: ~/AppleKivy_recipe/kivymd/
  #                             +-> kivymd/**/*.py,kv - py/kv-files for all KivyMD-modules (button, label, ...), ................................ files manually copied from: ~/kivy_projects/common_libs/kivymd_git/kivymd per "rsync" 
  
# --------------------------------------------------------------------------------
# TOOLCHAIN BUILD: Compile/Build modules python, kivy, kivmd, ... into virtual env 
# --------------------------------------------------------------------------------
# "toolchain build"                                                              |
# - builds third-party libs like: libpython, SDL2, Kivy, ...                     |
#   as XCFrameworks (ios-arm64-simulator)                                        |
# - generates the Xcode-Projekt : $APP_NAME-ios                                  |
#   *) Bootstrap: main.m (ObjC)                                                  |
#   *) Info.plist (ResourceFolder / PyMainFileName / ...)                        |
#   *) copies YourApp/ to the App-boundle                                        |
#   *) compile/build is done with SDK from "active" Xcode                        |
# --------------------------------------------------------------------------------
  if [ -d "${KIVYIOS_ROOT}/build/sdl2" ]; then
     echo "** everything is done -> continue building the <app>"
  else
     echo ""
     echo ""
     echo "** ================================================="
     echo "** TOOLCHAIN BUILD for kivy and side-package modules" # compile into virtual environment 
     echo "** ================================================="
     #
     # Check requirements
     # ------------------ 
     EXPECTED_PATH="$COMMON_KIVYMD/kivymd/__init__.py"           # -> CHECK if python knows the path to the side-package "kivymd"
     CURRENT_PATH=$(python -c "import kivymd; print(kivymd.__file__)" 2>/dev/null)
                                                                 #    ...
     if [ "$CURRENT_PATH" != "$EXPECTED_PATH" ]; then            #    ...
        echo "**) KivyMD not correctly linked - new installation -> exit"; exit 1
     fi                                                          # 
                                                                 #    
     export PYTHONPATH=$HOME                                     # -> PYTHONPATH is NECESSARY for getting to work compile of "kivymd" 
                                                                 #    Notes by ChatGPT: PYTHONPATH is necessary for kivymd, because 
                                                                 #    - toolchain  searches for recipes on base of a python-module-import (importlib.import_module(...))
                                                                 #    - our own kivymd recipe is located outside of the installation path of the kivy-ios-python-packages (that means, not under: site-packages)
                                                                 #    - this is the reason why PYTHONPATH must be set explicitly with objective to let python know at import time:
                                                                 #      "Ah – kivy_ios is located in the actual project folder!"        
     # Bug-Fixes for kivy-ios
     # ----------------------
       build_bugfix_toolchain_missed_libs.sh                     # bug: "toolchain build" is missing library <libpython3.11.a>, required from module "pillow"
       build_bugfix_simulator__remaining_black_screen.sh         # bug: remaining black screen on Simulator with runtime-iOS-17.x - the "SDL2-RGBA8-patch" (EAGL RGBA8 + retained backing + opaque)"
       build_bugfix_simulator__remaining_black_screen__check.sh  # check
       
     # Build site-packages: python3, kivy, kivyMD, ... considering the modified SDL2-recipe "$KIVYIOS_ROOT/kivy_ios/recipes/sdl2/__init__.py"
     # -----------------------------------------------
       # note-1: kivyMD requires: asynckivy, kivy, materialyoucolor, pillow, see cmd:  pip show kivymd   
       #
       # note-2: the sdl2-bug-fix above requires a rebuild of "sdl2 sdl2_image sdl2_mixer sdl2_ttf" as well instead of using pre-compiled version per default
       #
       # note-3: the first "build" MUST be applied to python3, else the build of "sdl2*" will fail
       #
       echo ""
       echo "** ===========================" 
       echo "** toolchain build for modules: python3, sdl2, sdl2_image, sdl2_mixer, sdl2_ttf, kivy, kivymd, materialyoucolor, pillow, ..." 
       echo "** ===========================" 
       echo ""
       cd "$KIVYIOS_ROOT"                                                                                        # implicit requirement for "toolchain"
       toolchain clean python3 sdl2 sdl2_image sdl2_mixer sdl2_ttf kivy kivymd materialyoucolor pillow $APP_NAME # optional toolchain-artefacts: clean cache for SDL2, Kivy, and ... 
       toolchain build python3 sdl2 sdl2_image sdl2_mixer sdl2_ttf kivy kivymd materialyoucolor pillow           # build
  fi            
  # folder structure at this state is:
  # ==============================
  # -> ${PROJECTS}
  #    |
  #    +-> common_libs/kivymd_git/kivmd ................ central storage of downloaded kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)
  #    |                                               
  #    +-> kivy-ios-venv ............................... virtual environment with link to: "${PROJECTS}/kivy-ios" - this is our local CLI-Tool-Environment executed on macOS, not on iOS!!!
  #    |   +-> bin/*  .................................. - executables as: "toolchain", pip*, python*, kivymd.add_view, kivymd.create_project, kivymd.make_release, rst*,  ... 
  #    |   +-> lib/python3.10/site-packages/kivymd ..... - NEW (manual): py/kv files accessed from macOS
  #    |                 ====                              
  #    +-> kivy-ios .................................... actualized with version, which provides command "toolchain" as: ${PROJECTS}/kivy-ios-venv/bin/toolchain
  #        +-> kivy_ios/recipes/<*>  ................... default "kiv-ios" site-packes      
  #        +-> kivy_ios/recipes/kivymd ................. site-packes enhanced with kivyMD of App-required state "kivyMD-2.0.1.dev0 (from 2025-08)       
  #        |                    +-- __init__.py          - our customized recipe for none-standard kivyMD-2.0.1.dev0 recipe ........................ file  manually copied from: ~/AppleKivy_recipe/kivymd/
  #        |                    +-- recipe.sh            - dummy, when "kivy-ios" is calling this script ........................................... file  manually copied from: ~/AppleKivy_recipe/kivymd/ 
  #        |                    +-- requirements.txt     - additional python dependencies of KivyMD-2.0.1.dev0 as: materialdesign, pygments, etc ... file  manually copied from: ~/AppleKivy_recipe/kivymd/
  #        |                    +-- kivymd/**/*.py,kv    - py/kv-files for all KivyMD-modules (button, label, ...), ................................ files manually copied from: ~/kivy_projects/common_libs/kivymd_git/kivymd per "rsync" 
  #        |  
  #        +-> dist/root/python3/lib                     iOS-Python runtime folder, which will be included into the ".app"-package).
  #        |   +-> python3.11/site-packages/kivy    .... - NEW (by toolchain): py/kv files accessed from iOS 
  #        |   +-> python3.11/site-packages/kivymd  .... - NEW (by toolchain): py/kv files accessed from iOS 
  #        |             ====
  #        +-> build  
  #            +-> kivy/iphone*-arm64/kivy-2.3.1/.build_done   .... NEW (by toolchain)
  #            +-> kivymd/iphone*-arm64/kivy-2.3.1/.build_done .... NEW (by toolchain)


