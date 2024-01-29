import 'package:storage_database/src/storage_database_exception.dart';

import 'src/default_storage_source.dart';
import 'src/storage_database_source.dart';
import 'src/storage_listeners.dart';
import 'storage_explorer/storage_explorer.dart';
import 'storage_collection.dart';
import 'api/api.dart';
import 'laravel_echo/laravel_echo.dart';

export 'storage_collection.dart';

export 'src/storage_database_source.dart';
export 'src/storage_database_values.dart';

export 'storage_explorer/storage_explorer.dart';

export 'api/api.dart';

export 'laravel_echo/laravel_echo.dart';

class StorageDatabase {
  final StorageDatabaseSource source;

  StorageDatabase(this.source);

  final List<Function> _onClear = [];
  final StorageListeners storageListeners = StorageListeners();

  static Future<StorageDatabase> getInstance({
    StorageDatabaseSource? source,
  }) async =>
      StorageDatabase(
        source ?? await DefaultStorageSource.instance,
      );

  StorageExplorer? _explorer;
  Future initExplorer({String? path}) async =>
      _explorer = await StorageExplorer.getInstance(this, path: path);

  bool get storageExplorerHasInitialized => _explorer != null;

  StorageExplorer get explorer {
    if (!storageExplorerHasInitialized) {
      throw const StorageDatabaseException(
        'StorageExplorer service has not initialized yet',
      );
    }
    return _explorer!;
  }

  StorageAPI? _storageAPI;
  initAPI({required String apiUrl, Map<String, String> headers = const {}}) =>
      _storageAPI = StorageAPI(
        storageDatabase: this,
        apiUrl: apiUrl,
        headers: headers,
      );

  bool get storageAPIHasInitialized => _storageAPI != null;

  StorageAPI get storageAPI {
    if (!storageAPIHasInitialized) {
      throw const StorageDatabaseException(
        'StorageAPI service has not initialized yet',
      );
    }
    return _storageAPI!;
  }

  LaravelEcho? _laravelEcho;
  initLaravelEcho(Connector connector, List<LaravelEchoMigration> migrations) =>
      _laravelEcho = LaravelEcho(this, connector, migrations);

  bool get laravelEchoHasInitialized => _laravelEcho != null;

  LaravelEcho get laravelEcho {
    if (!laravelEchoHasInitialized) {
      throw const StorageDatabaseException(
        'LaravelEcho service has not initialized yet',
      );
    }
    return _laravelEcho!;
  }

  initSocketLaravelEcho(
    String host,
    List<LaravelEchoMigration> migrations, {
    Map<String, String>? authHeaders,
    String? authEndpoint,
    String? nameSpace,
    bool autoConnect = true,
    Map<dynamic, dynamic> moreOptions = const {},
  }) {
    _laravelEcho?.disconnect();
    _laravelEcho = LaravelEcho.socket(
      this,
      host,
      migrations,
      authHeaders: authHeaders,
      nameSpace: nameSpace,
      autoConnect: autoConnect,
      moreOptions: moreOptions,
    );
  }

  initPusherLaravelEcho(
    String appKey,
    List<LaravelEchoMigration> migrations, {
    required String authEndPoint,
    Map<String, String> authHeaders = const {
      'Content-Type': 'application/json'
    },
    String? cluster,
    required String host,
    int wsPort = 80,
    int wssPort = 443,
    bool encrypted = true,
    int activityTimeout = 120000,
    int pongTimeout = 30000,
    int maxReconnectionAttempts = 6,
    int maxReconnectGapInSeconds = 30,
    bool enableLogging = true,
    bool autoConnect = true,
    String? nameSpace,
  }) {
    _laravelEcho?.disconnect();
    _laravelEcho = LaravelEcho.pusher(
      this,
      appKey,
      migrations,
      authEndPoint: authEndPoint,
      authHeaders: authHeaders,
      cluster: cluster,
      host: host,
      wsPort: wsPort,
      wssPort: wssPort,
      encrypted: encrypted,
      activityTimeout: activityTimeout,
      pongTimeout: pongTimeout,
      maxReconnectionAttempts: maxReconnectionAttempts,
      maxReconnectGapInSeconds: maxReconnectGapInSeconds,
      enableLogging: enableLogging,
      autoConnect: autoConnect,
      nameSpace: nameSpace,
    );
  }

  StorageCollection collection(String collectionId) =>
      StorageCollection(this, collectionId);

  Future<bool> checkCollectionIdExists(String collectionId) =>
      source.containsKey(collectionId);

  void onClear(Function func) => _onClear.add(func);

  Future clear({
    bool clearExplorer = true,
    bool clearNetworkFiles = true,
    bool clearAPI = true,
  }) async {
    if (clearExplorer && _explorer != null) await explorer.clear();
    if (clearNetworkFiles &&
        _explorer != null &&
        explorer.networkFilesHasInitialized) {
      await explorer.networkFiles.clear();
    }
    if (clearAPI && _storageAPI != null) await storageAPI.clear();

    await source.clear();

    for (Function onClearFunc in _onClear) {
      onClearFunc();
    }
  }
}
