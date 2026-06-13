#!/usr/bin/env bash
#
# Reset ClarityAI's Accessibility permission so macOS will prompt again.
#
# Use this when a rebuild stops working because macOS still trusts an old
# ad-hoc signature or build path.
#
# Usage:
#   ./reset-accessibility.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ID="com.clarityai.app"
APP_NAME="ClarityAI"
APP_PATH="$SCRIPT_DIR/build/Build/Products/Debug/${APP_NAME}.app"

echo "==> Quitting ${APP_NAME} if running..."
osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 1

echo "==> Resetting Accessibility permission for ${BUNDLE_ID}..."
if tccutil reset Accessibility "$BUNDLE_ID"; then
    echo "    TCC entry cleared."
else
    echo "    tccutil failed (continuing). You can still remove the app manually in System Settings." >&2
fi

echo "==> Opening Accessibility settings..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "Next steps:"
echo "  1. In Accessibility, remove any stale \"${APP_NAME}\" entries if they remain."
echo "  2. Rebuild and launch:"
echo "       ./run.sh"
if [ -d "$APP_PATH" ]; then
    echo "  3. When prompted, allow access. Or drag this app into the list:"
    echo "       ${APP_PATH}"
else
    echo "  3. After ./run.sh, drag the built app into the Accessibility list:"
    echo "       build/Build/Products/Debug/${APP_NAME}.app"
fi
echo ""
echo "You only need to do this when permission stops working after a rebuild."
