import 'dart:io';

abstract class ExplorerSource {
  Future<Directory> dir(String path);
  Future<File> file(String path);
  Directory dirSync(String path);
  File fileSync(String path);

  onDirCreate(String path);
  onDirUpdate(String path);
  onDirDelete(String path);

  onFileCreate(String path);
  onFileUpdate(String path);
  onFileDelete(String path);
}
