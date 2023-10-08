import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';

import 'directory_manager.dart';
import 'explorer_source.dart';
import 'file_manager.dart';

class DefaultFileManager extends FileManager {
  const DefaultFileManager(super.path);

  File get ioFile => File(path);

  @override
  Future<bool> exists() => ioFile.exists();

  @override
  bool existsSync() => ioFile.existsSync();

  @override
  Future<bool> create() async {
    await ioFile.create();
    return true;
  }

  @override
  bool createSync() {
    ioFile.createSync();
    return true;
  }

  @override
  Future<bool> delete() async {
    await ioFile.delete();
    return true;
  }

  @override
  bool deleteSync() {
    ioFile.deleteSync();
    return true;
  }

  @override
  Future<String> read() => ioFile.readAsString();

  @override
  String readSync() => ioFile.readAsStringSync();

  @override
  Future write(String data) => ioFile.writeAsString(data);

  @override
  void writeSync(String data) => ioFile.writeAsStringSync(data);

  @override
  Future<Uint8List> readBytes() => ioFile.readAsBytes();

  @override
  Uint8List readBytesSync() => ioFile.readAsBytesSync();

  @override
  Future writeBytes(Uint8List bytes) => ioFile.writeAsBytes(bytes);

  @override
  void writeBytesSync(Uint8List bytes) => ioFile.writeAsBytesSync(bytes);

  @override
  Future<DateTime> lastModified() => ioFile.lastModified();
}

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

class DefaultExplorerSource extends ExplorerSource {
  @override
  DirectoryManager dir(String path) => DefaultDirectoryManager(path);

  @override
  FileManager file(String path) => DefaultFileManager(path);
}

class DefaultDirectoryItemManager extends DirectoryItemManager {
  const DefaultDirectoryItemManager(super.path);

  @override
  bool get isDirectory => FileSystemEntity.isDirectorySync(path);
}
