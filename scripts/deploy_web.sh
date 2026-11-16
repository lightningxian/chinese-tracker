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
#   add --no-keys (any position) to deploy on purpose without deploy.env keys
#
# NOTE: Firebase Hosting on the free (Spark) plan refuses executable files,
# so the APK can only be published once project billing (Blaze) is enabled.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE=""
NO_KEYS=0
for arg in "$@"; do
  case "$arg" in
    --no-keys) NO_KEYS=1 ;;
    *) MODE="$arg" ;;
  esac
done
CONTENT_OWNER_ID="2orTXFeyAhSlxfTgIlcYgs6ZuCG2"
MIDTRANS_CLIENT_KEY="Mid-client-kQ_Bo0DQepeH8IhU"   # sandbox
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_URL="https://chinese-tracker.web.app/downloads/easy-study.apk"

# App Check site key (reCAPTCHA Enterprise) and Web Push (VAPID) key:
# created by the owner in the consoles. Both are public (they ship in the
# page), so their defaults live here, next to MIDTRANS_CLIENT_KEY, and every
# machine deploys with them (owner decision 2026-11-16). deploy.env
# (git-ignored via *.env) or exported variables still override them.
DEFAULT_APP_CHECK_SITE_KEY=""   # owner: paste the reCAPTCHA Enterprise key
DEFAULT_FCM_VAPID_KEY=""        # owner: paste the Web Push certificate key
if [[ -f deploy.env ]]; then
  # shellcheck disable=SC1091
  source deploy.env
fi
APP_CHECK_SITE_KEY="${APP_CHECK_SITE_KEY:-$DEFAULT_APP_CHECK_SITE_KEY}"
FCM_VAPID_KEY="${FCM_VAPID_KEY:-$DEFAULT_FCM_VAPID_KEY}"
# A deploy without the keys switches the AI paper scan and push off for
# every user, so refuse unless the caller says so on purpose.
if [[ -z "${APP_CHECK_SITE_KEY:-}" && "$NO_KEYS" != 1 ]]; then
  echo "✖ APP_CHECK_SITE_KEY is empty (no default in this script, no deploy.env)." >&2
  echo "  Deploying now would switch Scan paper with AI and push off for everyone." >&2
  echo "  Set DEFAULT_APP_CHECK_SITE_KEY here, or re-run with --no-keys on purpose." >&2
  exit 1
fi
KEY_DEFINES=(
  --dart-define=APP_CHECK_SITE_KEY="${APP_CHECK_SITE_KEY:-}"
  --dart-define=FCM_VAPID_KEY="${FCM_VAPID_KEY:-}"
)

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21}"
export PATH="$JAVA_HOME/bin:$PATH"

APK_DEFINE=()
if [[ "$MODE" != "--web-only" ]]; then
  if [[ "$MODE" == "--apk" || ! -f "$APK_SRC" ]]; then
    echo "▶ Building Android APK…"
    flutter build apk --release \
      --dart-define=CONTENT_OWNER_ID="$CONTENT_OWNER_ID" \
      --dart-define=MIDTRANS_CLIENT_KEY="$MIDTRANS_CLIENT_KEY" \
      "${KEY_DEFINES[@]}"
  fi
  APK_DEFINE=(--dart-define=ANDROID_APK_URL="$APK_URL")
fi

echo "▶ Building web…"
rm -rf build/web
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID="$CONTENT_OWNER_ID" \
  --dart-define=MIDTRANS_CLIENT_KEY="$MIDTRANS_CLIENT_KEY" \
  "${KEY_DEFINES[@]}" \
  ${APK_DEFINE[@]+"${APK_DEFINE[@]}"}   # empty-array-safe on macOS bash 3.2

if [[ "$MODE" != "--web-only" ]]; then
  mkdir -p build/web/downloads
  cp "$APK_SRC" build/web/downloads/easy-study.apk
  echo "▶ APK: $(du -h build/web/downloads/easy-study.apk | cut -f1) → $APK_URL"
fi

echo "▶ Deploying hosting…"
firebase deploy --only hosting --project chinese-tracker
