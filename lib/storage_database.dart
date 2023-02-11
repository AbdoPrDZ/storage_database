import './defualt_storae_source.dart';
import './storage_collection.dart';
import 'api/api.dart';
import 'src/storage_database_excption.dart';
import 'src/storage_database_source.dart';
import './storage_document.dart';
import 'storage_explorer/storage_explorer.dart';

export 'src/storage_database_source.dart';

export 'storage_explorer/explorer_network_files.dart';
export 'storage_explorer/explorer_directory.dart';
export 'storage_explorer/explorer_file.dart';

export 'api/api.dart';
export 'api/request.dart';
export 'api/response.dart';

class StorageDatabase {
  final StorageDatabaseSource source;
  StorageExplorer? explorer;
  StorageAPI? storageAPI;

  List<Function> onClear = [];

  StorageDatabase(this.source);

  static Future<StorageDatabase> getInstance({
    StorageDatabaseSource? source,
  }) async =>
      StorageDatabase(
        source ?? await DefualtStorageSource.getInstance(),
      );

  Future initExplorer() async =>
      explorer = await StorageExplorer.getInstance(this);

  Future initAPI({
    required String apiUrl,
    Map<String, String> headers = const {},
    // Function(APIResponse response)? onReRequestResponse,
  }) async {
    storageAPI = StorageAPI(
      storageDatabase: this,
      apiUrl: apiUrl,
      headers: headers,
      // onReRequestResponse: onReRequestResponse,
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

  checkCollectionIdExists(String collectionId) =>
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
