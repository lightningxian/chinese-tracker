class ClassConcludeException implements Exception {
  const ClassConcludeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ConcludeClassResult {
  const ConcludeClassResult({
    required this.creditedCount,
    required this.failedStudents,
    this.excusedCount = 0,
  });

  final int creditedCount;
  final List<String> failedStudents;
  /// Students marked izin (excused): not charged.
  final int excusedCount;

  bool get hasFailures => failedStudents.isNotEmpty;

  /// "3 charged, 1 excused" for snackbars and notifications.
  String get summary {
    final parts = ['$creditedCount charged'];
    if (excusedCount > 0) parts.add('$excusedCount excused');
    return parts.join(', ');
  }
}
