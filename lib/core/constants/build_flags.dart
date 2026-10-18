/// Compile-time switches passed with `--dart-define`.
abstract final class BuildFlags {
  /// `--dart-define=USE_EMULATORS=true`: talk to the local Firebase Emulator
  /// Suite instead of the live project (see `lib/main.dart` and
  /// `scripts/seed_emulator.py`). The app shows an EMULATOR banner when set.
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');
}
