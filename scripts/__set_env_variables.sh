#!/bin/bash
#
# >>> Anonymized version: adjust to you (team-id, passwd, install path of "KivyApp__build_iOS"         <<<
# >>>                     and your <App>-name (here is used: kivytest)                                 <<<
# >>> Copy THIS file to the folder, there your App is located (main.py, __init__.py, app_icon1024.png) <<<
#
# --------------------------------------------------------------------------------------------------------------------------------------
# ******************************************************  __set_env_variables.sh  ******************************************************
# --------------------------------------------------------------------------------------------------------------------------------------
# -------
# Purpose: - define depending and general env-variables 
# -------    which are accessed from the "build_<project>.sh" scripts provided within the ~/Apple/ folder.
#
#          - call "buld_set_env_variables.sh" in order to set depending parameters as well and to expand the PATH
#
# Perform: "source <this_file>.sh" in order to make following parameters available in current terminal-session
#           *********************
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

  export WKDIR=`pwd`                                                            # folder of current <project>, to which will be returned in (some) error cases
  
# Configuration
# ------------- 
  export APP="kivytest"                                                         # see: "Apple-developer-portal: https://developer.apple.com/account/apps
  export APP_NAME="kivytestapp"                                                 #
  export APP_ICON_1024="app_icon1024.png"                                       # name of the App master-icon in App-Store required resoulution 1024x1024 and of required type "png"
  export BUNDLE_ID="org.test.$APP_NAME"                                         # bundle-id as specified in the "Apple-developer-portal": "https://developer.apple.com/account/resources/identifiers/list" or Apple-Connect-portal: "https://appstoreconnect.apple.com/apps/6749379249/distribution/info"
  export BUNDLE_ID_PRODUCT="org.kivy.$APP_NAME"                                 # bundle-id as expected in mac-Simulator    
  export TEAM_ID="YOUR_TEAM_ID"                                                 # see: "Apple-developer-portal: https://developer.apple.com/account/resources
  export SIGN_IDENTITY="Apple Distribution: YOUR_NAME_AT_PORTAL ($TEAM_ID)"     #
  export PROVISIONING_PROFILE="ProfileAppStore_KivyTestApp"                     # see: "Apple-developer-portal: https://developer.apple.com/account/resources/profiles/list - type: "App Store" as required from TestFlight
  export PASSWD="__KEYCHAIN_PASSWORD__"                                         # passwd for p12-key-boundle as: my_testapp.p12, ...  
  export API_KEY_ID="YOUR_AppStoreConnect_KEY_ID"                               # see: "App Store Connect" access data: my keyID    ... (AppStoreConnect: https://appstoreconnect.apple.com/access/users/) 
  export API_ISSUER_ID="YOUR_AppStoreConnect_ISSUER_ID"                         # see: "App Store Connect" access data: my issuerID ...  ...  
  #
  # define "clean" before project build (toolchain build <proj>; xcodebuild)
  #
  export CLEAN="none"                                                           # -> perform xcodebuild() directly after modification of main.py,.... 
  #      CLEAN="clean_all"                                                      # -> total reload of kivy-ios & kivyMD from Git, rebuild of kivy and its site packages, allocation of the project and project build
  #      CLEAN="clean_kivyios"                                                  # -> total remove of kivy-ios folder => load kivy-ios from git -> activate virtual env -> perform toolchain build to all kivy-ios site packages
  #      CLEAN="clean_kivyios_site"                                             # -> perform DEEP clean of kivy-ios folders => 
  #      CLEAN="clean_kivymd"                                                   # -> reload and rebuild kivyMD only
 
# Set depending env-variables, expand PATH and activate virtual environment (venv)  
# --------------------------------------------------------------------------------
  source "$HOME/KivyApp_Build_iOS/build_set_env_variables.sh"  

