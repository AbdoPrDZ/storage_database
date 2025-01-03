import '../../storage_collection.dart';

extension ListExtension<E> on List<E> {
  /// Converts the list to a list of [MT]s.
  ///
  /// Example:
  /// ```dart
  /// class Person extends StorageModel {
  ///   final String name;
  ///   final int age;
  ///
  ///   Person({required this.name, required this.age});
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
