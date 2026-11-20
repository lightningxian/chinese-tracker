/// Build 8: query parameters read once at start-up, before the router's
/// redirects drop them. `?tab=N` opens a shell tab directly (the screenshot
/// runner, `tool/screenshots/run.mjs`).
abstract final class LaunchParams {
  static int? _tab;

  static void capture(Uri uri) {
    _tab = int.tryParse(uri.queryParameters['tab'] ?? '');
  }

  /// The requested tab (once), clamped to [max]; 0 when none was asked.
  static int takeTab(int max) {
    final t = _tab;
    _tab = null;
    return t == null ? 0 : t.clamp(0, max);
  }
}
