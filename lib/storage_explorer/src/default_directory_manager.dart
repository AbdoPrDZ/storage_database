import 'dart:io';

import 'package:path/path.dart';

import 'directory_manager.dart';

class DefaultDirectoryManager extends DirectoryManager {
  const DefaultDirectoryManager(super.path);

  Directory get ioDirectory => Directory(path);

  @override
  Future<bool> exists() => ioDirectory.exists();

  @override
  bool existsSync() => ioDirectory.existsSync();

  @override
  Future<bool> create() async {
    await ioDirectory.create();
    return true;
  }

  @override
  bool createSync() {
    ioDirectory.createSync();
    return true;
  }

  @override
  Future<bool> delete() async {
    await ioDirectory.delete();
    return true;
  }

  @override
  bool deleteSync() {
    ioDirectory.deleteSync();
    return true;
  }

  @override
  List<DirectoryItemManager> listSync() {
    List<DirectoryItemManager> items = [];
    for (var item in ioDirectory.listSync()) {
      items.add(DefaultDirectoryItemManager(basename(item.path)));
    }
    return items;
  }
}

class DefaultDirectoryItemManager extends DirectoryItemManager {
  const DefaultDirectoryItemManager(super.path);

  @override
  bool get isDirectory => FileSystemEntity.isDirectorySync(path);
}
