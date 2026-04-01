#!/bin/bash
# MarkScout — Mac App Store Build Script
#
# Prerequisites:
#   1. Apple Distribution certificate installed in Keychain
#   2. Mac Installer Distribution certificate installed in Keychain
#   3. Provisioning profile downloaded and placed in src-tauri/
#   4. Rust targets installed: rustup target add aarch64-apple-darwin x86_64-apple-darwin
#
# Usage:
#   TEAM_ID=XXXXXXXXXX ./scripts/build-mas.sh
#
# Outputs:
#   MarkScout.pkg — ready for upload to App Store Connect via Transporter

set -euo pipefail

# --- Configuration ---
TEAM_ID="${TEAM_ID:?Set TEAM_ID environment variable to your Apple Developer Team ID}"
APP_NAME="MarkScout"
BUNDLE_ID="com.markscout.app"
SIGNING_IDENTITY="Apple Distribution: Shahzad Ahsan (${TEAM_ID})"
INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Shahzad Ahsan (${TEAM_ID})"
ENTITLEMENTS="src-tauri/entitlements/MarkScout.entitlements"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "=== MarkScout Mac App Store Build ==="
echo "Team ID: $TEAM_ID"
echo "Project: $PROJECT_DIR"
echo ""

# --- Step 1: Build universal binary with MAS feature ---
echo "[1/5] Building universal binary with MAS feature flag..."
npx tauri build \
  --features mas \
  --target universal-apple-darwin \
  --config src-tauri/tauri.conf.mas.json

APP_PATH="src-tauri/target/universal-apple-darwin/release/bundle/macos/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Build failed — $APP_PATH not found"
  exit 1
fi

echo "   Built: $APP_PATH"
echo ""

# --- Step 2: Include PrivacyInfo.xcprivacy in the bundle ---
echo "[2/5] Adding PrivacyInfo.xcprivacy to bundle..."
cp src-tauri/PrivacyInfo.xcprivacy "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"
echo "   Done"
echo ""

# --- Step 3: Sign the .app ---
echo "[3/5] Signing .app with Apple Distribution certificate..."
codesign --deep --force --options runtime \
  --sign "$SIGNING_IDENTITY" \
  --entitlements "$ENTITLEMENTS" \
  "$APP_PATH"

echo "   Verifying signature..."
codesign --verify --deep --strict "$APP_PATH"
echo "   Signature valid"
echo ""

# --- Step 4: Create signed .pkg ---
echo "[4/5] Creating signed .pkg for App Store upload..."
PKG_PATH="${PROJECT_DIR}/${APP_NAME}.pkg"

xcrun productbuild \
  --sign "$INSTALLER_IDENTITY" \
  --component "$APP_PATH" /Applications \
  "$PKG_PATH"

echo "   Created: $PKG_PATH"
echo ""

# --- Step 5: Validate ---
echo "[5/5] Validating .pkg..."
xcrun altool --validate-app \
  -f "$PKG_PATH" \
  -t macos \
  --output-format json 2>&1 || echo "   (Validation requires Apple ID — upload via Transporter instead)"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Next steps:"
echo "  1. Open Transporter.app"
echo "  2. Drag ${APP_NAME}.pkg into Transporter"
echo "  3. Click 'Deliver' to upload to App Store Connect"
echo "  4. Go to appstoreconnect.apple.com to select the build and submit for review"
echo ""
echo "Alternatively, upload via CLI:"
echo "  xcrun altool --upload-app -f ${APP_NAME}.pkg -t macos -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD"
