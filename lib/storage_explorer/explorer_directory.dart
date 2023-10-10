// import 'dart:io';
import 'dart:math';

import 'package:path/path.dart';

import '../src/storage_listeners.dart';
import 'explorer_directory_item.dart';

import 'explorer_file.dart';
import 'src/directory_manager.dart';
import 'src/explorer_source.dart';

class ExplorerDirectory {
  final ExplorerSource explorerSource;
  final DirectoryManager ioDirectory;
  final String directoryName, shortPath;
  final StorageListeners storageListeners;

  ExplorerDirectory(
    this.explorerSource,
    this.ioDirectory,
    this.directoryName,
    this.shortPath,
    this.storageListeners,
  );

  String get path => ioDirectory.path;

  List<ExplorerDirectoryItem> get({String? streamId}) {
    if (!ioDirectory.existsSync()) ioDirectory.createSync();
    List<DirectoryItemManager> ioFiles = ioDirectory.listSync();
    List<ExplorerDirectoryItem> items = [];
    for (DirectoryItemManager item in ioFiles) {
      // String itemName = item.path.split("\\").last;
      String itemName = basename(item.path);
      items.add(
        ExplorerDirectoryItem(itemName,
            item.isDirectory ? directory(itemName) : file(itemName), this),
      );
    }
    if (streamId != null && storageListeners.hasStreamId(shortPath, streamId)) {
      storageListeners.setDate(shortPath, streamId);
    }
    return items;
  }

  bool hasFile(String filename) =>
      // File("${ioDirectory.path}/$filename").existsSync();
      explorerSource.file("${ioDirectory.path}/$filename").existsSync();

  ExplorerFile file(String filename) => ExplorerFile(
        explorerSource,
        // File("${ioDirectory.path}/$filename"),
        explorerSource.file("${ioDirectory.path}/$filename"),
        shortPath,
        filename,
        storageListeners,
      );

  ExplorerDirectory directory(String dirName, {String? streamId}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];
    dirNames = [for (String name in dirNames) name.replaceAll('\\', '/')];

    // Directory nioDirectory = Directory("${ioDirectory.path}/${dirNames[0]}");
    DirectoryManager nioDirectory =
        explorerSource.dir("${ioDirectory.path}/${dirNames[0]}");
    if (!nioDirectory.existsSync()) nioDirectory.createSync();

    if (streamId != null && storageListeners.hasStreamId(shortPath, streamId)) {
      storageListeners.setDate(shortPath, streamId);
    }

    ExplorerDirectory explorerDirectory = ExplorerDirectory(
      explorerSource,
      nioDirectory,
      dirNames[0],
      "$shortPath/${dirNames[0]}",
      storageListeners,
    );

    for (int i = 1; i < dirNames.length; i++) {
      explorerDirectory = explorerDirectory.directory(dirNames[i]);
    }

    return explorerDirectory;
  }

  Future delete({bool log = true}) async {
    await ioDirectory.delete();
    if (log) {
      for (String streamId in storageListeners.getPathStreamIds(shortPath)) {
        if (storageListeners.hasStreamId(shortPath, streamId)) {
          storageListeners.setDate(shortPath, streamId);
        }
      }
    }
  }

  String get _randomStreamId => String.fromCharCodes(
        List.generate(8, (index) => Random().nextInt(33) + 89),
      );

  Stream<List<ExplorerDirectoryItem>> stream(
      {delayCheck = const Duration(milliseconds: 50)}) async* {
    String streamId = _randomStreamId;
    storageListeners.initStream(shortPath, streamId);
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = storageListeners.getDates(shortPath, streamId);
      if (dates["set_date"] >= dates["get_date"]) {
        yield get();
      }
    }
  }

  Future clear() async {
    List<ExplorerDirectoryItem> dirItems = get();
    for (var item in dirItems) {
      if (item.itemType is ExplorerDirectory) {
        ExplorerDirectory dir = item.item;
        await dir.delete();
      } else {
        await item.item.delete();
      }
    }
  }
}
