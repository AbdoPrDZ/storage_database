import 'dart:io';

import 'explorer_source.dart';

class DefaultExplorerSource extends ExplorerSource {
  const DefaultExplorerSource();

  @override
  Future<Directory> dir(String path) async => dirSync(path);

  @override
  Future<File> file(String path) async => fileSync(path);

  @override
  Directory dirSync(String path) => Directory(path);

  @override
  File fileSync(String path) => File(path);
}
