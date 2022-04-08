class StorageDatabaseException {
  final String errorMesssage;

  StorageDatabaseException(this.errorMesssage);

  String get message => errorMesssage;
  int errorCode = 21347;

  String toString() => message;
}
