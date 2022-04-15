import 'dart:io';
import 'dart:math';

import '../src/storage_listeners.dart';
import 'explorer_directory_item.dart';

import 'explorer_file.dart';

class ExplorerDirectory {
  final Directory ioDirectory;
  final String directoryName, shortPath;
  final StorageListeners storageListeners;

  ExplorerDirectory(
    this.ioDirectory,
    this.directoryName,
    this.shortPath,
    this.storageListeners,
  );

  List<ExplorerDirectoryItem> get({String? streamId}) {
    if (!ioDirectory.existsSync()) ioDirectory.createSync();
    List<FileSystemEntity> ioFiles = ioDirectory.listSync();
    List<ExplorerDirectoryItem> items = [];
    for (FileSystemEntity item in ioFiles) {
      String itemName = item.path.split("\\").last;
      bool isDirectory = item.runtimeType.toString().contains("Directory");
      if (isDirectory) {
        items.add(
          ExplorerDirectoryItem(itemName, directory(itemName), this),
        );
      } else {
        items.add(
          ExplorerDirectoryItem(itemName, file(itemName), this),
        );
      }
    }
    if (streamId != null && storageListeners.hasStreamId(shortPath, streamId)) {
      storageListeners.setDate(shortPath, streamId);
    }
    return items;
  }

  bool hasFile(String filename) =>
      File("${ioDirectory.path}\\$filename").existsSync();

  ExplorerFile file(String filename) {
    return ExplorerFile(
      File("${ioDirectory.path}\\$filename"),
      shortPath,
      filename,
      storageListeners,
    );
  }

  ExplorerDirectory directory(String dirName, {String? streamId}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];

    Directory nioDirectory = Directory("${ioDirectory.path}\\${dirNames[0]}");
    if (!nioDirectory.existsSync()) nioDirectory.createSync();

    if (streamId != null && storageListeners.hasStreamId(shortPath, streamId)) {
      storageListeners.setDate(shortPath, streamId);
    }

    ExplorerDirectory exolorerDirectory = ExplorerDirectory(
      nioDirectory,
      dirNames[0],
      "$shortPath/${dirNames[0]}",
      storageListeners,
    );

    for (int i = 1; i < dirNames.length; i++) {
      exolorerDirectory = exolorerDirectory.directory(
        dirNames[i],
      );
    }

    return exolorerDirectory;
  }

  Future delete({bool log = true}) async {
    await ioDirectory.delete(recursive: true);
    if (log) {
      for (String streamId in storageListeners.getPathStreamIds(shortPath)) {
        if (storageListeners.hasStreamId(shortPath, streamId)) {
          storageListeners.setDate(shortPath, streamId);
        }
      }
    }
  }

  String get randomStreamId => String.fromCharCodes(
        List.generate(8, (index) => Random().nextInt(33) + 89),
      );

  Stream<List<ExplorerDirectoryItem>> stream(
      {delayCheck = const Duration(milliseconds: 50)}) async* {
    String streamId = randomStreamId;
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
      if (item.itemType == ExplorerDirectory) {
        ExplorerDirectory dir = item.item;
        await dir.delete();
      } else {
        await item.item.delete();
      }
    }
  }
}
