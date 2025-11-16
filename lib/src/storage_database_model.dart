import '../storage_database.dart';
import 'storage_database_exception.dart';

export 'storage_database_model_register.dart';
export 'extensions/list.extension.dart';
export 'extensions/map.extension.dart';
export 'extensions/object.extension.dart';

abstract class StorageModel {
  dynamic id;

  StorageModel({this.id});

  Map toMap();

  String? get collectionId => StorageModelRegister.getCollectionId(runtimeType);

  String? get path =>
      collectionId != null && id != null ? '$collectionId/$id' : null;

  String? get ref => path != null ? "ref:$path" : null;

  Map get map => {'id': id, ...toMap()};

  Future<bool> exists([StorageDatabase? database]) async {
    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    if (id == null) {
      throw StorageDatabaseException('ID is not set');
    }

    return await (database ?? StorageDatabase.instance)
        .collection(path!)
        .exists;
  }

  Stream<MT> stream<MT extends StorageModel>([
    Duration delayCheck = const Duration(milliseconds: 50),
    StorageDatabase? database,
  ]) => (database ?? StorageDatabase.instance)
      .collection(path!)
      .streamAsModel<MT>(delayCheck);

  Future save([StorageDatabase? database]) async {
    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    database ??= StorageDatabase.instance;

    await database.collection(collectionId!).set({});

    final map = this.map;

    if (map['id'] == null) {
      map['id'] = await nextId(runtimeType);
    }

    await database
        .collection(collectionId!)
        .collection(map['id'].toString())
        .set(map);

    id = map['id'];
  }

  Future<bool> delete({bool log = true, StorageDatabase? database}) async {
    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    if (id == null) {
      throw StorageDatabaseException('ID is not set');
    }

    return await (database ?? StorageDatabase.instance)
        .collection(path!)
        .delete(stream: log);
  }

  operator [](String key) => map[key];

  @override
  operator ==(Object other) =>
      other is StorageModel && other.id == id && other.map == map;

  @override
  int get hashCode => id.hashCode ^ map.hashCode;

  @override
  String toString() =>
      '#${collectionId ?? '?'}/${id ?? '?'} $runtimeType{\n${map.entries.map((entry) => '  ${entry.key}: ${entry.value ?? '?'},\n').join()}}';

  static Future<String> nextId<MT extends StorageModel>([
    Type? type,
    StorageDatabase? database,
    String? collectionId,
  ]) async {
    collectionId ??= StorageModelRegister.getCollectionId<MT>(type);

    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    final data = await (database ?? StorageDatabase.instance)
        .collection(collectionId)
        .get();

    if (data == null) return '1';

    if (data is Map) {
      final id =
          data.keys.fold(0, (value, key) {
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
      throw StorageDatabaseException('Data is not a Map or List');
    }
  }

  static Future<List<MT>> allWhere<MT extends StorageModel>([
    bool Function(dynamic)? where,
    StorageDatabase? database,
  ]) async {
    final collectionId = StorageModelRegister.getCollectionId<MT>();

    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    final data = await (database ?? StorageDatabase.instance)
        .collection(collectionId)
        .get();

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
      throw StorageDatabaseException('Data is not a Map or List');
    }

    return founds
        .map((found) => StorageModelRegister.encode<MT>(found))
        .toList();
  }

  static Future<List<String>> allIds<MT extends StorageModel>() async {
    final collectionId = StorageModelRegister.getCollectionId<MT>();

    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    final data = await StorageDatabase.instance.collection(collectionId).get();

    if (data == null) return [];

    if (data is Map) {
      return List<String>.from(data.keys.toList());
    } else {
      throw StorageDatabaseException('Data is not a Map or List');
    }
  }

  static Future<List<MT>> all<MT extends StorageModel>() => allWhere<MT>();

  static Stream<List<MT>> streamAll<MT extends StorageModel>([
    bool Function(MT)? where,
    Duration delayCheck = const Duration(milliseconds: 50),
    StorageDatabase? database,
  ]) {
    final collectionId = StorageModelRegister.getCollectionId<MT>();

    if (collectionId == null) {
      throw StorageDatabaseException('Collection ID is not set');
    }

    return (database ?? StorageDatabase.instance)
        .collection(collectionId)
        .streamAsModels<MT>(where, delayCheck);
  }

  static Future<MT?> findWhere<MT extends StorageModel>(
    bool Function(dynamic) where,
  ) async => (await allWhere<MT>(where)).firstOrNull;

  static Future<MT?> findBy<MT extends StorageModel>(
    dynamic value,
    String key,
  ) => findWhere<MT>((element) => element[key] == value);

  static Future<MT?> find<MT extends StorageModel>(String id) =>
      findWhere<MT>((element) => element['id'] == id);

  static Future<int> deleteWhere<MT extends StorageModel>([
    bool Function(dynamic)? where,
  ]) async {
    int count = 0;

    for (final item in await allWhere<MT>(where)) {
      if (await item.delete()) count++;
    }

    return count;
  }

  static Future<int> deleteBy<MT extends StorageModel>(
    dynamic value,
    String key,
  ) => deleteWhere<MT>((element) => element[key] == value);
}
