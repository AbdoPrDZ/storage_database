import 'dart:io';

abstract class ExplorerSource {
  const ExplorerSource();

  Future<Directory> dir(String path);
  Future<File> file(String path);
  Directory dirSync(String path);
  File fileSync(String path);

  void onDirCreate(String dir) {}
  void onDirUpdate(String dir) {}
  void onDirDelete(String dir) {}

  void onFileCreate(String path) {}
  void onFileUpdate(String path) {}
  void onFileDelete(String path) {}
}
