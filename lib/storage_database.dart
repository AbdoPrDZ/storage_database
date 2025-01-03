import 'dart:typed_data';

import 'src/default_storage_source.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_database_source.dart';
import 'src/storage_listeners.dart';
import 'storage_explorer/explorer_network_files.dart';
import 'storage_explorer/storage_explorer.dart';
import 'storage_collection.dart';
import 'api/api.dart';
import 'laravel_echo/laravel_echo.dart';

export 'storage_collection.dart';
export 'src/storage_database_model.dart';

export 'src/storage_database_source.dart';
export 'src/storage_database_values.dart';

export 'storage_explorer/storage_explorer.dart';

export 'api/api.dart';

export 'laravel_echo/laravel_echo.dart';

class StorageDatabase {
  final StorageDatabaseSource source;

  StorageDatabase(this.source) {
    _instance = this;
  }

  final List<Function> _onClear = [];
  final StorageListeners storageListeners = StorageListeners();

  static StorageDatabase? _instance;

  static StorageDatabase get instance {
    if (_instance == null) {
      throw const StorageDatabaseException(
        'StorageDatabase instance has not initialized yet',
      );
    }

    return _instance!;
  }

  static Future<void> initInstance({bool overide = false}) async {
    if (_instance != null && !overide) {
      throw const StorageDatabaseException(
        'StorageDatabase instance has not initialized yet',
      );
    }

    _instance = StorageDatabase(await DefaultStorageSource.instance);
  }

  Future initExplorer({String? path}) =>
      StorageExplorer.initInstance(this, path: path);

  StorageExplorer get explorer => StorageExplorer.instance;

  StorageAPI? _storageAPI;
  void initAPI({
    required String apiUrl,
    Map<String, String> Function(String url)? getHeaders,
    bool log = false,
  }) =>
      _storageAPI = StorageAPI(
        apiUrl: apiUrl,
        getHeaders: getHeaders ??
            (url) => {
                  "Accept": "application/json",
                  'Content-Type': 'application/json; charset=UTF-8',
                },
        log: log,
      );

  bool get storageAPIIsInitialized => _storageAPI != null;

  StorageAPI get storageAPI {
    if (!storageAPIIsInitialized) {
      throw const StorageDatabaseException(
        'StorageAPI service has not initialized yet',
      );
    }

    return _storageAPI!;
  }

  LaravelEcho? _laravelEcho;
  void initLaravelEcho(
    Connector connector, {
    List<LaravelEchoMigration> migrations = const [],
  }) =>
      _laravelEcho = LaravelEcho(this, connector, migrations: migrations);

  bool get laravelEchoIsInitialized => _laravelEcho != null;

  LaravelEcho get laravelEcho {
    if (!laravelEchoIsInitialized) {
      throw const StorageDatabaseException(
        'LaravelEcho service has not initialized yet',
      );
    }
    return _laravelEcho!;
  }

  void initSocketLaravelEcho(
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

  void initPusherLaravelEcho(
    String appKey,
    List<LaravelEchoMigration> migrations, {
    required String authEndPoint,
    Map<String, String> authHeaders = const {
      'Content-Type': 'application/json'
    },
    String? cluster,
    String? host,
    int wsPort = 80,
    int wssPort = 443,
    bool encrypted = true,
    int activityTimeout = 120000,
    int pongTimeout = 30000,
    int maxReconnectionAttempts = 6,
    Duration reconnectGap = const Duration(seconds: 2),
    bool enableLogging = true,
    bool autoConnect = true,
    Map<String, dynamic> Function(Uint8List, Map<String, dynamic>)?
        channelDecryption,
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
      reconnectGap: reconnectGap,
      enableLogging: enableLogging,
      autoConnect: autoConnect,
      nameSpace: nameSpace,
      channelDecryption: channelDecryption,
    );
  }

  StorageCollection collection(String collectionId) =>
      StorageCollection(this, collectionId);

  Future<bool> hasCollectionId(dynamic collectionId) =>
      source.containsKey(collectionId);

  void onClear(Function func) => _onClear.add(func);

  Future clear({
    bool clearExplorer = true,
    bool clearNetworkFiles = true,
  }) async {
    if (clearExplorer && StorageExplorer.hasInstance) await explorer.clear();
    if (clearNetworkFiles &&
        StorageExplorer.hasInstance &&
        ExplorerNetworkFiles.hasInstance) {
      await ExplorerNetworkFiles.instance.clear();
    }

    await source.clear();

    for (Function onClearFunc in _onClear) {
      onClearFunc();
    }
  }
}
