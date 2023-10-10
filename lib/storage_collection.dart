import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import './storage_database.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_listeners.dart';

class StorageCollection {
  final StorageDatabase storageDatabase;
  StorageCollection? parent;
  String collectionId;

  StorageCollection(this.storageDatabase, this.collectionId, {this.parent}) {
    if (collectionId.contains("/")) {
      List<String> items = collectionId.split("/");
      parent = StorageCollection(storageDatabase, items[0], parent: parent);
      for (int i = 1; i < items.length - 1; i++) {
        parent!.set({}, log: false);
        parent = parent!.collection(items[i]);
      }
      collectionId = items.last;
    }
  }

  StorageListeners get storageListeners => storageDatabase.storageListeners;

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

  Future<dynamic> _checkType(var data) async {
    if ((parent != null && !await parent!.hasCollectionId(collectionId)) ||
        (parent == null &&
            !await storageDatabase.checkCollectionIdExists(collectionId))) {
      var initialData = _isMap(data)
          ? {}
          : _isList(data)
              ? []
              : null;

      return initialData;
    } else {
      dynamic collectionData = (parent != null
          ? (await parent!.get())[collectionId]
          : await storageDatabase.source.getData(collectionId));

      bool currentType = false;
      try {
        if (collectionData == null) {
          currentType = true;
        } else if (_isMap(data)) {
          Map.from(collectionData);
          currentType = true;
        } else if (_isList(data)) {
          List.from(collectionData);
          currentType = true;
        } else {
          currentType = collectionData.runtimeType == data.runtimeType;
        }
      } catch (e) {
        dev.log("collection check type: $e");
        throw StorageDatabaseException("Collection Check Type Error: $e");
      }

      if (!currentType) {
        throw StorageDatabaseException(
          "The data type must be ${collectionData.runtimeType}, but current type is (${data.runtimeType})",
        );
      }

      return collectionData;
    }
  }

  Future set(var data, {bool log = true, bool keepData = true}) async {
    dynamic collectionData;
    if (!keepData) {
      collectionData = data;
    } else {
      collectionData = await _checkType(data);
      if (_isMap(data)) {
        collectionData ??= {};
        for (var key in data.keys) {
          collectionData[key] = data[key];
        }
      } else if (_isList(data)) {
        collectionData ??= [];
        for (var item in data) {
          if (!collectionData.contains(item)) collectionData.add(item);
        }
      } else {
        collectionData = data;
      }
    }

    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }

    if (parent != null) {
      await parent!.set({collectionId: collectionData});
    } else {
      await storageDatabase.source.setData(
        collectionId,
        collectionData,
      );
    }
  }

  Future<dynamic> get({String? streamId}) async {
    if ((parent != null && !await parent!.hasCollectionId(collectionId)) ||
        (parent == null &&
            !await storageDatabase.checkCollectionIdExists(collectionId))) {
      throw StorageDatabaseException(
        "This collection ($collectionId) has not yet been created",
      );
    }

    dynamic collectionData = (parent != null
        ? (await parent!.get())[collectionId]
        : await storageDatabase.source.getData(collectionId));

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return collectionData;
  }

  String get path => collectionId;

  Future<bool> hasCollectionId(dynamic docId) async {
    final data = await get();
    if (_isMap(data)) {
      return Map.from(data).containsKey(docId);
    } else if (_isList(data)) {
      if (docId is! int) {
        throw const StorageDatabaseException("docId must be integer");
      }
      return List.from(data).length <= docId;
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  StorageCollection collection(String collectionId) =>
      StorageCollection(storageDatabase, collectionId, parent: this);

  String get randomStreamId => String.fromCharCodes(
      List.generate(8, (index) => Random().nextInt(33) + 89));

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
    bool res = parent != null
        ? await parent!.deleteItem(collectionId)
        : await storageDatabase.source.remove(collectionId);

    if (log) {
      for (String streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }

    return res;
  }

  Future<bool> deleteItem(itemId, {bool log = true}) async {
    var collectionData = await get();

    if (_isMap(collectionData)) {
      if ((collectionData as Map).containsKey(itemId)) {
        collectionData.remove(itemId);
      } else {
        throw const StorageDatabaseException('Undefined item id');
      }
    } else if (_isList(collectionData)) {
      if (itemId >= 0 && (collectionData as List).length >= itemId) {
        collectionData.removeAt(itemId);
      } else {
        throw const StorageDatabaseException('Undefined item id');
      }
    } else {
      throw const StorageDatabaseException(
        'This Collection doesn\'t support collections',
      );
    }

    await set(collectionData, keepData: false);
    if (log) {
      for (String streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }
    return true;
  }

  Stream<Map<dynamic, StorageCollection>> streamDocs() =>
      stream().asyncExpand<Map<dynamic, StorageCollection>>((data) async* {
        if (data != null) yield getMapCollections(data);
      });

  Future<Map<dynamic, StorageCollection>> getCollections() async =>
      getMapCollections(await get());

  Map<dynamic, StorageCollection> getMapCollections(var data) {
    List docsIds;

    if (_isMap(data)) {
      docsIds = data.keys.toList();
    } else if (_isList(data)) {
      docsIds = [for (int i = 0; i < data.length; i++) i];
    } else {
      throw StorageDatabaseException(
        "This collection ($collectionId) does not support collections",
      );
    }

    Map<dynamic, StorageCollection> collections = {};

    for (dynamic collectionId in docsIds) {
      collections[collectionId] = StorageCollection(
        storageDatabase,
        collectionId,
        parent: this,
      );
    }

    return collections;
  }
}
