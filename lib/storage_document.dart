import 'dart:math';

import './storage_database.dart';
import 'src/storage_database_excption.dart';
import 'src/storage_listeners.dart';

class StorageDocument {
  final StorageDatabase storageDatabase;
  final parrent;
  final dynamic documentId, parrentId;
  final StorageListeners storageListeners;

  StorageDocument(
    this.storageDatabase,
    this.parrent,
    this.parrentId,
    this.documentId,
    this.storageListeners,
  );

  Future<dynamic> getParrentData() async {
    var parrentData = await parrent.get();
    try {
      Map.from(parrentData);
    } catch (e) {
      try {
        List.from(parrentData);
      } catch (e) {
        print("document error: $e");
        throw const StorageDatabaseException(
          "Document parrent doesn't support documents",
        );
      }
    }
    return parrentData;
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

  Future checkType(var data) async {
    dynamic parrentData = await getParrentData();
    if (!parrentData.containsKey(documentId)) {
      var initialData = isMap(data)
          ? {}
          : isList(data)
              ? []
              : null;
      await parrent.set({documentId: initialData});
      return initialData;
    } else {
      var docData = parrentData[documentId];
      bool currectType = false;
      try {
        if (isMap(data)) {
          Map.from(docData);
          currectType = true;
        } else if (isList(data)) {
          List.from(docData);
          currectType = true;
        } else {
          currectType = docData.runtimeType == data.runtimeType;
        }
      } catch (e) {
        print("document check type: $e");
      }
      if (!currectType) {
        throw StorageDatabaseException(
          "The data type must be ${docData.runtimeType}, but current type is (${data.runtimeType})",
        );
      }
      return docData;
    }
  }

  Future set(var data, {bool log = true, bool keepData = true}) async {
    var docData = await checkType(data);
    if (keepData && isMap(data)) {
      for (var key in data.keys) {
        docData[key] = data[key];
      }
    } else if (keepData && isList(data)) {
      docData.addAll(data);
    } else {
      docData = data;
    }
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(path)) {
        if (await storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }
    await parrent.set({documentId: docData});
  }

  StorageDocument document(dynamic docId) {
    List docIds = docId.runtimeType == String ? docId.split("/") : [docId];
    StorageDocument document = StorageDocument(
      storageDatabase,
      this,
      documentId,
      docIds[0],
      storageListeners,
    );
    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  Future<dynamic> get({String? streamId}) async {
    dynamic parrentData = await getParrentData();
    if (streamId != null &&
        await storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }
    return parrentData[documentId];
  }

  Future delete({bool log = true}) async {
    parrent.deleteItem(documentId);
    for (String streamId in storageListeners.getPathStreamIds(path)) {
      if (log && await storageListeners.hasStreamId(path, streamId)) {
        storageListeners.setDate(path, streamId);
      }
    }
  }

  Future deleteItem(var itemId, {bool log = true}) async {
    var docData = await get();
    if (isMap(docData)) {
      docData.remove(itemId);
    } else if (isList(docData)) {
      docData.removeAt(itemId);
    } else {
      throw const StorageDatabaseException(
        'This Document not support documents',
      );
    }
    await set(docData, keepData: false);
    for (String streamId in storageListeners.getPathStreamIds(path)) {
      if (log && storageListeners.hasStreamId(path, streamId)) {
        storageListeners.setDate(path, streamId);
      }
    }
  }

  String get path => "${parrent.path}/$documentId";

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

  Stream<Map<dynamic, StorageDocument>> streamDocs() {
    return stream().asyncExpand<Map<dynamic, StorageDocument>>((data) async* {
      if (data != null) yield getMapDocs(data);
    });
  }

  Map<dynamic, StorageDocument> getDocs() => getMapDocs(get());

  Map<dynamic, StorageDocument> getMapDocs(var data) {
    List docsIds;
    if (isMap(data)) {
      docsIds = data.keys.toList();
    } else if (isList(data)) {
      docsIds = [for (int i = 0; i < data.length; i++) i];
    } else {
      throw StorageDatabaseException(
        "This document ($documentId) does not support documents",
      );
    }
    Map<dynamic, StorageDocument> docs = {};
    for (dynamic docId in docsIds) {
      docs[docId] = StorageDocument(
        storageDatabase,
        this,
        documentId,
        docId,
        storageListeners,
      );
    }
    return docs;
  }
}
