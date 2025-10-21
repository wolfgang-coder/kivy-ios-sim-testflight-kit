#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# *************************************************  build_bugfix_toolchain__missed_libs.sh  ********************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: BugFix for "toolchain build": missing library <libpython3.11.a>, required from module "pillow" which is used by "kivyMD" 
# -------- 
#          Note: a "pure kivy" application does not access "pillow" and therfore it does not show that missing library bug. 
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
  
# Bug-Fix - necessary customizings
# --------------------------------
# In the standard recipe "__init__.py" of "python3" the library "libpython3.11.a" gets removed in the clean section
# but the tool/module "pillow" needs this for its's build 
# => therefore this recipe "__init__.py" MUST be customized by <staying with library <libpython3.11.a>   
  echo ""
  echo "** ==================" 
  echo "** BugFix for python3: pillow needs library <libpython3.11.a> which gets remove with standard/default python3-recipe"
  echo "** ==================  solution: modify python3-recipe __init__.py"
  echo ""
  cp "$HOME/AppleKivy_recipe/python3/__init__.py"  "$KIVYIOS_ROOT/kivy_ios/recipes/python3"  
