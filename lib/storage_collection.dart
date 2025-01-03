import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import './storage_database.dart';
import 'src/extensions/object.extension.dart';
import 'src/storage_database_exception.dart';
import 'src/storage_listeners.dart';

export 'src/storage_database_model.dart';

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

  Future<dynamic> _checkType(var data) async {
    if (!await exists) {
      var initialData = data is Map
          ? {}
          : data is List
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
        } else if (data is Map) {
          Map.from(collectionData);
          currentType = true;
        } else if (data is List) {
          List.from(collectionData);
          currentType = true;
        } else {
          currentType = collectionData.runtimeType == data.runtimeType;
        }
      } catch (e) {
        dev.log(
          "[StorageDatabase.StorageCollection] - collection check type: $e",
        );
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

  Future set(dynamic data, {bool log = true, bool keepData = true}) async {
    dynamic newData;

    if (data is StorageModel) {
      newData = data.map;
    } else if (data is List<StorageModel>) {
      newData = [for (var item in data) item.map];
    } else {
      newData = data;
    }

    dynamic collectionData;
    if (!keepData) {
      collectionData = newData;
    } else {
      collectionData = await _checkType(newData);
      if (newData is Map) {
        collectionData ??= {};
        for (var key in newData.keys) {
          collectionData[key] = newData[key];
        }
      } else if (newData is List) {
        collectionData ??= [];
        for (var item in newData) {
          if (!collectionData.contains(item)) collectionData.add(item);
        }
      } else {
        collectionData = newData;
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

  Future<bool> get exists {
    if (parent != null) {
      return parent!.hasCollectionId(collectionId);
    } else {
      return storageDatabase.hasCollectionId(collectionId);
    }
  }

  Future<dynamic> get({String? streamId}) async {
    if (!await exists) {
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

  Future<dynamic> getItem(dynamic docId) async {
    final data = await get();
    if (data is Map) {
      return data[docId];
    } else if (data is List) {
      if (docId is! int) {
        throw const StorageDatabaseException("docId must be integer");
      }
      return data[docId];
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  Future<dynamic> getItemWhere(bool Function(dynamic) where) async {
    final data = await get();
    if (data is Map) {
      return data.entries.firstWhere((entry) => where(entry.value));
    } else if (data is List) {
      return data.firstWhere(where);
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  Future<MT> getAsModel<MT extends StorageModel>({
    String? streamId,
  }) async {
    Object data = await get(streamId: streamId);
    return data.toModel<MT>();
  }

  Future<List<MT>> getAsModels<MT extends StorageModel>({
    String? streamId,
  }) async {
    final data = await get(streamId: streamId);

    if (data is Map) {
      return [for (Object item in data.values) item.toModel<MT>()];
    } else if (data is List) {
      return [for (Object item in data) item.toModel<MT>()];
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  String get path => collectionId;

  Future<bool> hasCollectionId(dynamic collectionId) async {
    final data = await get();

    if (data is Map) {
      return data.containsKey(collectionId);
    } else if (data is List) {
      if (collectionId is! int) {
        throw const StorageDatabaseException("collectionId must be integer");
      }

      return data.length <= collectionId;
    } else {
      throw StorageDatabaseException(
        "This Collection ($this.collectionId) does not support collections",
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

  Stream<MT> streamAsModel<MT extends StorageModel>([
    delayCheck = const Duration(milliseconds: 50),
  ]) =>
      stream(delayCheck: delayCheck).asyncExpand<MT>((data) async* {
        if (data != null) yield data.toModel<MT>();
      });

  Stream<List<MT>> streamAsModels<MT extends StorageModel>([
    delayCheck = const Duration(milliseconds: 50),
  ]) =>
      stream(delayCheck: delayCheck).asyncExpand<List<MT>>((data) async* {
        if (data != null) {
          if (data is Map) {
            yield [for (Object item in data.values) item.toModel<MT>()];
          } else if (data is List) {
            yield [for (Object item in data) item.toModel<MT>()];
          }
        }
      });

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

    if (collectionData is Map) {
      if (collectionData.containsKey(itemId)) {
        collectionData.remove(itemId);
      } else {
        throw const StorageDatabaseException('Undefined item id');
      }
    } else if (collectionData is List) {
      if (itemId >= 0 && collectionData.length >= itemId) {
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

    if (data is Map) {
      docsIds = data.keys.toList();
    } else if (data is List) {
      docsIds = [for (int i = 0; i < data.length; i++) i];
    } else {
      throw StorageDatabaseException(
        "This collection ($collectionId) does not support collections",
      );
    }

    Map<dynamic, StorageCollection> collections = {};

    for (final collectionId in docsIds) {
      collections[collectionId] = StorageCollection(
        storageDatabase,
        collectionId,
        parent: this,
      );
    }

    return collections;
  }
}
