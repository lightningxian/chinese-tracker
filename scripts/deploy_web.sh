#!/usr/bin/env bash
# Build the web app and deploy it to Firebase Hosting, including the Android
# APK at /downloads/easy-study.apk.
#
# Hosting deploys are full snapshots, so the APK has to be copied into
# build/web on EVERY deploy or the download link breaks. Always deploy with
# this script, not with a bare `firebase deploy --only hosting`.
#
# Usage:
#   scripts/deploy_web.sh --web-only # web only, no APK (works on the free plan)
#   scripts/deploy_web.sh            # web + APK, reusing the last APK build
#   scripts/deploy_web.sh --apk      # web + APK, rebuilding the APK (~6 min)
#
# NOTE: Firebase Hosting on the free (Spark) plan refuses executable files,
# so the APK can only be published once project billing (Blaze) is enabled.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
CONTENT_OWNER_ID="2orTXFeyAhSlxfTgIlcYgs6ZuCG2"
MIDTRANS_CLIENT_KEY="Mid-client-kQ_Bo0DQepeH8IhU"   # sandbox
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_URL="https://chinese-tracker.web.app/downloads/easy-study.apk"

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21}"
export PATH="$JAVA_HOME/bin:$PATH"

APK_DEFINE=()
if [[ "$MODE" != "--web-only" ]]; then
  if [[ "$MODE" == "--apk" || ! -f "$APK_SRC" ]]; then
    echo "▶ Building Android APK…"
    flutter build apk --release \
      --dart-define=CONTENT_OWNER_ID="$CONTENT_OWNER_ID" \
      --dart-define=MIDTRANS_CLIENT_KEY="$MIDTRANS_CLIENT_KEY"
  fi
  APK_DEFINE=(--dart-define=ANDROID_APK_URL="$APK_URL")
fi

echo "▶ Building web…"
rm -rf build/web
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID="$CONTENT_OWNER_ID" \
  --dart-define=MIDTRANS_CLIENT_KEY="$MIDTRANS_CLIENT_KEY" \
  "${APK_DEFINE[@]}"

if [[ "$MODE" != "--web-only" ]]; then
  mkdir -p build/web/downloads
  cp "$APK_SRC" build/web/downloads/easy-study.apk
  echo "▶ APK: $(du -h build/web/downloads/easy-study.apk | cut -f1) → $APK_URL"
fi

echo "▶ Deploying hosting…"
firebase deploy --only hosting --project chinese-tracker
