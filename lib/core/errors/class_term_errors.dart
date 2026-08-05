class NoClassCreditsException implements Exception {
  const NoClassCreditsException({this.reason});

  final String? reason;

  @override
  String toString() =>
      reason ??
      'No class sessions left on an active term. Ask your teacher to add a new 8 or 16 session term.';
}
