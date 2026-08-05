# Cursor build prompt — Android installer + iOS PWA + landing download

Copy everything in the block below into Cursor (Composer / agent) and run it on
the Mac that has Flutter, Android SDK, and Xcode installed. It assumes the code
changes described in "Context already done" are already in the repo.

---

## Context already done (do not redo — just verify)

The following was already changed in this repo:

- `lib/firebase_options.dart` — real Android + iOS Firebase values filled in
  (were placeholders); iOS bundle id set to `com.chinesetracker.chineseTracker`.
- `android/app/build.gradle.kts` — `minSdk = maxOf(flutter.minSdkVersion, 23)`.
- `android/app/src/main/AndroidManifest.xml` — added `INTERNET` permission,
  app label set to `Easy Study`, added an `https` VIEW query for `url_launcher`.
- `web/index.html` — iOS/PWA meta tags fixed (title, `apple-mobile-web-app-capable`).
- `lib/features/landing/landing_screen.dart` — added a web-only "Get the app"
  section with an Android download button and an iOS "Add to Home Screen" guide.
- `lib/core/constants/app_constants.dart` — added `androidApkUrl` (from
  `--dart-define=ANDROID_APK_URL=...`) and `hasAndroidApk`.
- `pubspec.yaml` — added `url_launcher: ^6.3.1` (and previously `cloud_functions`).

## Your tasks

Goal: ship an **installable Android APK** (sideload — NOT Google Play), keep
**iOS as an installable PWA** (Add to Home Screen — NOT the App Store, no paid
Apple account), and wire the landing page "Download for Android" button to the
hosted APK.

### 0. Sanity

1. `flutter pub get`
2. `flutter analyze` — fix any errors introduced by the changes above.
3. Confirm the app still runs on web: `flutter run -d chrome`.

### 1. Android release APK (sideloadable)

1. Create an upload keystore if one doesn't exist:
   ```bash
   keytool -genkey -v -keystore ~/easystudy-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias easystudy
   ```
2. Add `android/key.properties` (git-ignored) with `storeFile`, `storePassword`,
   `keyAlias`, `keyPassword`, and wire a real `signingConfigs.release` in
   `android/app/build.gradle.kts` (replace the debug-signing TODO in the
   `release` build type).
3. Build a **universal** APK (not an app bundle — bundles are for Play only):
   ```bash
   flutter build apk --release \
     --dart-define=CONTENT_OWNER_ID=<the owner uid> \
     --dart-define=ANDROID_APK_URL=<final hosted APK url>
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`.
4. Rename to something friendly, e.g. `easy-study.apk`.

> Note for testers: Android will warn about installing from an unknown source;
> they must allow it for their browser/Files app. Include that in instructions.

### 2. Host the APK and set the download URL

Pick a host (the app just needs a public direct-download URL):

- **Firebase Hosting** (recommended — project already uses Firebase): copy the
  APK into a hosting folder (e.g. `web/downloads/easy-study.apk` or a dedicated
  hosting target), `firebase deploy --only hosting`, final URL like
  `https://chinese-tracker.web.app/downloads/easy-study.apk`.
- Or **GitHub Releases**: attach the APK to a release; use the asset URL.

Then set that URL as `ANDROID_APK_URL` (rebuild the web app so the landing
button points at it):

```bash
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID=<the owner uid> \
  --dart-define=ANDROID_APK_URL=<final hosted APK url>
firebase deploy --only hosting
```

Make sure the host serves the APK with
`Content-Type: application/vnd.android.package-archive` (Firebase Hosting does by
extension; if not, add a header rule in `firebase.json`).

### 3. iOS — PWA (no App Store, no paid account)

No `.ipa` build. iOS users install the deployed web app via Safari:

1. Confirm the web build is deployed (step 2) and loads over **https**.
2. On an iPhone, open the site in **Safari** → Share → **Add to Home Screen** →
   the icon should say **Easy Study** and launch full-screen (standalone).
3. Verify `web/manifest.json` (`display: standalone`, icons) and the
   `apple-touch-icon` / `apple-mobile-web-app-*` tags in `web/index.html`.
4. Sanity-check that Firebase Auth + Firestore work inside the standalone PWA on
   iOS Safari.

### 4. End-user install instructions

Produce a short `docs/INSTALL.md` for testers covering: Android (download APK →
allow unknown source → install) and iPhone (open in Safari → Add to Home Screen).

## Do NOT

- Do not publish to Google Play or the App Store.
- Do not build an `.ipa` or require an Apple Developer account.
- Do not commit the keystore or `key.properties`.

## Acceptance

- `flutter analyze` is clean.
- `app-release.apk` installs and runs on a real Android phone; login + a
  Firestore read work.
- The deployed web app installs to an iPhone home screen and runs standalone.
- The landing page "Download for Android" button downloads the APK; "Install on
  iPhone" shows the Add-to-Home-Screen steps.
