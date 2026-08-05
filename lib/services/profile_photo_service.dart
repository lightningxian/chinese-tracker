import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePhotoService {
  ProfilePhotoService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const _maxBytes = 5 * 1024 * 1024;

  /// Picks an image and uploads it to `profile_photos/{userId}/avatar.*`.
  /// Returns the download URL.
  Future<String> pickAndUpload(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw ProfilePhotoCancelledException();
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not read the selected image. Try another file.');
    }
    if (bytes.length > _maxBytes) {
      throw StateError('Photo must be smaller than 5 MB.');
    }

    final extension = _extensionFor(file.name, file.extension);
    final contentType = _contentTypeFor(extension);
    final ref = _storage.ref('profile_photos/$userId/avatar.$extension');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    return ref.getDownloadURL();
  }

  String _extensionFor(String fileName, String? pickerExtension) {
    final fromPicker = pickerExtension?.toLowerCase().trim();
    if (fromPicker != null && fromPicker.isNotEmpty) {
      return fromPicker == 'jpeg' ? 'jpg' : fromPicker;
    }
    final parts = fileName.split('.');
    if (parts.length > 1) {
      final ext = parts.last.toLowerCase();
      if (ext == 'jpeg') return 'jpg';
      if (ext.isNotEmpty) return ext;
    }
    return 'jpg';
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

class ProfilePhotoCancelledException implements Exception {
  @override
  String toString() => 'Photo selection cancelled.';
}
