#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ********************************************************   app_build__myKeyChain.sh   *************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: Setup private Keychain - necessary for REMOTE builds of <app>-archives/uploads, or more precise for the remote certification-steps
# --------  
#          The Apple security police DOES NOT allow a remote unlock of the login.keychain.
#          The unlock of the keychain is required for the <app>-certification process and the build of the <app>-archive.  
#          To workaround that restriction, a PRIVATE keychain gets generated, gets expanding the keychain lists and getbe set to the default.
#
#          "${MY_KEYCHAIN}-db" is build only, if it already DOES NOT exist in "$HOME/Library/Keychains/", else nothing is done 
#
# Inputs
# ------
# - $CERTFICATES/my_testapp.p12 ......... 
# - $CERTFICATES/my_testapp_key.key   ... private key, generated remote with: openssl req -new -newkey rsa:2048 -nodes -keyout my_testapp_key.key -out my_testapp_request.csr -subj "/CN=Wolfgang Rulka/emailAddress=rulka@web.de"
# - $CERTFICATES/apple_deployment.pem ... distribution certificate (type (AppStore) ................. as defined with Apple-developer-portal: https://developer.apple.com/account/  
# - $CERTFICATES/AppleWWDRCAG4.pem    ... current Apple intermediate certificate (G3,G2 are obsolete) as defined with Apple-developer-portal: https://developer.apple.com/account/  
# - $SIGN_IDENTITY ...................... "Apple Distribution: YOUR_NAME (YOUR_TEAM_ID)"   as defined with Apple-developer-portal: https://developer.apple.com/account/  
# - $PASSWD ............................. user defined passwd for p12-key-boundle as: my_testapp.p12, ... 
#
# Result
# ------
# - ${MY_KEYCHAIN}-db=$HOME/Library/Keychains/iosbuild.keychain-db ... my Xcode key-chains enhancing user-specific "login.keychain".
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
# CERTFICATES="$HOME/AppleZertifikate"  
# SIGN_IDENTITY="Apple Distribution: YOUR_NAME (YOUR_TEAM_ID)"
# PASSWD="__KEYCHAIN_PASSWORD__" 
# MY_KEYCHAIN="$HOME/Library/Keychains/iosbuild.keychain"    
 
# ----------------------------------------------------------------------
# Ensure Xcode certification requirements  -----------------------------
# ----------------------------------------------------------------------
  # export <.p12> again 
  # - note: IOS-distribution needs:
  #         - the "apple distribution certificate (*.cer), 
  #         - the intermediate certifacte AppleWWDRCAG4 (G2,G3 is no more supported (state: 2025-07-30)) 
  #  
  if [[ ! -f "${MY_KEYCHAIN}-db" ]]; then
     echo ""
     echo ""
     echo "**) build <.p12>-bundle file and import it to <security> and finally release it"
     echo ""
     echo ""   
     
     cd $CERTFICATES 
     openssl pkcs12                        \
        -export                            \
        -legacy                            \
        -out          my_testapp.p12       \
        -inkey        my_testapp_key.key   \
        -in           apple_deployment.pem \
        -certfile     AppleWWDRCAG4.pem    \
        -name         ${SIGN_IDENTITY}     \
        -passout pass:${PASSWD}            # => result is ./my_testapp.p12
     
     security import my_testapp.p12 \
        -k ${MY_KEYCHAIN}           \
        -P ${PASSWD}                \
        -T /usr/bin/codesign        \
        -T /usr/bin/xcodebuild      \
        -T /usr/bin/security        # => result is $MY_KEYCHAIN="~/Library/Keychains/iosbuild.keychain"   

     # activate private Keychain
     # -------------------------
     if [[ -f "${MY_KEYCHAIN}-db" ]]; then
        echo "Unlock private KeyChain: $MY_KEYCHAIN"
        security  unlock-keychain -p        "$PASSWD" "$MY_KEYCHAIN"                || true   # unlock keychain + increase timeout (for example: 6h)
        security     set-keychain-settings -lut 21600 "$MY_KEYCHAIN"                || true   # ...
        security    list-keychains -s                 "$MY_KEYCHAIN" login.keychain || true   # set keychain-search sequence: private one before login.keychain
        security default-keychain  -s                 "$MY_KEYCHAIN"                || true   # set private keychain as default (important for xcodebuild)
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PASSWD" "$MY_KEYCHAIN" || true   # expand key-partition-list (rights for tools)
     fi
  fi
