import 'dart:developer' as dev;
import 'dart:math';

import './storage_database.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_listeners.dart';

class StorageDocument {
  final StorageDatabase storageDatabase;
  final dynamic parent;
  final dynamic documentId, parentId;

  StorageDocument(
    this.storageDatabase,
    this.parent,
    this.parentId,
    this.documentId,
  );

  StorageListeners get storageListeners => parent.storageListeners;

  Future<dynamic> _getParentData() async {
    var parentData = await parent.get();

    try {
      Map.from(parentData);
    } catch (e) {
      try {
        List.from(parentData);
      } catch (e) {
        dev.log("document error: $e");

        throw const StorageDatabaseException(
          "Document parent doesn't support documents",
        );
      }
    }

    return parentData;
  }

  bool _isMap(dynamic data) {
    try {
      Map.from(data);

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isList(var data) {
    try {
      List.from(data);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future _checkType(var data) async {
    dynamic parentData = await _getParentData();

    if (!parentData.containsKey(documentId)) {
      var initialData = _isMap(data)
          ? {}
          : _isList(data)
              ? []
              : null;

      await parent.set({documentId: initialData});

      return initialData;
    } else {
      var docData = parentData[documentId];

      bool currentType = false;

      try {
        if (docData == null) {
          currentType = true;
        } else if (_isMap(data)) {
          Map.from(docData);
          currentType = true;
        } else if (_isList(data)) {
          List.from(docData);
          currentType = true;
        } else {
          currentType = docData.runtimeType == data.runtimeType;
        }
      } catch (e) {
        dev.log("document check type: $e");
      }

      if (!currentType) {
        throw StorageDatabaseException(
          "The data type must be ${docData.runtimeType}, but current type is (${data.runtimeType})",
        );
      }

      return docData;
    }
  }

  Future set(var data, {bool log = true, bool keepData = true}) async {
    dynamic docData;

    if (!keepData) {
      docData = data;
    } else {
      docData = await _checkType(data);

      if (_isMap(data)) {
        for (var key in data.keys) {
          docData[key] = data[key];
        }
      } else if (_isList(data)) {
        docData.addAll(data);
      } else {
        docData = data;
      }

      if (log) {
        for (String path in storageListeners.getPathParents(path)) {
          for (var streamId in storageListeners.getPathStreamIds(path)) {
            if (storageListeners.hasStreamId(path, streamId)) {
              storageListeners.setDate(path, streamId);
            }
          }
        }
      }
    }

    await parent.set({documentId: docData});
  }

  StorageDocument document(dynamic docId) {
    List docIds = docId.runtimeType == String ? docId.split("/") : [docId];

    StorageDocument document = StorageDocument(
      storageDatabase,
      this,
      documentId,
      docIds[0],
    );

    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }

    return document;
  }

  Future<bool> hasDocId(dynamic docId) async {
    final docData = await get();
    try {
      return Map.from(docData).containsKey(docId);
    } catch (e) {
      try {
        List lData = List.from(docData);
        try {
          lData[docId];
          return true;
        } catch (e) {
          return false;
        }
      } catch (e) {
        throw const StorageDatabaseException(
          "This Document doesn't support documents",
        );
      }
    }
  }

  Future<dynamic> get({String? streamId}) async {
    dynamic parentData = await _getParentData();

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return parentData[documentId];
  }

  Future delete({bool log = true}) async {
    parent.deleteItem(documentId);

    for (String path in storageListeners.getPathParents(path)) {
      for (String streamId in storageListeners.getPathStreamIds(path)) {
        if (log && storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }
  }

  Future deleteItem(var itemId, {bool log = true}) async {
    var docData = await get();

    if (_isMap(docData)) {
      docData.remove(itemId);
    } else if (_isList(docData)) {
      docData.removeAt(itemId);
    } else {
      throw const StorageDatabaseException(
        'This Document not support documents',
      );
    }

    await set(docData, keepData: false);

    for (String path in storageListeners.getPathParents(path)) {
      for (String streamId in storageListeners.getPathStreamIds(path)) {
        if (log && storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }
  }

  String get path => "${parent.path}/$documentId";

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

    if (_isMap(data)) {
      docsIds = data.keys.toList();
    } else if (_isList(data)) {
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
      );
    }

    return docs;
  }
}
