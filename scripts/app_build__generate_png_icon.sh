#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ******************************************************  app_build__generate_png_icon.sh  **********************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: Dieses Helfer-Skript erzeugt dir "AppIconAssets.xcassets" / "AppIcon.appiconset" inkl. aller Pflichtgrößen aus einem 1024×1024-PNG. 
# -------- Danach in Xcode/Build-Settings: Asset Catalog App Icon Set Name = AppIcon (im Haupt-Target) sicherstellen – das macht 
#          das Skript "./app_build__TestFlight.sh" beim Archivieren ebenfalls via Build-Setting. 
#
#          Aufruf-Beispiel: ./app_build__generate_png_icon.sh ~/icon1024.png "$HOME/kivy_projects/kivy-ios/kivytestapp-ios" "kivytestapp"
#
#          Hint: Das 1024er "Marketing-Icon" wird nicht in die App gebündelt, aber du kannst es als Quelle zum Runterskalieren verwenden. 
#                Für die Einreichung in App Store Connect brauchst du das 1024er zusätzlich im Store-Listing.
#
# Inputs
# ------
# - SRC     =$1 ... name of 1024x1024 PNG-icon  , for example: "$PROJECTS/$APP/app_icon1024.png" // ~/kivy_projects/kivytest/app_icon1024.png
# - PROJ_DIR=$2 ... name of valid "PROJECT_DIR" , for example: "$KIVYIOS_ROOT/${APP_NAME}-ios"   // ~/kivy_projects/kivy-ios/kivytestapp-ios/
# - APP_NAME=$3 ... app-name                    , for example: "kivytestapp"   
#
# - global env-variables: $HOME/kivy_projects/<app>/__set_env_variables.sh
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
set -Eeuo pipefail
  
# Requirement /Configuration (import environment variables and activate virtual environment (venv))
# -------------------------- 
  # source ~/kivy_projects/kivytest/__set_env_variables.sh # presumed to be performed in calling shell: set project specific env-variables
  # source ~/Apple__ENV__/build_set_env_variables.sh       # .........................................: set depending env-variables, expand path, activate (venv)
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# Usage            : ./app_build__generate_png_icon.sh <.../Icon1024.png> <.../PROJECT_DIR> <App_Name> 
# Legt/aktualisiert: PROJECT_DIR/Images.xcassets/AppIcon.appiconset

# Get/map inputs $1,$2,$3
# -----------------------
  SRC="${1:-}"
  PROJ_DIR="${2:-}"
  APP_NAME="${3:-}"

  [[ -f "$SRC"                ]] || { echo "Please give 1024x1024 PNG."                  ; exit 1; }
  [[ -d "$PROJ_DIR"           ]] || { echo "Please give valid PROJECT_DIR."              ; exit 1; }
  [[ -n "$APP_NAME"           ]] || { echo "ERROR: APP_NAME is empty"                    ; exit 1; }
  [[ -d "$PROJ_DIR/$APP_NAME" ]] || { echo "ERROR: folder not found: $PROJ_DIR/$APP_NAME"; exit 1; }
         
  sips -Z 1024 "$SRC" --out "$SRC"  # this script expects the icon-file as "1024×1024 PNG" -> ensure by scaling

# Configuration
# -------------
  AC_DIR="$PROJ_DIR/$APP_NAME/Images.xcassets" 
  SET_DIR="$AC_DIR/AppIcon.appiconset"         # note: Xcode liest standardmäßig: "$PROJECT_DIR/$APP_NAME/Images.xcassets/AppIcon.appiconset"
  
  mkdir -p "$SET_DIR"

# desired values (px): file name - # "Größe:Dateiname" Paare – reicht für iPhone/iPad Pflichtgrößen
# ------------------------------
  pairs="120:Icon-60@2x.png 180:Icon-60@3x.png 152:Icon-76@2x.png 167:Icon-83.5@2x.png 1024:ItunesArtwork@2x.png"

  for pair in $pairs; do
    sz="${pair%%:*}"
    fname="${pair#*:}"
    sips -Z "$sz" "$SRC" --out "$SET_DIR/$fname" >/dev/null
  done
  
  cat > "$SET_DIR/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "Icon-60@2x.png",   "idiom" : "iphone"   , "scale" : "2x", "size"    : "60x60" },
    { "filename" : "Icon-60@3x.png",   "idiom" : "iphone"   , "scale" : "3x", "size"    : "60x60" },
    { "filename" : "Icon-76@2x.png",   "idiom" : "ipad"     , "scale" : "2x", "size"    : "76x76" },
    { "filename" : "Icon-83.5@2x.png", "idiom" : "ipad"     , "scale" : "2x", "size"    : "83.5x83.5" },
    { "idiom"    : "ios-marketing"   , "size"  : "1024x1024", "scale" : "1x", "filename": "ItunesArtwork@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "ok: AppIcon.appiconset generated in: $SET_DIR with AppIconSetName='AppIcon'"
#     -> Ensure, that in the <Target-Build-Setting> is: 'Asset Catalog App Icon Set Name' = AppIcon 
#     -> this is implemented in: ./app_build__TestFlight.sh"
