#!/usr/bin/env bash
# Build the web app against the local Firebase emulators and serve it on
# http://localhost:5181 from build/web-emulator.
#
# Never serve build/web for emulator work: scripts/deploy_web.sh rebuilds
# build/web with the LIVE config, and a dev server still pointing there would
# silently switch to the live database (this happened on 2026-11-09).
#
# Prerequisites (other terminals):
#   firebase emulators:start --only auth,firestore,storage --project chinese-tracker
#   python3 -I scripts/seed_emulator.py
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=build/web-emulator
PORT="${PORT:-5181}"

echo "▶ Building emulator web bundle → $OUT"
rm -rf "$OUT"
flutter build web --release --dart-define=USE_EMULATORS=true --output "$OUT"
mkdir -p "$OUT/test_uploads"

echo "▶ Serving $OUT on http://localhost:$PORT (SPA fallback on)"
npx --yes serve@14 -s "$OUT" -l "$PORT"
