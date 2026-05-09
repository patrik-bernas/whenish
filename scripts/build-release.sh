#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/src/TimezoneApp.xcodeproj"
SCHEME="TimezoneApp"
CONFIGURATION="Release"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Whenish.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
EXPORT_OPTIONS="$ROOT_DIR/config/ExportOptions.plist"
APP_PATH="$EXPORT_PATH/TimezoneApp.app"

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

if codesign -d --entitlements - "$APP_PATH" 2>/dev/null | grep -q "com.apple.security.get-task-allow"; then
  echo "Refusing to package app: get-task-allow is present in release entitlements." >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [[ "${NOTARIZE:-0}" == "1" ]]; then
  : "${NOTARY_PROFILE:?Set NOTARY_PROFILE to the notarytool keychain profile name.}"
  ditto -c -k --keepParent "$APP_PATH" "$EXPORT_PATH/Whenish.zip"
  xcrun notarytool submit "$EXPORT_PATH/Whenish.zip" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
fi

echo "Release app exported to $APP_PATH"
