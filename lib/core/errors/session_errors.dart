class SessionFullException implements Exception {
  const SessionFullException({this.capacity});

  final int? capacity;

  @override
  String toString() => capacity != null
      ? 'This class is full ($capacity spots).'
      : 'This class is full.';
}
