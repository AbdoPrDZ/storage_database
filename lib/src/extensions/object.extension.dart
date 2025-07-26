import '../../storage_collection.dart';
import '../storage_database_exception.dart';

extension StorageModelExtension on Object {
  MT toModel<MT extends StorageModel>([String? type]) =>
      StorageModelRegister.encode(
        this is StorageCollection
            ? (this as StorageCollection).getSync()
            : this,
      );

  List<MT> toListModel<MT extends StorageModel>([String? type]) {
    if (this is List) {
      return (this as List).map((e) => e.toModel<MT>(type)).toList()
          as List<MT>;
    } else if (this is Map) {
      return (this as Map).values
          .map((e) => (e as Object).toModel<MT>(type))
          .toList();
    } else {
      throw StorageDatabaseException('Data is not a List or Map');
    }
  }
}
