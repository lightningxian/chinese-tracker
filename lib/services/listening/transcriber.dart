import 'dart:typed_data';

import 'transcriber_stub.dart' if (dart.library.js_interop) 'transcriber_web.dart'
    as impl;

/// Owner 2026-11-24 (Q7): writes the listening script of a recording with
/// Whisper in the browser (`web/transcribe_whisper.js`, files from
/// `scripts/fetch_whisper.mjs`). Nothing leaves the computer.
abstract final class ListeningTranscriber {
  /// Whether the writer is on the page (web builds only).
  static bool get available => impl.transcriberAvailable;

  /// Writes the Mandarin text of [url] or [bytes] (one of them), one line per
  /// piece of up to 29 seconds. [onProgress] gets `loading` (first-time model
  /// download) or `writing` with a fraction from 0 to 1.
  static Future<String> transcribe({
    String? url,
    Uint8List? bytes,
    void Function(String stage, double fraction)? onProgress,
  }) =>
      impl.transcribe(url: url, bytes: bytes, onProgress: onProgress);
}
