import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationKind {
  registration('registration'),
  session('session'),
  grading('grading'),

  /// "Due today" reminders written by the `dailyReminders` function.
  reminder('reminder');

  const NotificationKind(this.value);

  final String value;

  static NotificationKind fromValue(String? value) {
    return NotificationKind.values.firstWhere(
      (k) => k.value == value,
      orElse: () => NotificationKind.session,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.forRole,
    this.userId,
    this.read = false,
    this.createdAt,
    this.targetRoute,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// `admin`, `teacher`, `student`, or `all`
  final String forRole;
  final String? userId;
  final bool read;
  final DateTime? createdAt;
  final String? targetRoute;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      kind: NotificationKind.fromValue(data['kind'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      forRole: data['forRole'] as String? ?? 'all',
      userId: data['userId'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      targetRoute: data['targetRoute'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.value,
        'title': title,
        'body': body,
        'forRole': forRole,
        // Broadcasts store '' (not a missing field) so clients can query them.
        'userId': userId ?? '',
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
        if (targetRoute != null && targetRoute!.isNotEmpty)
          'targetRoute': targetRoute,
      };
}
