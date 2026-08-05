import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Result of uploading a material file to Storage.
class MaterialUpload {
  const MaterialUpload({
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  final String fileUrl;
  final String fileName;
  final String fileType;
}

/// Picks and uploads a material file to `materials/{ownerId}/...`.
/// Mirrors [ProfilePhotoService] but accepts documents (PDF/Office/images).
class MaterialsStorageService {
  MaterialsStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const _maxBytes = 25 * 1024 * 1024;

  static const _allowedExtensions = [
    'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx',
    'txt', 'csv', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp3', 'mp4',
  ];

  Future<MaterialUpload> pickAndUpload(String ownerId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw MaterialUploadCancelledException();
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not read the selected file. Try another one.');
    }
    if (bytes.length > _maxBytes) {
      throw StateError('File must be smaller than 25 MB.');
    }

    final extension = (file.extension ?? '').toLowerCase().trim();
    if (extension.isEmpty || !_allowedExtensions.contains(extension)) {
      throw StateError('Unsupported file type.');
    }

    final contentType = _contentTypeFor(extension);
    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'materials/$ownerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);

    await ref.putData(bytes, SettableMetadata(contentType: contentType));

    return MaterialUpload(
      fileUrl: await ref.getDownloadURL(),
      fileName: file.name,
      fileType: extension,
    );
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp3' => 'audio/mpeg',
      'mp4' => 'video/mp4',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}

class MaterialUploadCancelledException implements Exception {
  @override
  String toString() => 'File selection cancelled.';
}
