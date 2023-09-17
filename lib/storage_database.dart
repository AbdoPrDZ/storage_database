import 'src/default_storage_source.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_database_source.dart';
import 'src/storage_listeners.dart';
import 'storage_explorer/storage_explorer.dart';
import 'storage_collection.dart';
import 'storage_document.dart';
import 'api/api.dart';
import 'laravel_echo/laravel_echo.dart';

export 'storage_collection.dart';
export 'storage_document.dart';

export 'src/storage_database_source.dart';
export 'src/storage_database_values.dart';

export 'storage_explorer/storage_explorer.dart';

export 'api/api.dart';

export 'laravel_echo/laravel_echo.dart';

class StorageDatabase {
  final StorageDatabaseSource source;

  List<Function> onClear = [];

  StorageListeners storageListeners = StorageListeners();

  StorageDatabase(this.source);

  static Future<StorageDatabase> getInstance({
    StorageDatabaseSource? source,
  }) async =>
      StorageDatabase(
        source ?? await DefaultStorageSource.instance,
      );

  StorageExplorer? explorer;
  Future initExplorer({String? path}) async =>
      explorer = await StorageExplorer.getInstance(this, path: path);

  StorageAPI? storageAPI;
  initAPI({
    required String apiUrl,
    Map<String, String> headers = const {},
    // Function(APIResponse response)? onReRequestResponse,
  }) =>
      storageAPI = StorageAPI(
        storageDatabase: this,
        apiUrl: apiUrl,
        headers: headers,
        // onReRequestResponse: onReRequestResponse,
      );

  LaravelEcho? laravelEcho;
  initLaravelEcho(Connector connector, List<LaravelEchoMigration> migrations) =>
      laravelEcho = LaravelEcho(this, connector, migrations);

  initSocketLaravelEcho(
    String host,
    List<LaravelEchoMigration> migrations, {
    Map<String, String>? authHeaders,
    String? authEndpoint,
    String? nameSpace,
    bool autoConnect = true,
    Map<dynamic, dynamic> moreOptions = const {},
  }) {
    if (laravelEcho != null) laravelEcho!.disconnect();
    laravelEcho = LaravelEcho.socket(
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
    if (laravelEcho != null) laravelEcho!.disconnect();
    laravelEcho = LaravelEcho.pusher(
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

  StorageDocument document(String documentPath) {
    if (!documentPath.contains("/")) {
      throw const StorageDatabaseException(
        "Incorrect document path, ex: 'collection/doc/docChild'",
      );
    }
    List<String> docIds = documentPath.split("/");
    StorageDocument document = StorageCollection(this, docIds[0]).document(
      docIds[1],
    );
    for (int i = 2; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  Future checkCollectionIdExists(String collectionId) =>
      source.containsKey(collectionId);

  Future clear({
    bool clearExplorer = true,
    bool clearNetworkFiles = true,
    bool clearAPI = true,
  }) async {
    if (clearExplorer && explorer != null) await explorer!.clear();
    if (clearNetworkFiles &&
        explorer != null &&
        explorer!.networkFiles != null) {
      await explorer!.networkFiles!.clear();
    }
    if (clearAPI && storageAPI != null) await storageAPI!.clear();

    await source.clear();

    for (Function onClearFunc in onClear) {
      onClearFunc();
    }
  }
}
