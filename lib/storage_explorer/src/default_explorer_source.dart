import 'dart:io';

import 'explorer_source.dart';

class DefaultExplorerSource extends ExplorerSource {
  @override
  Future<Directory> dir(String path) async => dir(path);

  @override
  Future<File> file(String path) async => file(path);

  @override
  Directory dirSync(String path) => Directory(path);

  @override
  File fileSync(String path) => File(path);

  @override
  onDirCreate(String path) => null;

  @override
  onDirDelete(String path) => null;

  @override
  onDirUpdate(String path) => null;

  @override
  onFileCreate(String path) => null;

  @override
  onFileDelete(String path) => null;

  @override
  onFileUpdate(String path) => null;
}
