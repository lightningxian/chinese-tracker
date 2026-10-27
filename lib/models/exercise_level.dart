import 'package:cloud_firestore/cloud_firestore.dart';

/// A named bundle of exercises assigned to a group of students
/// (`exercise_levels`). Saving a level materialises one
/// `exercise_assignments` doc per (exercise, student) pair, tagged with
/// `levelId`, so every student view, stat and report keeps working unchanged.
/// Editing the level adds or removes those assignments for everyone in it.
class ExerciseLevel {
  const ExerciseLevel({
    required this.id,
    required this.name,
    this.hskLevel,
    this.description,
    this.exerciseIds = const [],
    this.studentIds = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// e.g. "HSK 1"; null when the bundle mixes levels.
  final String? hskLevel;
  final String? description;
  final List<String> exerciseIds;
  final List<String> studentIds;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExerciseLevel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    List<String> ids(String key) =>
        (d[key] as List?)?.whereType<String>().toList() ?? const [];
    return ExerciseLevel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      hskLevel: d['hskLevel'] as String?,
      description: d['description'] as String?,
      exerciseIds: ids('exerciseIds'),
      studentIds: ids('studentIds'),
      createdBy: d['createdBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'hskLevel': hskLevel,
        'description': description,
        'exerciseIds': exerciseIds,
        'studentIds': studentIds,
      };

  ExerciseLevel copyWith({
    String? name,
    String? hskLevel,
    bool clearHskLevel = false,
    String? description,
    List<String>? exerciseIds,
    List<String>? studentIds,
  }) =>
      ExerciseLevel(
        id: id,
        name: name ?? this.name,
        hskLevel: clearHskLevel ? null : (hskLevel ?? this.hskLevel),
        description: description ?? this.description,
        exerciseIds: exerciseIds ?? this.exerciseIds,
        studentIds: studentIds ?? this.studentIds,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
