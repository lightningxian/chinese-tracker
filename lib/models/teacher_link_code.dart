class TeacherLinkCode {
  const TeacherLinkCode({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class TeacherLinkCodeException implements Exception {
  TeacherLinkCodeException(this.message);

  final String message;

  @override
  String toString() => message;
}
