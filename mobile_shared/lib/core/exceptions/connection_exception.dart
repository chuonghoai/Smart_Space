class ConnectionNotReadyException implements Exception {
  final String message;
  ConnectionNotReadyException(this.message);

  @override
  String toString() => 'ConnectionNotReadyException: $message';
}
