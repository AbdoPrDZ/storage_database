import '../storage_database_model.dart';

extension MapExtension<K, V> on Map<K, V> {
  /// Returns the first element that satisfies the given [test], or `null` if
  /// there is none.
  V? firstWhereOrNull(bool Function(V element) where) {
    try {
      return values.firstWhere(where);
    } catch (e) {
      return null;
    }
  }

  Map<String, MT> toModels<MT extends StorageModel>() => {
    for (final entry in entries)
      entry.key.toString(): StorageModelRegister.encode<MT>(entry.value),
  };
}

extension MapStorageModelExtension on Map<String, StorageModel> {
  /// Saves all models in the list to the database.
  ///
  /// ## Example:
  /// ```dart
  /// final models = {
  ///   '1': Person(id: '1', name: 'John', age: 30),
  ///   '2': Person(id: '2', name: 'Doe', age: 25),
  /// };
  ///
  /// await models.save();
  /// ```
  Future save() async {
    for (final item in values) {
      await item.save();
    }
  }

  /// Gets a list of references from the models in the list.
  ///
  /// ## Example:
  /// ```dart
  /// final models = {
  ///   '1': Person(id: '1', name: 'John', age: 30),
  ///   '2': Person(id: '2', name: 'Doe', age: 25),
  /// };
  ///
  /// final refs = models.refs;
  /// print(refs); // ['ref:person/1', 'ref:person/2']
  /// ```
  ///
  /// ## Output:
  /// ```shell
  /// ['ref:person/1', 'ref:person/2']
  /// ```
  List<String> get refs => [
    for (final item in values)
      if (item.ref != null) item.ref!,
  ];

  /// Gets a list of IDs from the models in the list.
  ///
  /// ## Example:
  /// ```dart
  /// final models = {
  ///   '1': Person(id: '1', name: 'John', age: 30),
  ///   '2': Person(id: '2', name: 'Doe', age: 25),
  /// };
  ///
  /// final ids = models.ids;
  /// print(ids); // ['1', '2']
  /// ```
  ///
  /// ## Output:
  /// ```shell
  /// ['1', '2']
  /// ```
  List<String> get ids => [
    for (final item in values)
      if (item.id != null) item.id!,
  ];

  /// Converts the map of models to a map of maps.
  ///
  /// ## Example:
  /// ```dart
  /// final models = {
  ///   '1': Person(id: '1', name: 'John', age: 30),
  ///   '2': Person(id: '2', name: 'Doe', age: 25),
  /// };
  /// final maps = models.map;
  /// print(maps); // {'1': {'id': '1', 'name': 'John', 'age': 30}, '2': {'id': '2', 'name': 'Doe', 'age': 25}}
  /// ```
  ///
  /// ## Output:
  /// ```shell
  /// {'1': {'id': '1', 'name': 'John', 'age': 30}, '2': {'id': '2', 'name': 'Doe', 'age': 25}}
  /// ```
  Map<String, Map> getMap() => {
    for (final entry in entries) entry.key: entry.value.map,
  };
}
