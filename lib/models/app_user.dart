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
    this.linkedParentUid,
    this.linkedParentName,
    this.createdAt,
    this.active = true,
    this.status,
    this.placementChoice,
    this.placementTarget,
    this.placementResultCode,
    this.rejectReason,
    this.levels = const [],
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

  /// Parent account linked to this student (written by the `linkChild`
  /// function). Only used to tell the student who handles payments; the
  /// parent's access comes from the parent's own [studentIds].
  final String? linkedParentUid;
  final String? linkedParentName;

  bool get hasLinkedParent => (linkedParentUid ?? '').isNotEmpty;
  final DateTime? createdAt;
  final bool active;

  /// Build 3: `pending` until an admin approves a self-registered student,
  /// `rejected` when refused, `active` after approval. Accounts made before
  /// Build 3 have none and count as approved.
  final String? status;

  /// `hsk1` ("Mulai dari HSK 1") or `test` (wants a placement test).
  final String? placementChoice;

  /// The level a student who chose the placement test aims at (`HSK 4`).
  final String? placementTarget;

  /// Result code of a public placement test typed at registration.
  final String? placementResultCode;
  final String? rejectReason;

  /// A teacher's levels (`HSK 1`..`HSK 6`), ticked by the admin.
  final List<String> levels;

  bool get isPending => status == statusPending;
  bool get isRejected => status == statusRejected;

  /// Pending or rejected: the student waits on the waiting page.
  bool get awaitsApproval => isStudent && (isPending || isRejected);

  static const statusPending = 'pending';
  static const statusRejected = 'rejected';
  static const statusActive = 'active';
  static const choiceHsk1 = 'hsk1';
  static const choiceTest = 'test';

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

  /// Latin name (PLAN.md §3): [nameIndonesian], falling back to [name].
  String get latinName => displayNameIndonesian;

  /// What admins and teachers see: `Chinese name (Latin name)`, or the
  /// Latin name alone when there is no Chinese name.
  String get staffLabel => staffLabelOf(displayNameChinese, latinName);

  /// What another student sees: the Chinese name, or the first word of the
  /// Latin name when there is none.
  String get peerLabel => peerLabelOf(displayNameChinese, latinName);

  /// [staffLabel] for names stored outside a profile (attempts, results).
  static String staffLabelOf(String? chinese, String latin) {
    final c = chinese?.trim() ?? '';
    final l = latin.trim();
    if (c.isEmpty) return l;
    if (l.isEmpty) return c;
    return '$c ($l)';
  }

  /// [peerLabel] for names stored outside a profile.
  static String peerLabelOf(String? chinese, String latin) {
    final c = chinese?.trim() ?? '';
    if (c.isNotEmpty) return c;
    final words = latin.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.first;
  }

  /// True when [query] is empty or found (case-insensitive) in the Chinese
  /// name, the Latin name, [name] or, with [includeEmail], the email.
  bool matchesSearch(String query, {bool includeEmail = true}) =>
      nameMatches(
        query,
        chinese: nameChinese,
        latin: latinName,
        others: [name, if (includeEmail) email],
      );

  /// Search helper for names stored outside a profile: matches the Chinese
  /// name, the Latin name and any [others] (email, codes).
  static bool nameMatches(
    String query, {
    String? chinese,
    String latin = '',
    Iterable<String?> others = const [],
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    for (final value in [chinese, latin, ...others]) {
      if (value != null && value.toLowerCase().contains(q)) return true;
    }
    return false;
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
      linkedParentUid: data['linkedParentUid'] as String?,
      linkedParentName: data['linkedParentName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      active: data['active'] as bool? ?? true,
      status: data['status'] as String?,
      placementChoice: data['placementChoice'] as String?,
      placementTarget: data['placementTarget'] as String?,
      placementResultCode: data['placementResultCode'] as String?,
      rejectReason: data['rejectReason'] as String?,
      levels: (data['levels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
        if (linkedParentUid != null && linkedParentUid!.isNotEmpty)
          'linkedParentUid': linkedParentUid,
        if (linkedParentName != null && linkedParentName!.isNotEmpty)
          'linkedParentName': linkedParentName,
        'active': active,
        if (status != null) 'status': status,
        if (placementChoice != null) 'placementChoice': placementChoice,
        if (placementTarget != null) 'placementTarget': placementTarget,
        if (placementResultCode != null)
          'placementResultCode': placementResultCode,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
