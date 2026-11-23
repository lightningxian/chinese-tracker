#!/usr/bin/env bash
# Builds the iOS App Store archive (owner 2026-11-24, Q9 option B). Mac only:
# needs the full Xcode, CocoaPods, and the owner's Apple developer team set
# on the Runner target (Xcode → Signing & Capabilities). See
# docs/IOS_SPEC.md for the whole path to TestFlight and the App Store.
#
#   scripts/build_ios.sh            # build/ios/ipa/*.ipa for App Store Connect
#   BUILD_NUMBER=3 scripts/build_ios.sh
#
# The build number must go up with every upload to App Store Connect; it
# defaults to the number of commits, which only grows.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname)" != "Darwin" ]]; then
  echo "✖ iOS builds need a Mac with Xcode." >&2
  exit 1
fi

# The same public values the web and Android builds use (scripts/deploy_web.sh).
CONTENT_OWNER_ID="2orTXFeyAhSlxfTgIlcYgs6ZuCG2"
MIDTRANS_CLIENT_KEY="Mid-client-kQ_Bo0DQepeH8IhU"   # sandbox until MT-05 passes
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD)}"

flutter pub get
flutter build ipa --release \
  --build-number="$BUILD_NUMBER" \
  --dart-define=CONTENT_OWNER_ID="$CONTENT_OWNER_ID" \
  --dart-define=MIDTRANS_CLIENT_KEY="$MIDTRANS_CLIENT_KEY"

echo "✔ Archive: build/ios/archive/Runner.xcarchive"
echo "  Upload: open it in Xcode → Window → Organizer → Distribute App → App Store Connect,"
echo "  or drag build/ios/ipa/*.ipa into Apple's Transporter app."
