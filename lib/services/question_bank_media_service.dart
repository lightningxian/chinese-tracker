import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

/// Uploads image/audio for question-bank items to
/// `question_bank_media/{ownerId}/…`.
class QuestionBankMediaService {
  QuestionBankMediaService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Pictures stay small; a paper's official recording can be long
  /// (Build 1B: up to 60 MB). The same limits are in `storage.rules`.
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxAudioBytes = 60 * 1024 * 1024;

  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  /// Owner 2026-11-24: an MP3 saved as `.mpeg` (some browsers and phones
  /// name downloads that way) is accepted too and stored as `audio/mpeg`.
  static const audioExtensions = [
    'mp3', 'mpeg', 'mpga', 'wav', 'm4a', 'aac', 'ogg', 'oga', 'opus', 'webm',
  ];
  static const _audioExtensions = audioExtensions;

  static int _maxFor(String contentType) =>
      contentType.startsWith('audio/') ? maxAudioBytes : maxImageBytes;

  Future<String> pickAndUploadImage(String ownerId) =>
      _pickAndUpload(ownerId, _imageExtensions, 'image');

  /// [onPicked] runs once the file is chosen (to show the progress);
  /// [onProgress] reports the upload, 0–1.
  Future<String> pickAndUploadAudio(
    String ownerId, {
    VoidCallback? onPicked,
    void Function(double fraction)? onProgress,
  }) =>
      _pickAndUpload(ownerId, _audioExtensions, 'audio',
          onPicked: onPicked, onProgress: onProgress);

  Future<String> _pickAndUpload(
    String ownerId,
    List<String> extensions,
    String kind, {
    VoidCallback? onPicked,
    void Function(double fraction)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw QuestionBankMediaCancelledException();
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not read the selected file.');
    }
    final extension = (file.extension ?? '').toLowerCase().trim();
    if (extension.isEmpty || !extensions.contains(extension)) {
      throw StateError('Unsupported file type.');
    }
    final contentType = _contentType(extension);
    _checkSize(bytes.length, contentType);
    onPicked?.call();

    return uploadBytes(
      ownerId,
      bytes,
      fileName: '${kind}_${file.name}',
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  static void _checkSize(int length, String contentType) {
    final max = _maxFor(contentType);
    if (length > max) {
      throw StateError(
          'File must be smaller than ${max ~/ (1024 * 1024)} MB.');
    }
  }

  /// Stores [bytes] under the owner's media folder and returns the download
  /// URL. Used for picked files and for pictures cropped out of a scanned
  /// paper by the AI import.
  Future<String> uploadBytes(
    String ownerId,
    Uint8List bytes, {
    required String fileName,
    required String contentType,
    void Function(double fraction)? onProgress,
  }) async {
    if (bytes.isEmpty) throw StateError('Could not read the file.');
    _checkSize(bytes.length, contentType);
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'question_bank_media/$ownerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    final sub = onProgress == null
        ? null
        : task.snapshotEvents.listen((s) {
            if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
          }, onError: (_) {});
    try {
      await task;
    } finally {
      await sub?.cancel();
    }
    onProgress?.call(1);
    return ref.getDownloadURL();
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      'mp3' || 'mpeg' || 'mpga' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' || 'oga' || 'opus' => 'audio/ogg',
      'webm' => 'audio/webm',
      _ => 'application/octet-stream',
    };
  }
}

class QuestionBankMediaCancelledException implements Exception {
  @override
  String toString() => 'File selection cancelled.';
}
