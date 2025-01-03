abstract class StorageDatabaseError implements Exception {
  final String? message;

  const StorageDatabaseError([this.message]);

  @override
  String toString() =>
      'StorageDatabaseError${message is String ? ': $message' : ''}';
}

class StorageDatabaseException extends StorageDatabaseError {
  const StorageDatabaseException([super.message]);
}
