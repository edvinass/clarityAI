#!/usr/bin/env bash
#
# Build and launch ClarityAI.
#
# Usage:
#   ./run.sh            Build (Debug) and launch the app
#   ./run.sh release    Build (Release) and launch the app
#   ./run.sh build      Build only, do not launch
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT="ClarityAI.xcodeproj"
SCHEME="ClarityAI"
APP_NAME="ClarityAI"
BUILD_DIR="$SCRIPT_DIR/build"

CONFIGURATION="Debug"
LAUNCH=true

for arg in "$@"; do
    case "$arg" in
        release|Release) CONFIGURATION="Release" ;;
        debug|Debug)     CONFIGURATION="Debug" ;;
        build)           LAUNCH=false ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

echo "==> Building ${APP_NAME} (${CONFIGURATION})..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_DEBUG_DYLIB=NO \
    build \
    | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" || true

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "==> Build failed: $APP_PATH not found" >&2
    exit 1
fi

echo "==> Built: $APP_PATH"

if [ "$LAUNCH" = true ]; then
    echo "==> Relaunching ${APP_NAME}..."
    # Quit any running instance so the new build takes over (menu bar app).
    osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    sleep 1
    open "$APP_PATH"
    echo "==> Launched. Look for the ClarityAI icon in the menu bar."
fi
