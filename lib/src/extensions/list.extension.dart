import '../../storage_collection.dart';

extension ListExtension<E> on List<E> {
  /// Converts the list to a list of [MT]s.
  ///
  /// ## Example:
  /// ```dart
  /// class Person extends StorageModel {
  ///   final String name;
  ///   final int age;
  ///
  ///   Person({super.id, required this.name, required this.age});
  ///
  ///   @override
  ///   Map<String, dynamic> toMap() => {'name': name, 'age': age};
  /// }
  ///
  /// StorageModel.register<Person>(() => Person(name: '', age: 0));
  ///
  /// final list = [
  ///   {'name': 'John', 'age': 30},
  ///   {'name': 'Doe', 'age': 25},
  /// ];
  ///
  /// final models = list.toModels<Person>();
  ///
  /// print(models[0].name); // John
  /// print(models[0].age); // 30
  /// print(models[1].name); // Doe
  /// print(models[1].age); // 25
  /// ```
  ///
  /// ## Output:
  /// ```shell
  /// John
  /// 30
  /// Doe
  /// 25
  /// ```
  MT toModel<MT extends StorageModel>(int index) =>
      StorageModelRegister.encode<MT>(this[index]);

  List<MT> toModels<MT extends StorageModel>() => [
    for (var item in this) StorageModelRegister.encode<MT>(item),
  ];

  E? get firstOrNull => isNotEmpty ? first : null;

  E? firstWhereOrNull(bool Function(E element) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}

extension ListStorageModelExtension on List<StorageModel> {
  /// Saves all models in the list to the database.
  ///
  /// ## Example:
  /// ```dart
  /// final models = [
  ///   Person(name: 'John', age: 30),
  ///   Person(name: 'Doe', age: 25),
  /// ];
  ///
  /// await models.save();
  /// ```
  Future save() async {
    for (final item in this) {
      await item.save();
    }
  }

  /// Gets a list of references from the models in the list.
  ///
  /// ## Example:
  /// ```dart
  /// final models = [
  ///   Person(id: '1', name: 'John', age: 30),
  ///   Person(id: '2', name: 'Doe', age: 25),
  /// ];
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
    for (final item in this)
      if (item.ref != null) item.ref!,
  ];

  /// Gets a list of IDs from the models in the list.
  ///
  /// ## Example:
  /// ```dart
  /// final models = [
  ///   Person(id: '1', name: 'John', age: 30),
  ///   Person(id: '2', name: 'Doe', age: 25),
  /// ];
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
    for (final item in this)
      if (item.id != null) item.id!,
  ];

  /// Converts the list of models to a list of maps.
  ///
  /// ## Example:
  /// ```dart
  /// final models = [
  ///   Person(id: '1', name: 'John', age: 30),
  ///   Person(id: '2', name: 'Doe', age: 25),
  /// ];
  /// final maps = models.map;
  /// print(maps); // [{'id': '1', 'name': 'John', 'age': 30}, {'id': '2', 'name': 'Doe', 'age': 25}]
  /// ```
  ///
  /// ## Output:
  /// ```shell
  /// [{'id': '1', 'name': 'John', 'age': 30}, {'id': '2', 'name': 'Doe', 'age': 25}]
  /// ```
  List<Map> getMap() => [for (final item in this) item.map];
}
