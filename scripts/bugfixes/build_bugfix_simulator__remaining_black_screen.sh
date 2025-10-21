#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# *********************************************  build_bugfix_simulator__remaining_black_screen.sh  *************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: BugFix for App running on macSimulator - the so-called SDL2-RGBA8-patch (RGBA8 + retained backing + opaque=YES)
# -------- 
#          - Bug: - remaining black screen on Simulator iPhone device with runtime-iOS-17.x
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
  
  
# Bug-Fix for Mac-Simulator: "remaining black screen on Simulator devices: iPhone" - the "SDL2-RGBA8-patch" (EAGL RGBA8 + retained backing + opaque) 
# ---------------------------------------------------------------------------------------------------------
# - Problem : The "remaining black-screen" seems to be a classical well known EAGL-Layer/Simulator-Bug. 
# - Cause   : The most common cause is an unfortunate combination of prebuilt "SDL2-XCFramework" running in "Simulator-Runtime-iOS"
# - Action  : Build SDL2 yourself via kivy-ios and force "toolchain" not to use the prebuilts:          
# - Goal    : It gets ensured that the libSDL2.a/XCFramework comes from your environment and matches the SDK/Runtime.        
#             This surprisingly often fixes the black screen "swap" problem on Simulator-Runtime-iOS 17.x.             
#
# - Solution: This is fixed by editing the source ".../SDL_uikitopenglview.m" directly - see: _rgba8_fix()).
#             There it gets enforced: "RGBA8 + retained backing + opaque=YES" in the EAGL-Layer.
#    
#             - Don't use the pre-build-SDL2 but rebuild the SDL2 libraries.
#             - Enforce: "RGBA8 + retained backing + opaque=YES" in the EAGL-Layer.
#             
#             - All this is edited in modified recipe: ~/kivy_projects/kivy-ios/kivy_ios/recipes/sdl2/__init__.py 
#                                     ***************                                            ****************
#             - Ensure that the SDL2-recipe does not use any pre-builds by:
#               - editing: ~/kivy_projects/kivy-ios/kivy_ios/recipes/sdl2/__init__.py
#               - set a flag o. 
#               - remove prebuild-paths. 
#               Short:
#               - self.prebuilt_path = None
#               - return False in "has_prebuilt()" (if existing)
#             
#             - new functions in .../__init__.py is: "def _rgba8_fix()", ...:
#
# - Result  : This is fixed together with correct xcodebuild-flags (see BugFix-A below) 
#             a simple standard "Hello World"-App written in pure "Kivy", works on Simulator-iPhone with runtime-iOS-17.2
#             but still leaves/end directly after its launch with runtime-iOS-17.5.
#
#             The test-app main.py:
#                 +------------------------------------------------------------+
#                 | from kivy.app         import  App                          |
#                 | from kivy.uix.label   import  Label                        |
#                 | from kivy.core.window import  Window                       |
#                 |                                                            |
#                 | class Hello(App):                                          |
#                 |     def build(self):                                       |
#                 |         Window.clearcolor = (0.2, 0.6, 0.9, 1)             |
#                 |         return Label(text="Hallo World", font_size="24sp") |
#                 |                                                            |
#                 | Hello().run()                                              |
#                 +------------------------------------------------------------+
#
# ---------------------------------------------------------------------------------------------------------
  echo ""
  echo "** ===============" 
  echo "** BugFix for SDL2: problem-1: remaining black screen on Simulator iPhone devices on Simulator runtime-iOS-17.x" 
  echo "** ===============  solution : apply the <SDL2-RGBA8-patch> (EAGL RGBA8 + retained backing + opaque)"   
  echo "**                  result   : the App works on Simulator with runtime-iOS-17.2 but still crashes/stops on 17.5" 
  echo ""
  echo "** BugFix for SDL2 action: update/modify the SDL2-recipe (.../kivy_ios/recipes/sdl2/__init__.py) and rebuild SDL2" 
  echo "** ======================" 

  if [ -f ~/AppleKivy_recipe/sdl2/__init__.py ]; then 
       cp ~/AppleKivy_recipe/sdl2/__init__.py \
          $KIVYIOS_ROOT/kivy_ios/recipes/sdl2/__init__.py
  else
     echo "** ERROR for Mac-Simulator bug-fix (of black screen): the modified SDL2-recipe ~/AppleKivy_recipe/sdl2/__init__.py does not exist -> exit"  
     exit 1
  fi
  #
  # For getting the new/added (none-default) patch working, we MUST totally clean the sdl2 target folder/files first.
  # 
  # a) remove "Toolchain-Marker" for SDL2 
       cd ${PROJECTS}/kivy-ios   # - implicit requirement for "toolchain"
       toolchain clean sdl2      # - clean                                                                
  #
  # b) remove "artefacs" and "state" (required for invoking a full re-build of sdl2) // note: folder "$KIVYIOS_ROOT/kivytestapp-ios/build/" results from previous recipe-states and can/must be remove for clear/unique folder structure
       cd ${PROJECTS}/kivy-ios
       rm -rf build/ dist/ .kivy-ios* ~/.kivy-ios                 || true  # Toolchain caches & state
       rm -rf "$KIVYIOS_ROOT/${APP_NAME}-ios"                     || true  # App folder regenerated by toolchain create <app>
       rm -rf ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-* || true  # Xcode DerivedData for this scheme
  # 
  # d) rebuild SDL2-module
  #
  #    note: the original "sdl2"-recipe requires that "python3" and "hostpython3" is already build,
  #          but the previous "deep clean (rm -rf) has removed these modules as well.
  #          => if yout want to re-establish the original/unpatched version you
  #             first have to build  "python3" and "hostpython3"  
  #          => the currently patched sdl2-recipe (__kinit__.py) avoids completely the dependency of "hostpython_ver"
  #             -> the "toolchain build sdl2" can be build independently
  #
  #    build, based on original (but buggy) sdl2-recipe
  #      cd ${PROJECTS}/kivy-ios                                                # implicit requirement for "toolchain"
  #      toolchain clean hostpython3 python3 sdl                                #
  #      toolchain build hostpython3 python3 sdl2 2>&1 | tee /tmp/tc_build.log  # modules MUST be given as ONE command, if a previously "deep" clean (rm -rf) was done - see chatGPT
  # 
  #   rebuild SDL2-module with patched sdl2-recipe
       cd ${PROJECTS}/kivy-ios   # implicit requirement for "toolchain"
       toolchain build sdl2 2>&1 | tee /tmp/tc_build.log
