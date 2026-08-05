import 'package:cloud_firestore/cloud_firestore.dart';

/// How a class is delivered.
enum SessionMode {
  offline('offline', 'In-person'),
  online('online', 'Online'),
  hybrid('hybrid', 'Hybrid');

  const SessionMode(this.value, this.label);

  final String value;
  final String label;

  static SessionMode? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final m in SessionMode.values) {
      if (m.value == value) return m;
    }
    return null;
  }
}

/// Registration lifecycle for a class session.
enum RegistrationState {
  draft('draft', 'Draft'),
  open('open', 'Open for registration'),
  active('active', 'Active'),
  closed('closed', 'Closed');

  const RegistrationState(this.value, this.label);

  final String value;
  final String label;

  static RegistrationState? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in RegistrationState.values) {
      if (s.value == value) return s;
    }
    return null;
  }
}

class ClassSession {
  const ClassSession({
    required this.id,
    required this.teacherId,
    required this.sessionDate,
    required this.sessionTitle,
    required this.startMinutes,
    required this.endMinutes,
    required this.capacity,
    required this.isOpen,
    this.isConcluded = false,
    this.mode,
    this.room,
    this.registrationState,
    this.concludedAt,
    this.createdAt,
  });

  final String id;
  final String teacherId;
  final String sessionDate;
  final String sessionTitle;
  final int startMinutes;
  final int endMinutes;
  final int capacity;
  final bool isOpen;
  /// When true, class has ended and joined students were charged a session.
  final bool isConcluded;

  /// Optional class metadata (all nullable; older sessions stay valid).
  final SessionMode? mode;
  final String? room;
  final RegistrationState? registrationState;

  final DateTime? concludedAt;
  final DateTime? createdAt;

  String get timeRangeLabel => _formatTimeRange(startMinutes, endMinutes);

  /// True when students should be able to see/join this class for registration.
  bool get isOpenForRegistration => registrationState == RegistrationState.open;

  factory ClassSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassSession(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      sessionDate: data['sessionDate'] as String? ?? '',
      sessionTitle: data['sessionTitle'] as String? ?? '',
      startMinutes: data['startMinutes'] as int? ?? 0,
      endMinutes: data['endMinutes'] as int? ?? 0,
      capacity: data['capacity'] as int? ?? 20,
      isOpen: data['isOpen'] as bool? ?? true,
      isConcluded: data['isConcluded'] as bool? ?? false,
      mode: SessionMode.fromValue(data['mode'] as String?),
      room: data['room'] as String?,
      registrationState:
          RegistrationState.fromValue(data['registrationState'] as String?),
      concludedAt: (data['concludedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'teacherId': teacherId,
        'sessionDate': sessionDate,
        'sessionTitle': sessionTitle,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'capacity': capacity,
        'isOpen': isOpen,
        'isConcluded': isConcluded,
        if (mode != null) 'mode': mode!.value,
        if (room != null && room!.isNotEmpty) 'room': room,
        if (registrationState != null)
          'registrationState': registrationState!.value,
        if (concludedAt != null) 'concludedAt': Timestamp.fromDate(concludedAt!),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  static String _formatTimeRange(int startMinutes, int endMinutes) {
    String fmt(int minutes) {
      final h = (minutes ~/ 60).toString().padLeft(2, '0');
      final m = (minutes % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${fmt(startMinutes)}–${fmt(endMinutes)}';
  }
}
