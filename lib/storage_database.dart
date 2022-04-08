library storage_database;

import './defualt_storae_source.dart';
import './storage_collection.dart';
import 'src/storage_database_excption.dart';
import 'src/storage_database_source.dart';
import './storage_document.dart';

class StorageDatabase {
  final StorageDatabaseSource source;

  StorageDatabase(this.source);

  static Future<StorageDatabase> getInstance({
    StorageDatabaseSource? source,
  }) async =>
      StorageDatabase(
        source ?? await DefualtStorageSource.getInstance(),
      );

  StorageCollection collection(String collectionId) {
    return StorageCollection(this, collectionId);
  }

  StorageDocument document(String documentPath) {
    if (!documentPath.contains("/")) {
      throw StorageDatabaseException(
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

  bool checkCollectionIdExists(String collectionId) {
    return source.containsKey(collectionId);
  }

  Future<bool> clear() async => await source.clear();
}
