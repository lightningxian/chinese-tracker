/// Compile-time switches passed with `--dart-define`.
abstract final class BuildFlags {
  /// `--dart-define=USE_EMULATORS=true`: talk to the local Firebase Emulator
  /// Suite instead of the live project (see `lib/main.dart` and
  /// `scripts/seed_emulator.py`). The app shows an EMULATOR banner when set.
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');

  /// `--dart-define=APP_CHECK_SITE_KEY=<reCAPTCHA v3 site key>`: turns on
  /// Firebase App Check (web: reCAPTCHA v3, Android: Play Integrity). The key
  /// is public (it ships in the page); it is read from the environment by
  /// `scripts/deploy_web.sh`. Empty: App Check stays off.
  static const appCheckSiteKey = String.fromEnvironment('APP_CHECK_SITE_KEY');

  /// `--dart-define=APP_CHECK_DEBUG=true`: web only. App Check uses the debug
  /// provider, which prints a debug token in the browser console; register
  /// that token in the Firebase console (App Check → Apps → ⋮ → Manage
  /// debug tokens) and local runs pass App Check too.
  static const appCheckDebug = bool.fromEnvironment('APP_CHECK_DEBUG');

  /// `--dart-define=FCM_VAPID_KEY=<Web Push certificate key pair>`: needed for
  /// web push tokens (Firebase console → Cloud Messaging → Web Push
  /// certificates). Empty: the "Push notifications" switch is hidden.
  static const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
}
