import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import './storage_database.dart';
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
        parent!.set({}, stream: false);
        parent = parent!.collection(items[i]);
      }

      collectionId = items.last;
    }
  }

  bool _cacheLoaded = false;
  dynamic _cache;

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

  dynamic _decodeRefs(dynamic data) {
    if (data is Map) {
      for (var key in data.keys) {
        data[key] = _decodeRefs(data[key]);
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        data[i] = _decodeRefs(data[i]);
      }
    } else if (data is StorageCollection) {
      data = data.ref;
    } else if (data is StorageModel) {
      data = data.ref ?? data.map;
    }

    return data;
  }

  Future set(dynamic data, {bool stream = true, bool keepData = true}) async {
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

    if (stream) {
      for (var streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }

    collectionData = _decodeRefs(collectionData);

    if (parent != null) {
      await parent!.set({collectionId: collectionData});
    } else {
      await storageDatabase.source.setData(collectionId, collectionData);
    }

    _cache = collectionData;
    _cacheLoaded = true;
  }

  Future<bool> get exists {
    if (parent != null) {
      return parent!.hasCollectionId(collectionId);
    } else {
      return storageDatabase.hasCollectionId(collectionId);
    }
  }

  Future<dynamic> _encodeRefs(dynamic data) async {
    if (data is Map) {
      for (var key in data.keys) {
        data[key] = await _encodeRefs(data[key]);
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        data[i] = await _encodeRefs(data[i]);
      }
    } else if (data is String && data.startsWith("ref:")) {
      String refId = data.substring(4);
      StorageCollection collection = storageDatabase.collection(refId);
      await collection.get();
      data = collection;
    }

    return data;
  }

  Future<dynamic> get({String? streamId}) async {
    if (!await exists) {
      throw StorageDatabaseException(
        "This collection ($collectionId) has not yet been created",
      );
      // await set({}, stream: false, keepData: false);
      // _cache = {};
    }

    dynamic collectionData = (parent != null
        ? (await parent!.get())[collectionId]
        : await storageDatabase.source.getData(collectionId));

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    collectionData = await _encodeRefs(collectionData);
    _cache = collectionData;
    _cacheLoaded = true;

    return collectionData;
  }

  dynamic getSync({String? streamId}) {
    if (!_cacheLoaded) {
      throw StorageDatabaseException(
        "Cache is not loaded. Call get() method first.",
      );
    }

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return _cache;
  }

  Future<dynamic> getItem(dynamic docId, {String? streamId}) async {
    final data = await get();

    dynamic item;

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    if (data is Map) {
      item = data[docId];
    } else if (data is List) {
      if (docId is! int) {
        throw const StorageDatabaseException("docId must be integer");
      }
      item = data[docId];
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }

    return item;
  }

  dynamic getItemSync(dynamic docId, {String? streamId}) {
    if (!_cacheLoaded) {
      throw StorageDatabaseException(
        "Cache is not loaded. Call get() method first.",
      );
    }

    dynamic item;

    if (_cache is Map) {
      item = _cache[docId];
    } else if (_cache is List) {
      if (docId is! int) {
        throw const StorageDatabaseException("docId must be integer");
      }
      item = _cache[docId];
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return item;
  }

  Future<dynamic> getItemWhere(
    bool Function(dynamic) where, {
    String? streamId,
  }) async {
    final data = await get(streamId: streamId);
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

  dynamic getItemWhereSync(bool Function(dynamic) where, {String? streamId}) {
    if (!_cacheLoaded) {
      throw StorageDatabaseException(
        "Cache is not loaded. Call get() method first.",
      );
    }

    dynamic item;

    if (_cache is Map) {
      item = _cache.entries.firstWhere((entry) => where(entry.value));
    } else if (_cache is List) {
      item = _cache.firstWhere(where);
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return item;
  }

  Future<MT> getAsModel<MT extends StorageModel>({String? streamId}) async {
    Object data = await get(streamId: streamId);

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return data.toModel<MT>();
  }

  MT getAsModelSync<MT extends StorageModel>({String? streamId}) {
    if (!_cacheLoaded) {
      throw StorageDatabaseException(
        "Cache is not loaded. Call get() method first.",
      );
    }

    if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
      storageListeners.getDate(path, streamId);
    }

    return _cache.toModel<MT>();
  }

  Future<List<MT>> getAsModels<MT extends StorageModel>({
    String? streamId,
  }) async {
    final data = await get(streamId: streamId);

    if (data is Map || data is List) {
      if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
        storageListeners.getDate(path, streamId);
      }

      return data.toListModel<MT>();
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  List<MT> getAsModelsSync<MT extends StorageModel>({String? streamId}) {
    if (!_cacheLoaded) {
      throw StorageDatabaseException(
        "Cache is not loaded. Call get() method first.",
      );
    }

    if (_cache is Map || _cache is List) {
      if (streamId != null && storageListeners.hasStreamId(path, streamId)) {
        storageListeners.getDate(path, streamId);
      }
      return _cache.toListModel<MT>();
    } else {
      throw StorageDatabaseException(
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  String get path =>
      parent != null ? "${parent!.path}/$collectionId" : collectionId;

  String get ref => "ref:$path";

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
        "This Collection ($collectionId) does not support collections",
      );
    }
  }

  StorageCollection collection(String collectionId) =>
      StorageCollection(storageDatabase, collectionId, parent: this);

  String get randomStreamId => String.fromCharCodes(
    List.generate(8, (index) => Random().nextInt(33) + 89),
  );

  Stream stream({
    Duration delayCheck = const Duration(milliseconds: 50),
  }) async* {
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
    Duration delayCheck = const Duration(milliseconds: 50),
  ]) => stream(delayCheck: delayCheck).asyncExpand<MT>((data) async* {
    if (data != null) yield data.toModel<MT>();
  });

  Stream<List<MT>> streamAsModels<MT extends StorageModel>([
    bool Function(MT)? where,
    Duration delayCheck = const Duration(milliseconds: 50),
  ]) => stream(delayCheck: delayCheck).asyncExpand<List<MT>>((data) async* {
    if (data != null) {
      if (data is Map) {
        List<MT> items = data.toListModel<MT>();
        if (where != null) {
          items = items.where(where).toList();
        }
        yield items;
      } else if (data is List) {
        List<MT> items = data.toModels<MT>();
        if (where != null) {
          items = items.where(where).toList();
        }
        yield items;
      }
    }
  });

  Future<bool> delete({bool stream = true}) async {
    bool res = parent != null
        ? await parent!.deleteItem(collectionId)
        : await storageDatabase.source.remove(collectionId);

    if (stream) {
      for (String streamId in storageListeners.getPathStreamIds(path)) {
        if (storageListeners.hasStreamId(path, streamId)) {
          storageListeners.setDate(path, streamId);
        }
      }
    }

    return res;
  }

  Future<bool> deleteItem(itemId, {bool stream = true}) async {
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
    if (stream) {
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

  @override
  String toString() =>
      'col:$path ${_cacheLoaded ? "{${_cache.entries.map((entry) => '${entry.key}: ${entry.value ?? '?'}').join(', ')}}" : "ref:$path"}';
}
