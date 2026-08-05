import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/level_utils.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.teacherId,
    this.level,
    this.termSize,
    this.nameIndonesian,
    this.nameChinese,
    this.whatsapp,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
    this.phone,
    this.studentIds = const [],
    this.parentCode,
    this.createdAt,
    this.active = true,
  });

  final String uid;
  final String email;
  /// Primary display name (usually Indonesian name).
  final String name;
  final String role;
  /// Links this student to lesson/session content in Firestore.
  final String? teacherId;
  final String? level;
  final int? termSize;
  final String? nameIndonesian;
  final String? nameChinese;
  final String? whatsapp;
  final String? photoUrl;
  final String? parentName;
  final String? parentPhone;
  /// Legacy phone field — prefer [whatsapp].
  final String? phone;
  /// Children linked to a [AppConstants.roleParent] account.
  final List<String> studentIds;
  /// Stable 6-char code a parent enters to link to this student.
  final String? parentCode;
  final DateTime? createdAt;
  final bool active;

  bool get isTeacher => role == AppConstants.roleTeacher;
  bool get isStudent => role == AppConstants.roleStudent;
  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isParent => role == AppConstants.roleParent;
  bool get isStaff => isTeacher || isAdmin;

  /// Indonesian name with fallback to [name].
  String get displayNameIndonesian {
    final value = nameIndonesian?.trim();
    if (value != null && value.isNotEmpty) return value;
    return name;
  }

  /// Chinese name when set.
  String? get displayNameChinese {
    final value = nameChinese?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// WhatsApp number with fallback to legacy [phone].
  String? get displayWhatsapp {
    final value = whatsapp?.trim();
    if (value != null && value.isNotEmpty) return value;
    final legacy = phone?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return null;
  }

  /// UI label — Admin / Guru / Murid / Orang Tua
  String get roleDisplayLabel {
    if (isAdmin) return 'Admin';
    if (isTeacher) return 'Guru';
    if (isParent) return 'Orang Tua';
    return 'Murid';
  }

  int get lessonsPerTerm => termSize ?? AppConstants.defaultTermSize;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? AppConstants.roleStudent,
      teacherId: data['teacherId'] as String?,
      level: LevelUtils.normalizeHskLevel(data['level'] as String?),
      termSize: data['termSize'] as int?,
      nameIndonesian: data['nameIndonesian'] as String?,
      nameChinese: data['nameChinese'] as String?,
      whatsapp: data['whatsapp'] as String?,
      photoUrl: data['photoUrl'] as String?,
      parentName: data['parentName'] as String?,
      parentPhone: data['parentPhone'] as String?,
      phone: data['phone'] as String?,
      studentIds: (data['studentIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      parentCode: data['parentCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role,
        if (teacherId != null && teacherId!.isNotEmpty) 'teacherId': teacherId,
        if (level != null) 'level': level,
        if (termSize != null) 'termSize': termSize,
        if (nameIndonesian != null && nameIndonesian!.isNotEmpty)
          'nameIndonesian': nameIndonesian,
        if (nameChinese != null && nameChinese!.isNotEmpty)
          'nameChinese': nameChinese,
        if (whatsapp != null && whatsapp!.isNotEmpty) 'whatsapp': whatsapp,
        if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
        if (parentName != null && parentName!.isNotEmpty)
          'parentName': parentName,
        if (parentPhone != null && parentPhone!.isNotEmpty)
          'parentPhone': parentPhone,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (studentIds.isNotEmpty) 'studentIds': studentIds,
        if (parentCode != null && parentCode!.isNotEmpty)
          'parentCode': parentCode,
        'active': active,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
