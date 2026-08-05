import 'package:cloud_firestore/cloud_firestore.dart';

/// A shared teaching material (`materials`) — a file/link beyond structured
/// lessons. Named `MaterialItem` to avoid clashing with Flutter's `Material`.
class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.status,
    this.level,
    this.skill,
    this.tags = const [],
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;

  /// "draft" | "published"
  final String status;
  final String? level;
  final String? skill;
  final List<String> tags;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isPublished => status == 'published';

  factory MaterialItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MaterialItem(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      level: data['level'] as String?,
      skill: data['skill'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? const []),
      fileUrl: data['fileUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileType: data['fileType'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title.trim(),
        'status': status,
        if (level != null && level!.isNotEmpty) 'level': level,
        if (skill != null && skill!.isNotEmpty) 'skill': skill,
        'tags': tags,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
      };
}
