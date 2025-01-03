import 'dart:io';

abstract class ExplorerSource {
  const ExplorerSource();

  Future<Directory> dir(String path);
  Future<File> file(String path);
  Directory dirSync(String path);
  File fileSync(String path);

  onDirCreate(String dir);
  onDirUpdate(String dir);
  onDirDelete(String dir);

  onFileCreate(String path);
  onFileUpdate(String path);
  onFileDelete(String path);
}
