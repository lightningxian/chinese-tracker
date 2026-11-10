import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads image/audio for question-bank items to
/// `question_bank_media/{ownerId}/…`.
class QuestionBankMediaService {
  QuestionBankMediaService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const _maxBytes = 10 * 1024 * 1024;

  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const _audioExtensions = ['mp3', 'wav', 'm4a', 'ogg'];

  Future<String> pickAndUploadImage(String ownerId) =>
      _pickAndUpload(ownerId, _imageExtensions, 'image');

  Future<String> pickAndUploadAudio(String ownerId) =>
      _pickAndUpload(ownerId, _audioExtensions, 'audio');

  Future<String> _pickAndUpload(
    String ownerId,
    List<String> extensions,
    String kind,
  ) async {
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
    if (bytes.length > _maxBytes) {
      throw StateError('File must be smaller than 10 MB.');
    }

    final extension = (file.extension ?? '').toLowerCase().trim();
    if (extension.isEmpty || !extensions.contains(extension)) {
      throw StateError('Unsupported file type.');
    }

    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'question_bank_media/$ownerId/${DateTime.now().millisecondsSinceEpoch}_${kind}_$safeName';
    final ref = _storage.ref(path);

    await ref.putData(
        bytes, SettableMetadata(contentType: _contentType(extension)));

    return ref.getDownloadURL();
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      _ => 'application/octet-stream',
    };
  }
}

class QuestionBankMediaCancelledException implements Exception {
  @override
  String toString() => 'File selection cancelled.';
}
