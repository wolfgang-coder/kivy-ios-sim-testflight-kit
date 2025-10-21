# kivy-ios → Simulator → TestFlight Kit (Xcode 16 / iOS 18)

A ready-to-run shell workflow that builds a **Kivy / KivyMD** app for the **iOS Simulator**, archives it for **App Store Connect**, exports an **.ipa**, and uploads via **fastlane** — including hardened fixes for the 17.x Simulator black‑screen issue (SDL2 RGBA8) and the Pillow/libpython static-lib hiccup.

> All scripts prefer **manual signing** (App Store profile) and are safe for **headless/remote** CI use with a private keychain.

## What’s inside

```
scripts/
  build_ios.sh                         # entrypoint from your app folder
  __set_env_variables.sh               # app-specific env (edit this)
  build_set_env_variables.sh           # shared env: paths, venv activate, helpers
  app_build__Project.sh                # toolchain create/build <app>
  app_build__Simulator.sh              # xcodebuild for Simulator + simctl install/launch
  app_build__TestFlight.sh             # archive → export → upload (fastlane)
  app_build__myKeyChain.sh             # create/unlock private keychain (remote signing)
  app_build__generate_png_icon.sh      # build AppIcon.appiconset from 1024×1024 PNG
  build_install_and_build_modules.sh   # install kivy-ios + build python3/sdl2/kivy/kivymd…
  bugfixes/
    build_bugfix_simulator__remaining_black_screen.sh   # SDL2 RGBA8 + retained backing
    build_bugfix_simulator__check_all.sh                # assert patches present
    build_bugfix_toolchain__missed_libs.sh              # keep libpython3.x.a for Pillow
    simulator_device_UDID_and_Setup.sh                  # ensure/find & boot a Simulator
docs/
  CallGraph.txt
LICENSE
.gitignore
```

## Requirements

- **macOS 14.7+** on Apple Silicon (verified)
- **Xcode 16.2+** (`xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer`)
- iOS **18.2** SDK and **Simulator runtime** installed
- **Python 3.10/3.11** on host, plus `virtualenv`
- Apple Developer Program account + **App Store** provisioning profile
- Distribution/Installation via TestFlight requires an App-Store-Connect account
- The app must provide an `icon`.png image in resolution 1024x1024

## Quick start

1. Copy `scripts/` into your app repo and edit `scripts/__set_env_variables.sh`:
   - `APP`, `APP_NAME`, `BUNDLE_ID` (`com.example.yourapp`), paths.
   - Signing: `TEAM_ID="YOUR_TEAM_ID"`, `SIGN_IDENTITY="Apple Distribution: YOUR_NAME (YOUR_TEAM_ID)"`,
     `PROFILE_NAME="ProfileAppStore_YourApp"`, `MY_KEYCHAIN="$HOME/Library/Keychains/iosbuild.keychain"`.
   - Distribution (TestFlight): `API_KEY_ID="YOUR_AppStoreConnect_KEY_ID"`, `API_ISSUER_ID="YOUR_AppStoreConnect_ISSUER_ID"` 


2. From your app folder (where `main.py` lives):
   ```bash
   bash scripts/build_ios.sh
   ```
   - Choose **Simulator** or **Archive/Export/Upload** per prompts, or call sub-scripts directly.

### Simulator

- Ensures an iPhone 15 on **iOS 18.2** (or 17.2) exists and is booted.
- Builds with `xcodebuild -sdk iphonesimulator` and launches with `simctl`.

### Archive → Export → Upload

- Archives with `-sdk iphoneos` + **manual signing**.
- Exports `.ipa` via `ExportOptions.plist` (`method=app-store-connect`).
- Uploads through **fastlane pilot** (App Store Connect API key).

## App Icon

Run once to generate an asset catalog from a 1024×1024 PNG:
```bash
bash scripts/app_build__generate_png_icon.sh /path/to/Icon1024.png /path/to/PROJECT_DIR YOUR_APP_TARGET
```
The scripts will set `CFBundleIconName` and compile the catalog.

## Sensitive data

This bundle is sanitized (team id, names, emails, passwords replaced by placeholders).
**Replace placeholders** in `__set_env_variables.sh` with your values before use.
**Never commit** `.p8`, `.mobileprovision`, or real keychains.

## Known notes

- For Simulator black screen on iOS 17.x, the SDL2 RGBA8 patch is applied by `bugfixes/build_bugfix_simulator__remaining_black_screen.sh`.
- App Store rejects bundles containing stray `.a`/`.xcframework`/`.so`. The TestFlight script enforces a clean bundle.
- The simulator build requires in Info.plist the default kivy-ios bundle-id  `org.kivy.YourAppName` with `YourAppName` als the app name defined in Apple-Developer portal. But the archive build requires in Info.plist the App bundle-id as sepcifed in `xxx.xxxxx.YourAppName` in the Apple-Developer portal. 


## License

MIT — see `LICENSE`.
