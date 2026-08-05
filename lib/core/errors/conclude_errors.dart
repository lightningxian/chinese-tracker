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
  });

  final int creditedCount;
  final List<String> failedStudents;

  bool get hasFailures => failedStudents.isNotEmpty;
}
