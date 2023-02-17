import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../src/storage_listeners.dart';
import '../storage_database.dart';

export '../src/storage_database_values.dart';

class StorageExplorer {
  final StorageDatabase storageDatabase;
  final StorageListeners storageListeners;
  final ExplorerDirectory localDirectory;

  StorageExplorer(
    this.storageDatabase,
    this.storageListeners,
    this.localDirectory,
  ) {
    storageDatabase.onClear.add(() => initLocalDirectory(storageListeners));
  }

  static Future<ExplorerDirectory> initLocalDirectory(
    StorageListeners storageListeners, {
    // String? customPath,
    String? path,
  }) async {
    Directory localIODirectory = Directory(
      path ??
          // "${(await getApplicationDocumentsDirectory()).path}\\storage_database_explorer${customPath != null ? '\\$customPath' : ''}",
          "${(await getApplicationDocumentsDirectory()).path}\\storage_database_explorer",
    );
    String localDirName = localIODirectory.path.split("\\").last;
    if (!localIODirectory.existsSync()) localIODirectory.createSync();
    return ExplorerDirectory(
      localIODirectory,
      localDirName,
      localDirName,
      storageListeners,
    );
  }

  static Future<StorageExplorer> getInstance(
    StorageDatabase storageDatabase, {
    // String? customPath,
    String? path,
  }) async {
    StorageListeners storageListeners = StorageListeners();
    ExplorerDirectory localDirectory = await initLocalDirectory(
      storageListeners,
      // customPath: customPath,
      path: path,
    );
    return StorageExplorer(
      storageDatabase,
      storageListeners,
      localDirectory,
    );
  }

  ExplorerNetworkFiles? networkFiles;
  initNetWorkFiles({ExplorerDirectory? cachDirictory}) {
    networkFiles = ExplorerNetworkFiles(
      this,
      cachDirictory ?? directory('network-files'),
    );
  }

  ExplorerDirectory directory(String dirName, {bool log = true}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];

    Directory nIODirectory = Directory(
      "${localDirectory.ioDirectory.path}\\${dirNames[0]}",
    );
    if (!nIODirectory.existsSync()) nIODirectory.createSync();

    if (log) {
      for (var streamId in storageListeners.getPathStreamIds("explorer")) {
        if (storageListeners.hasStreamId("explorer", streamId)) {
          storageListeners.getDate("explorer", streamId);
        }
      }
    }

    ExplorerDirectory explorerDirectory = ExplorerDirectory(
      nIODirectory,
      dirNames[0],
      dirNames[0],
      storageListeners,
    );
    for (int i = 1; i < dirNames.length; i++) {
      explorerDirectory = explorerDirectory.directory(
        dirNames[i],
      );
    }
    return explorerDirectory;
  }

  ExplorerFile file(String filename) {
    File ioFile = File("${localDirectory.ioDirectory.path}\\$filename");
    if (!ioFile.existsSync()) {
      ioFile.createSync();
    }
    return ExplorerFile(
      ioFile,
      "",
      filename,
      storageListeners,
    );
  }

  Future clear() async => await localDirectory.clear();
}
