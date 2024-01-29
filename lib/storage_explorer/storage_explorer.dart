import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_database/src/storage_database_exception.dart';

import '../src/storage_listeners.dart';
import '../storage_database.dart';
import 'explorer_network_files.dart';
import 'src/default_explorer_source.dart';
import 'src/explorer_source.dart';

export './explorer_directory.dart';
export './explorer_file.dart';

class StorageExplorer {
  final StorageDatabase storageDatabase;
  final ExplorerSource explorerSource;
  final StorageListeners storageListeners;
  final ExplorerDirectory localDirectory;

  StorageExplorer(
    this.storageDatabase,
    this.explorerSource,
    this.storageListeners,
    this.localDirectory,
  ) {
    storageDatabase.onClear(() => _initLocalDirectory(
          storageListeners,
          explorerSource,
          path: localDirectory.ioDirectory.path,
        ));
  }

  static Future<ExplorerDirectory> _initLocalDirectory(
    StorageListeners storageListeners,
    ExplorerSource source, {
    String? path,
  }) async {
    Directory localIODirectory = Directory(
      path ??
          "${(await getApplicationDocumentsDirectory()).path}/storage_database_explorer",
    );
    String localDirName = basename(localIODirectory.path);
    if (!localIODirectory.existsSync()) localIODirectory.createSync();
    return ExplorerDirectory(
      source,
      localIODirectory,
      localDirName,
      localDirName,
      storageListeners,
    );
  }

  static Future<StorageExplorer> getInstance(
    StorageDatabase storageDatabase, {
    ExplorerSource? source,
    String? path,
  }) async {
    StorageListeners storageListeners = StorageListeners();
    source = source ?? DefaultExplorerSource();
    ExplorerDirectory localDirectory = await _initLocalDirectory(
      storageListeners,
      source,
      path: path,
    );
    return StorageExplorer(
      storageDatabase,
      source,
      storageListeners,
      localDirectory,
    );
  }

  ExplorerNetworkFiles? _networkFiles;
  initNetWorkFiles({ExplorerDirectory? cacheDirectory}) {
    _networkFiles = ExplorerNetworkFiles(
      this,
      cacheDirectory ?? directory('network-files'),
    );
  }

  bool get networkFilesHasInitialized => _networkFiles != null;

  ExplorerNetworkFiles get networkFiles {
    if (!networkFilesHasInitialized) {
      throw const StorageDatabaseException(
        'ExplorerNetworkFiles has not initialized yet',
      );
    }
    return _networkFiles!;
  }

  ExplorerDirectory directory(String dirName, {bool log = true}) {
    List<String> dirNames =
        dirName.contains("/") ? dirName.split("/") : [dirName];
    dirNames = [for (String name in dirNames) name.replaceAll('\\', '/')];

    // Directory nIODirectory = Directory(
    Directory nIODirectory = explorerSource.dirSync(
      "${localDirectory.ioDirectory.path}/${dirNames[0]}",
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
      explorerSource,
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
    // File ioFile = File("${localDirectory.ioDirectory.path}\\$filename");
    File ioFile = explorerSource
        .fileSync("${localDirectory.ioDirectory.path}\\$filename");
    if (!ioFile.existsSync()) {
      ioFile.createSync();
    }
    return ExplorerFile(
      explorerSource,
      ioFile,
      "",
      filename,
      storageListeners,
    );
  }

  Future clear() async => await localDirectory.clear();
}
