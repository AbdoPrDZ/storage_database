import '../../storage_collection.dart';

extension StorageModelExtension on Object {
  MT toModel<MT extends StorageModel>({String? type}) =>
      StorageModelRegister.encode(this);
}
