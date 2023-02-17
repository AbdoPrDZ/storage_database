import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

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
    storageListeners = StorageListeners();
  }

  bool isMap(var data) {
    bool isMap = true;
    try {
      Map.from(data);
    } catch (e) {
      isMap = false;
    }
    return isMap;
  }

  bool isList(var data) {
    bool isList = true;
    try {
      List.from(data);
    } catch (e) {
      isList = false;
    }
    return isList;
  }

  Future<dynamic> checkType(var data) async {
    if (!await storageDatabase.checkCollectionIdExists(collectionId)) {
      var initialData = isMap(data)
          ? {}
          : isList(data)
              ? []
              : null;
      await storageDatabase.source.setData(collectionId, initialData);
      return initialData;
    } else {
      dynamic collectionData =
          await storageDatabase.source.getData(collectionId);
      bool currectType = false;
      try {
        if (collectionData == null) {
          currectType = true;
        } else if (isMap(data)) {
          Map.from(collectionData);
          currectType = true;
        } else if (isList(data)) {
          List.from(collectionData);
          currectType = true;
        } else {
          currectType = collectionData.runtimeType == data.runtimeType;
        }
      } catch (e) {
        dev.log("collection check type: $e");
      }
      if (!currectType) {
        throw StorageDatabaseException(
          "The data type must be ${collectionData.runtimeType}, but current type is (${data.runtimeType})",
        );
      }
      return collectionData;
    }
  }

  Future set(var data, {bool log = true, bool keepData = true}) async {
    dynamic collectionData = await checkType(data);
    if (keepData && isMap(data)) {
      for (var key in data.keys) {
        collectionData[key] = data[key];
      }
    } else if (keepData && isList(data)) {
      for (var item in data) {
        if (!collectionData.contains(item)) {
          collectionData.add(item);
        }
      }
    } else {
      collectionData = data;
    }
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }
    await storageDatabase.source.setData(
      collectionId,
      collectionData,
    );
  }

  Future<dynamic> get({String? streamId}) async {
    if (!await storageDatabase.checkCollectionIdExists(collectionId)) {
      throw StorageDatabaseException(
        "This collection ($collectionId) has not yet been created",
      );
    }
    dynamic collectionData = storageDatabase.source.getData(collectionId);
    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }
    return collectionData;
  }

  String get path => collectionId;

  Future<bool> hasDocumentId(dynamic documentId) async {
    try {
      return Map.from(await get()).containsKey(documentId);
    } catch (e) {
      dev.log("has id: $e");
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support documents",
      );
    }
  }

  String get randomStreamId => String.fromCharCodes(
        List.generate(8, (index) => Random().nextInt(33) + 89),
      );

  Stream stream({delayCheck = const Duration(milliseconds: 50)}) async* {
    String streamId = randomStreamId;
    storageListeners.initStream(path, streamId);
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = storageListeners.getDates(path, streamId);
      if (dates["set_date"] >= dates["get_date"]) {
        yield await get(streamId: streamId);
      }
    }
  }

  Future<bool> delete({bool log = true}) async {
    bool res = await storageDatabase.source.remove(collectionId);
    for (String streamId in storageListeners.getPathStreamIds(path)) {
      if (log && storageListeners.hasStreamId(path, streamId)) {
        storageListeners.setDate(path, streamId);
      }
    }
    return res;
  }

  deleteItem(itemId, {bool log = true}) async {
    var collectionData = await get();
    if (isMap(collectionData)) {
      collectionData.remove(itemId);
    } else if (isList(collectionData)) {
      collectionData.removeAt(itemId);
    } else {
      throw const StorageDatabaseException(
        'This Collection doesn\'t support documents',
      );
    }
    await set(collectionData, keepData: false);
    for (String streamId in storageListeners.getPathStreamIds(path)) {
      if (log && storageListeners.hasStreamId(path, streamId)) {
        storageListeners.setDate(path, streamId);
      }
    }
  }

  StorageDocument document(dynamic docId) {
    // if (!storageDatabase.checkCollectionIdExists(collectionId)) {
    //   storageDatabase.source.setData(collectionId, {});
    // }
    storageDatabase.checkCollectionIdExists(collectionId).then((contain) {
      if (!contain) storageDatabase.source.setData(collectionId, {});
    });
    List docIds = docId.runtimeType == String ? docId.split("/") : [docId];

    StorageDocument document = StorageDocument(
      storageDatabase,
      this,
      collectionId,
      docIds[0],
      storageListeners,
    );
    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  Stream<Map<dynamic, StorageDocument>> streamDocs() =>
      stream().asyncExpand<Map<dynamic, StorageDocument>>((data) async* {
        if (data != null) yield getMapDocs(data);
      });

  Future<Map<dynamic, StorageDocument>> getDocs() async =>
      getMapDocs(await get());

  Map<dynamic, StorageDocument> getMapDocs(var data) {
    List docsIds;
    if (isMap(data)) {
      docsIds = data.keys.toList();
    } else if (isList(data)) {
      docsIds = [for (int i = 0; i < data.length; i++) i];
    } else {
      throw StorageDatabaseException(
        "This collection ($collectionId) does not support documents",
      );
    }
    Map<dynamic, StorageDocument> docs = {};
    for (dynamic docId in docsIds) {
      docs[docId] = StorageDocument(
        storageDatabase,
        this,
        collectionId,
        docId,
        storageListeners,
      );
    }
    return docs;
  }
}
