import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/level_utils.dart';
import '../models/app_user.dart';
import '../services/child_link_service.dart';
import '../services/teacher_link_code_service.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get firebaseUser => _auth.currentUser;
  AppUser? _appUser;
  AppUser? get appUser => _appUser;
  bool get isLoggedIn => firebaseUser != null && _appUser != null;

  /// True until the first [init] profile load finishes.
  /// Prevents cold-start redirects to `/complete-profile` while `appUser` is still null.
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  /// True while [signIn] already has a Firebase user but is still fetching
  /// the profile. The router stays put during this window instead of
  /// bouncing a valid account to `/complete-profile`.
  bool _profileLoading = false;
  bool get isProfileLoading => _profileLoading;

  Future<void> init() async {
    try {
      final user = firebaseUser;
      if (user != null) {
        await _loadProfile(user.uid);
        if (_appUser?.active == false) {
          // Deactivated while signed in: drop the session on next launch.
          await _auth.signOut();
          _appUser = null;
        }
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final user = firebaseUser;
    if (user == null) return;
    await _loadProfile(user.uid);
    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    final ref = _firestore.collection(AppConstants.usersCollection).doc(uid);
    var doc = await ref.get();
    if (!doc.exists && doc.metadata.isFromCache) {
      // Right after a cold start the SDK can answer from an empty cache
      // while the connection is still coming up; ask the server before
      // treating the profile as missing.
      doc = await ref.get(const GetOptions(source: Source.server));
    }
    if (!doc.exists) {
      _appUser = null;
      return;
    }

    final data = doc.data() ?? {};
    final rawLevel = data['level'] as String?;
    final normalizedLevel = LevelUtils.normalizeHskLevel(rawLevel);
    if (rawLevel != null &&
        normalizedLevel != null &&
        rawLevel != normalizedLevel) {
      await doc.reference.update({'level': normalizedLevel});
      final refreshed = await doc.reference.get();
      _appUser = AppUser.fromFirestore(refreshed);
      return;
    }

    _appUser = AppUser.fromFirestore(doc);
  }

  Future<AppUser> register({
    required String nameIndonesian,
    required String email,
    required String password,
    required String level,
    required int termSize,
    required String linkCode,
    String? nameChinese,
    String? whatsapp,
    String? parentName,
    String? parentPhone,
  }) async {
    // Validate the link code BEFORE creating the auth account. Otherwise a bad
    // code leaves an orphaned Firebase Auth user with no Firestore profile,
    // and the email can no longer be re-registered.
    final teacherId = await TeacherLinkCodeService.resolveTeacherId(
      firestore: _firestore,
      rawCode: linkCode,
    );

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    final indonesian = nameIndonesian.trim();

    final profile = AppUser(
      uid: uid,
      email: email.trim(),
      name: indonesian,
      nameIndonesian: indonesian,
      nameChinese: _optional(nameChinese),
      whatsapp: _optional(whatsapp),
      parentName: _optional(parentName),
      parentPhone: _optional(parentPhone),
      role: AppConstants.roleStudent,
      teacherId: teacherId,
      level: level,
      termSize: termSize,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(profile.toMap());

    _appUser = profile;
    notifyListeners();
    return profile;
  }

  /// Registers a parent account, then links it to a child via that child's
  /// access code. The parent doc is created with no children; the linkChild
  /// Cloud Function performs the authoritative link server-side (clients cannot
  /// write studentIds/teacherIds).
  Future<AppUser> registerParent({
    required String nameIndonesian,
    required String email,
    required String password,
    required String childCode,
    String? nameChinese,
    String? whatsapp,
  }) async {
    // Validate the code first (fail fast, before creating an auth account).
    await ChildLinkService.resolveChild(rawCode: childCode);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    final indonesian = nameIndonesian.trim();

    // Create the parent profile with NO linked children — rules forbid clients
    // from writing studentIds/teacherIds. The linkChild function does the
    // authoritative link server-side after the account exists.
    final data = <String, dynamic>{
      'email': email.trim(),
      'name': indonesian,
      'nameIndonesian': indonesian,
      if (_optional(nameChinese) != null) 'nameChinese': _optional(nameChinese),
      if (_optional(whatsapp) != null) 'whatsapp': _optional(whatsapp),
      'role': AppConstants.roleParent,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(data);

    // Authoritative server-side link (writes studentIds/teacherIds via admin SDK).
    await ChildLinkService.linkChild(rawCode: childCode);

    await _loadProfile(uid);
    notifyListeners();
    return _appUser!;
  }

  /// Creates a Firebase Auth account without signing out the current admin.
  Future<AppUser> createUserByAdmin({
    required String nameIndonesian,
    required String email,
    required String password,
    required String role,
    String? nameChinese,
    String? whatsapp,
    String? parentName,
    String? parentPhone,
    String? level,
    int? termSize,
    List<String> studentIds = const [],
  }) async {
    if (_appUser?.isAdmin != true) {
      throw StateError('Only admins can create users from the admin panel.');
    }

    // For parent accounts, derive the linked teachers up front (needed so the
    // parent can read their children's class sessions).
    final isParentRole = role == AppConstants.roleParent;
    final teacherIds = isParentRole
        ? await _teacherIdsForStudents(studentIds)
        : const <String>[];

    final secondaryApp = await Firebase.initializeApp(
      name: 'AdminCreateUser_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      final ownerId = AppConstants.contentOwnerId;
      final isStudent = role == AppConstants.roleStudent;
      final indonesian = nameIndonesian.trim();
      final profile = AppUser(
        uid: uid,
        email: email.trim(),
        name: indonesian,
        nameIndonesian: indonesian,
        nameChinese: _optional(nameChinese),
        whatsapp: _optional(whatsapp),
        parentName: isStudent ? _optional(parentName) : null,
        parentPhone: isStudent ? _optional(parentPhone) : null,
        role: role,
        teacherId: isStudent && ownerId.isNotEmpty ? ownerId : null,
        level: isStudent ? level : null,
        termSize: isStudent ? termSize : null,
        studentIds: isParentRole ? studentIds : const [],
        createdAt: DateTime.now(),
      );

      final data = profile.toMap();
      if (isParentRole && teacherIds.isNotEmpty) {
        data['teacherIds'] = teacherIds;
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(data);

      return profile;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<List<String>> _teacherIdsForStudents(List<String> studentIds) async {
    final teacherIds = <String>{};
    for (final id in studentIds) {
      if (id.isEmpty) continue;
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(id)
          .get();
      final tid = doc.data()?['teacherId'] as String?;
      if (tid != null && tid.isNotEmpty) teacherIds.add(tid);
    }
    return teacherIds.toList();
  }

  /// Sends Firebase's password-reset email. Firebase does not reveal whether
  /// the address has an account, so callers should show a neutral message.
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _profileLoading = true;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadProfile(credential.user!.uid);
    } finally {
      _profileLoading = false;
    }
    if (_appUser?.active == false) {
      await _auth.signOut();
      _appUser = null;
      notifyListeners();
      throw FirebaseAuthException(
        code: 'user-disabled',
        message: 'This account has been deactivated. Please contact the centre.',
      );
    }
    notifyListeners();
    if (_appUser == null) {
      throw FirebaseAuthException(
        code: 'profile-missing',
        message:
            'Your account exists, but profile data is missing. Please complete your profile.',
      );
    }
    return _appUser!;
  }

  Future<AppUser> completeProfile({
    required String nameIndonesian,
    required String level,
    required int termSize,
    required String linkCode,
    String? nameChinese,
    String? whatsapp,
    String? parentName,
    String? parentPhone,
  }) async {
    final user = firebaseUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please sign in again.',
      );
    }

    final teacherId = await TeacherLinkCodeService.resolveTeacherId(
      firestore: _firestore,
      rawCode: linkCode,
    );
    final indonesian = nameIndonesian.trim();

    final profile = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: indonesian,
      nameIndonesian: indonesian,
      nameChinese: _optional(nameChinese),
      whatsapp: _optional(whatsapp),
      parentName: _optional(parentName),
      parentPhone: _optional(parentPhone),
      role: AppConstants.roleStudent,
      teacherId: teacherId,
      level: level,
      termSize: termSize,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(profile.toMap());

    _appUser = profile;
    notifyListeners();
    return profile;
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _appUser = null;
    notifyListeners();
  }
}
