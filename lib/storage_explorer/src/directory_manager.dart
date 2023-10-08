abstract class DirectoryManager {
  final String path;

  const DirectoryManager(this.path);

  Future<bool> create();
  bool createSync();

  Future<bool> exists();
  bool existsSync();

  Future<void> delete();
  void deleteSync();

  List<DirectoryItemManager> listSync();
}

abstract class DirectoryItemManager {
  final String path;

  const DirectoryItemManager(this.path);

  bool get isDirectory;
}
