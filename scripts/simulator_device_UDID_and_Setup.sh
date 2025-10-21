#!/bin/bash
set -Eeuo pipefail
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# *****************************************************  simulator_device_UDID_and_Setup.sh  ********************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------
#
# --------                     
# Purpose: iPhone-Simulator mit gewünschter Runtime finden/erstellen/booten und "nur" die UDID auf STDOUT ausgeben (Logs -> STDERR).
# -------- 
#      
# Aufruf (Defaults: "iOS 17.2", "iPhone 15"):
# ------
#           UDID="$(./simulator_device_UDID_and_Setup.sh "iOS 17.2" "iPhone 15")"
#           # oder still:
#           UDID="$(./simulator_device_UDID_and_Setup.sh 2>/dev/null)"
#
# Optional: RUNTIME_NAME per 1. Arg, MODEL_NAME per 2. Arg setzen.
#
#           - andere Runtime    :  RUNTIME_NAME="iOS 17.4"  
#           - Wunsch-Gerätetypen:  MODEL_NAME="iPhone 15 Pro,iPhone 15,iPhone SE (3rd generation)"
# 
#
# state      | author  | comment
# -----------+---------------------------------------------------------------------------------------------------------------------------------------
# 2025-10-02 | W.Rulka | author (by chatGPT) 
# ...        | ...     | ...
# 
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# ***************************************************************************************************************************************************
# ---------------------------------------------------------------------------------------------------------------------------------------------------

log(){ printf '%s\n' "$*" >&2; }

RUNTIME_NAME="${1:-iOS 17.2}"
MODEL_NAME="${2:-iPhone 15}"
PYTHON="/usr/bin/python3"   # aus Xcode; unabhängig von pyenv

# 1) Runtime-ID holen (z.B. com.apple.CoreSimulator.SimRuntime.iOS-17-2)
RUNTIME_ID="$(
"$PYTHON" - "$RUNTIME_NAME" <<'PY'
import json, subprocess, sys
name=sys.argv[1]
data=json.loads(subprocess.check_output(
    ["xcrun","simctl","list","-j","runtimes"], text=True))
rid=""
for rt in data.get("runtimes", []):
    if rt.get("name")==name and (rt.get("isAvailable", True) or
                                 str(rt.get("availability","")).startswith("available")):
        rid = rt.get("identifier") or rt.get("id") or ""
        break
if not rid:
    # Fallback: aus dem Namen einen Suffix wie iOS-17-2 ableiten
    suf = name.replace(" ", "-").replace(".", "-")
    for rt in data.get("runtimes", []):
        if (rt.get("identifier","").endswith(suf) and
           (rt.get("isAvailable", True) or str(rt.get("availability","")).startswith("available"))):
            rid = rt.get("identifier"); break
print(rid)
PY
)"
[ -n "$RUNTIME_ID" ] || { log "ERROR: Runtime '$RUNTIME_NAME' not available. Xcode ? Settings ? Platforms."; exit 2; }

# 2) Passendes Device (Booted bevorzugt, sonst Shutdown) suchen
FOUND_LINE="$(
"$PYTHON" - "$RUNTIME_ID" "$MODEL_NAME" <<'PY'
import json, subprocess, sys
rid, model = sys.argv[1:3]
data=json.loads(subprocess.check_output(
    ["xcrun","simctl","list","-j","devices"], text=True))
booted=None; shutdown=None
for key, arr in data.get("devices", {}).items():
    same_rt_key = (key == rid)
    for d in arr:
        if not d.get("isAvailable", True): continue
        same_rt = same_rt_key or d.get("runtime")==rid or d.get("runtimeIdentifier")==rid
        if not same_rt: continue
        if d.get("name")!=model: continue
        st = d.get("state")
        if st=="Booted" and booted is None: booted=d["udid"]
        elif st!="Booted" and shutdown is None: shutdown=d["udid"]
if booted:
    print("Booted "+booted)
elif shutdown:
    print("Shutdown "+shutdown)
PY
)"
state="${FOUND_LINE%% *}"
udid="${FOUND_LINE#* }"
[ "$state" != "$udid" ] || udid=""

# 3) Falls kein Gerät gefunden: DeviceType-ID ermitteln & neu anlegen
if [ -z "$udid" ]; then
  # DeviceType via JSON suchen (robuster als String zusammenzusetzen)
  DEVTYPE_ID="$(
  "$PYTHON" - "$MODEL_NAME" <<'PY'
import json, subprocess, sys
model=sys.argv[1]
data=json.loads(subprocess.check_output(
    ["xcrun","simctl","list","-j","devicetypes"], text=True))
ident=""
for dt in data.get("devicetypes", []):
    if dt.get("name")==model:
        ident=dt.get("identifier",""); break
print(ident)
PY
  )"
  if [ -z "$DEVTYPE_ID" ]; then
    log "ERROR: Device type '$MODEL_NAME' not found. Try one of:"
    xcrun simctl list devicetypes | sed -n 's/^\(iPhone[^()]*\) (.*/  \1/p' >&2
    exit 4
  fi
  # simctl create ? gibt UDID auf STDOUT aus
  udid="$(xcrun simctl create "$MODEL_NAME" "$DEVTYPE_ID" "$RUNTIME_ID" 2>/dev/null || true)"
  udid="${udid//$'\r'/}"
  udid="${udid//$'\n'/}"
  if ! [[ "$udid" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
    # Fallback: frisch angelegtes Gerät noch einmal suchen
    udid="$(
    "$PYTHON" - "$RUNTIME_ID" "$MODEL_NAME" <<'PY'
import json, subprocess, sys
rid, model = sys.argv[1:3]
data=json.loads(subprocess.check_output(
    ["xcrun","simctl","list","-j","devices"], text=True))
for key, arr in data.get("devices", {}).items():
    if key != rid: continue
    for d in arr:
        if d.get("name")==model and d.get("isAvailable", True):
            print(d.get("udid","")); sys.exit(0)
print("")
PY
    )"
  fi
  [ -n "$udid" ] || { log "ERROR: simctl create failed (no UDID)."; exit 5; }
  state="Shutdown"
fi

# 4) Nur wenn nicht Booted: booten + auf Ready warten (stumm)
if [ "$state" != "Booted" ]; then
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus -b "$udid" >/dev/null 2>&1 || true
fi

# 5) Nur UDID auf STDOUT
printf '%s\n' "$udid"
