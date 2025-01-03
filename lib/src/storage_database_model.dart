import '../storage_database.dart';
import 'extensions/list.extension.dart';
import 'storage_database_exception.dart';

abstract class StorageModel {
  final String? id;

  const StorageModel({
    this.id,
  });

  Map toMap();

  String? get collectionId => StorageModelRegister.getCollectionId(runtimeType);

  String? get path =>
      collectionId != null && id != null ? '$collectionId/$id' : null;

  DateTime? get createdAt => map['created_at'] != null
      ? DateTime.parse(map['created_at'] as String)
      : null;

  DateTime? get updatedAt => map['updated_at'] != null
      ? DateTime.parse(map['updated_at'] as String)
      : null;

  Map get map => {'id': id, ...toMap()};

  Stream<MT> stream<MT extends StorageModel>([
    delayCheck = const Duration(milliseconds: 50),
  ]) =>
      StorageDatabase.instance.collection(path!).streamAsModel<MT>(delayCheck);

  Future save({bool log = true}) async {
    if (collectionId == null) {
      throw StorageDatabaseException(
        'Collection ID is not set',
      );
    }

    await StorageDatabase.instance.collection(collectionId!).set({}, log: log);

    final map = this.map;

    if (map['id'] == null) {
      map['id'] = await nextId(runtimeType);
    }

    if (map.containsKey('created_at') && map['created_at'] == null) {
      map['created_at'] = DateTime.now().toIso8601String();
    }

    if (map.containsKey('updated_at')) {
      map['updated_at'] = DateTime.now().toIso8601String();
    }

    await StorageDatabase.instance
        .collection(collectionId!)
        .collection(map['id'].toString())
        .set(map, log: log);
  }

  Future<bool> delete({bool log = true}) async {
    if (collectionId == null) {
      throw StorageDatabaseException(
        'Collection ID is not set',
      );
    }

    if (id == null) {
      throw StorageDatabaseException(
        'ID is not set',
      );
    }

    return await StorageDatabase.instance.collection(path!).delete(log: log);
  }

  operator [](String key) => map[key];

  @override
  operator ==(Object other) =>
      other is StorageModel && other.id == id && other.map == map;

  @override
  int get hashCode => id.hashCode ^ map.hashCode;

  @override
  String toString() =>
      '#${collectionId ?? '?'}/${id ?? '?'} $runtimeType{\n${map.entries.map(
            (entry) => '  ${entry.key}: ${entry.value ?? '?'},\n',
          ).join()}}';

  static Future<String> nextId<MT extends StorageModel>([Type? type]) async {
    final collectionId = StorageModelRegister.getCollectionId<MT>(type);

    if (collectionId == null) {
      throw StorageDatabaseException(
        'Collection ID is not set',
      );
    }

    final data = await StorageDatabase.instance.collection(collectionId).get();

    if (data == null) return '1';

    if (data is Map) {
      final id = data.keys.fold(0, (value, key) {
            final idInt = int.tryParse(key.toString());

            if (idInt != null && idInt > value) {
              return idInt;
            }

            return value;
          }) +
          1;
      return "$id";
    } else if (data is List) {
      return "${data.length + 1}";
    } else {
      throw StorageDatabaseException(
        'Data is not a Map or List',
      );
    }
  }

  static Future<List<MT>> allwhere<MT extends StorageModel>([
    bool Function(dynamic)? where,
  ]) async {
    final collectionId = StorageModelRegister.getCollectionId<MT>();

    if (collectionId == null) {
      throw StorageDatabaseException(
        'Collection ID is not set',
      );
    }

    final data = await StorageDatabase.instance.collection(collectionId).get();

    if (data == null) {
      return [];
    }

    List<dynamic> founds;

    if (data is Map) {
      founds = where != null
          ? data.values.where(where).toList()
          : data.values.toList();
    } else if (data is List) {
      founds = where != null ? data.where(where).toList() : data;
    } else {
      throw StorageDatabaseException(
        'Data is not a Map or List',
      );
    }

    return founds
        .map((found) => StorageModelRegister.encode<MT>(found))
        .toList();
  }

  static Future<List<MT>> all<MT extends StorageModel>() => allwhere<MT>();

  static Stream<List<MT>> streamAll<MT extends StorageModel>([
    delayCheck = const Duration(milliseconds: 50),
  ]) {
    final collectionId = StorageModelRegister.getCollectionId<MT>();

    if (collectionId == null) {
      throw StorageDatabaseException(
        'Collection ID is not set',
      );
    }

    return StorageDatabase.instance
        .collection(collectionId)
        .streamAsModels<MT>(delayCheck);
  }

  static Future<MT?> findWhere<MT extends StorageModel>(
    bool Function(dynamic) where,
  ) async =>
      (await allwhere<MT>(where)).firstOrNull;

  static Future<MT?> findBy<MT extends StorageModel>(
    dynamic value,
    String key,
  ) =>
      findWhere<MT>((element) => element[key] == value);

  static Future<MT?> find<MT extends StorageModel>(
    String id,
  ) =>
      findWhere<MT>(
        (element) => element['id'] == id,
      );

  static Future<int> deleteWhere<MT extends StorageModel>(
    bool Function(dynamic) where,
  ) async {
    int count = 0;

    for (final item in await allwhere<MT>(where)) {
      if (await item.delete()) count++;
    }

    return count;
  }

  static Future<int> deleteBy<MT extends StorageModel>(
    dynamic value,
    String key,
  ) =>
      deleteWhere<MT>((element) => element[key] == value);
}

class StorageModelRegister {
  final StorageModel Function(dynamic data) encoder;
  final String? collectionId;

  const StorageModelRegister({
    required this.encoder,
    this.collectionId,
  });

  static final Map<String, StorageModelRegister> _encoders = {};

  static void register<MT extends StorageModel>(
    StorageModel Function(dynamic data) encoder, [
    String? collectionId,
  ]) =>
      _encoders[MT.toString()] = StorageModelRegister(
        encoder: encoder,
        collectionId: collectionId,
      );

  static MT encode<MT extends StorageModel>(dynamic data) {
    if (!_encoders.containsKey("$MT")) {
      throw StorageDatabaseException(
        'No encoder found for type: $MT',
      );
    }

    return _encoders["$MT"]!.encoder(data) as MT;
  }

  static String? getCollectionId<MT extends StorageModel>([Type? type]) =>
      _encoders["${type ?? MT}"]?.collectionId;
}
