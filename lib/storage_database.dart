import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'src/default_storage_source.dart';
import 'src/secure_storage_source.dart';
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
export 'src/default_storage_source.dart';
export 'src/secure_storage_source.dart';
export 'src/storage_database_types.dart';

export 'storage_explorer/storage_explorer.dart';

export 'api/api.dart';

export 'laravel_echo/laravel_echo.dart';

class StorageDatabase {
  final StorageDatabaseSource source;

  StorageDatabase(this.source);

  final List<Function> _onClear = [];
  final StorageListeners storageListeners = StorageListeners();

  static StorageDatabase? _instance;

  static bool get hasInstance => _instance != null;

  static StorageDatabase get instance {
    if (!hasInstance) {
      throw const StorageDatabaseException(
        'StorageDatabase instance has not initialized yet',
      );
    }

    return _instance!;
  }

  static Future<void> initInstance({bool override = false}) async {
    if (hasInstance && !override) {
      throw const StorageDatabaseException(
        'StorageDatabase instance has already initialized',
      );
    }

    _instance = StorageDatabase(await DefaultStorageSource.instance);
  }

  static Future<void> initSecureInstance(
    String sourcePassword, {
    String? sourcePath,
    String sourceName = "storage_database",
    String? appIV,
    bool override = false,
  }) async {
    if (hasInstance && !override) {
      throw const StorageDatabaseException(
        'StorageDatabase instance has already initialized',
      );
    }

    sourcePath ??= (await getApplicationDocumentsDirectory()).path;
    sourcePath += "/$sourceName.sdb";

    _instance = StorageDatabase(
      await SecureStorageSource.instance(sourcePath, sourcePassword, iv: appIV),
    );
  }

  Future initExplorer({String? path}) =>
      StorageExplorer.initInstance(this, path: path);

  StorageExplorer get explorer => StorageExplorer.instance;

  StorageAPI initAPI({
    required String apiUrl,
    Map<String, String> Function(String url)? getHeaders,
    bool log = false,
  }) => StorageAPI.initInstance(
    apiUrl: apiUrl,
    getHeaders:
        getHeaders ??
        (url) => {
          "Accept": "application/json",
          'Content-Type': 'application/json; charset=UTF-8',
        },
    log: log,
  );

  StorageAPI get storageAPI => StorageAPI.instance;

  void initLaravelEcho(
    Connector connector, {
    List<LaravelEchoMigration> migrations = const [],
  }) => LaravelEcho(this, connector, migrations: migrations);

  LaravelEcho get laravelEcho => LaravelEcho.instance;

  LaravelEcho<Socket, SocketIoChannel> get socketLaravelEcho =>
      LaravelEcho.socketInstance;

  LaravelEcho<PusherClient, PusherChannel> get pusherLaravelEcho =>
      LaravelEcho.pusherInstance;

  void initSocketLaravelEcho(
    String host,
    List<LaravelEchoMigration> migrations, {
    Future<Map<String, String>> Function()? authHeaders,
    String? authEndpoint,
    String? nameSpace,
    bool autoConnect = true,
    Map<dynamic, dynamic> moreOptions = const {},
  }) {
    if (LaravelEcho.hasSocketInstance) laravelEcho.disconnect();

    LaravelEcho.socket(
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
    Future<Map<String, String>> Function()? authHeaders,
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
    if (LaravelEcho.hasPusherInstance) laravelEcho.disconnect();

    LaravelEcho.pusher(
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

  void registerModel<MT extends StorageModel>(
    StorageModel Function(dynamic data) encoder, [
    String? collectionId,
  ]) => StorageModelRegister.register<MT>(encoder, collectionId);

  void registerModels(Map<Type, StorageModelRegister> models) =>
      StorageModelRegister.registerAll(models);

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
