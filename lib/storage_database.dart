import 'package:pusher_client_fixed/pusher_client_fixed.dart';

import 'src/default_storage_source.dart';
import './storage_collection.dart';
import 'api/api.dart';
import 'laravel_echo/laravel_echo.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_database_source.dart';
import './storage_document.dart';
import 'src/storage_listeners.dart';
import 'storage_explorer/storage_explorer.dart';

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
      laravelEcho = LaravelEcho(this, connector);

  initSocketLaravelEcho(
    String host, {
    Map? auth,
    String? authEndpoint,
    String? key,
    String? namespace,
    bool autoConnect = false,
    Map moreOptions = const {},
  }) =>
      laravelEcho = LaravelEcho.socket(
        this,
        host,
        auth: auth,
        authEndpoint: authEndpoint,
        key: key,
        namespace: namespace,
        autoConnect: autoConnect,
        moreOptions: moreOptions,
      );

  initPusherLaravelEcho(
    String appKey,
    PusherOptions options, {
    Map? auth,
    String? authEndpoint,
    String? host,
    String? key,
    String? namespace,
    bool autoConnect = true,
    bool enableLogging = true,
    Map moreOptions = const {},
  }) =>
      laravelEcho = LaravelEcho.pusher(
        this,
        appKey,
        options,
        auth: auth,
        authEndpoint: authEndpoint,
        key: key,
        namespace: namespace,
        autoConnect: autoConnect,
        moreOptions: moreOptions,
      );

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
