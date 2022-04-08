import 'dart:async';
import 'dart:convert';

import './storage_database.dart';
import 'src/storage_database_excption.dart';
import './storage_document.dart';
import 'src/storage_listeners.dart';

class StorageCollection {
  final StorageDatabase storageDatabase;
  final String collectionId;
  late String collectionContentType;
  late StorageListeners storageListeners;

  StorageCollection(this.storageDatabase, this.collectionId) {
    storageListeners = StorageListeners(storageDatabase);
  }

  Map checkType(Type dataType) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      storageDatabase.source.setData(
        collectionId,
        dataType.toString().contains("Map")
            ? '{"data": {}}'
            : dataType.toString().contains("List")
                ? '{"data": []}'
                : '{"data": null}',
      );
      return {
        "data": dataType.toString().contains("Map")
            ? {}
            : dataType.toString().contains("List")
                ? []
                : null
      };
    } else {
      Map collectionData = jsonDecode(
        storageDatabase.source.getData(collectionId)!,
      );
      bool currectType = false;
      try {
        if (dataType.toString().contains("Map")) {
          Map.from(collectionData["data"]);
          currectType = true;
        } else if (dataType.toString().contains("List")) {
          List.from(collectionData["data"]);
          currectType = true;
        } else {
          currectType = collectionData["data"].runtimeType == dataType;
        }
      } catch (e) {
        print("collection check type: $e");
      }
      if (!currectType) {
        throw StorageDatabaseException(
          "The data type must be ${collectionData['data'].runtimeType}, but current type is ($dataType)",
        );
      }
      return collectionData;
    }
  }

  set(var data, {bool log = true, bool keepData = true}) {
    Map collectionData = checkType(data.runtimeType);
    if (keepData &&
        (data.runtimeType.toString().contains("Map") ||
            data.runtimeType.toString().contains("List"))) {
      collectionData["data"].addAll(data);
    } else {
      collectionData["data"] = data;
    }
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.setDate(getPath());
    }
    storageDatabase.source.setData(
      collectionId,
      jsonEncode(collectionData),
    );
  }

  dynamic get({bool log = true}) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      throw StorageDatabaseException(
        "This collection has not yet been created",
      );
    }
    Map collectionData = jsonDecode(
      storageDatabase.source.getData(collectionId)!,
    );
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.getDate(getPath());
    }
    storageDatabase.source.setData(collectionId, jsonEncode(collectionData));
    return collectionData["data"];
  }

  String getPath() => collectionId;

  bool hasDocumentId(String documentId) {
    try {
      return Map.from(get()).containsKey(documentId);
    } catch (e) {
      print("has id: $e");
      throw StorageDatabaseException(
        "This Collection does not support documents",
      );
    }
  }

  List<int> getDates() {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      throw StorageDatabaseException(
        "This collection has not yet been created",
      );
    }
    Map collectionData = jsonDecode(
      storageDatabase.source.getData(collectionId)!,
    );
    return [
      collectionData.containsKey("set_date") ? collectionData["set_date"] : 1,
      collectionData.containsKey("get_date") ? collectionData["get_date"] : 0,
    ];
  }

  Stream stream() async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));
      List<int> dates = getDates();
      if (dates[0] > dates[1]) {
        yield get();
      }
    }
  }

  Future<bool> delete() async =>
      await storageDatabase.source.remove(collectionId);

  deleteItem(itemId) {
    var collectionData = get();
    collectionData.remove(itemId);
    set(collectionData, keepData: false);
  }

  StorageDocument document(String docId) {
    if (!storageDatabase.checkCollectionIdExists(collectionId)) {
      storageDatabase.source.setData(collectionId, '{"data": {}}');
    }
    try {
      Map.from(get());
    } catch (e) {
      print("document error $e");
      throw StorageDatabaseException(
        "This collection($collectionId) doesn't support documents",
      );
    }
    List<String> docIds = docId.split("/");
    StorageDocument document = StorageDocument(
        storageDatabase, this, true, collectionId, docIds[0], storageListeners);
    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  Map<String, StorageDocument> getDocs() {
    var data = get();
    List docsIds;
    if (data.runtimeType.toString().contains("Map")) {
      docsIds = data.keys.toList();
    } else {
      throw StorageDatabaseException(
        "This collection does not support documents",
      );
    }
    Map<String, StorageDocument> docs = {};
    for (String docId in docsIds) {
      docs[docId] = StorageDocument(
        storageDatabase,
        this,
        true,
        collectionId,
        docId,
        storageListeners,
      );
    }
    return docs;
  }
}
