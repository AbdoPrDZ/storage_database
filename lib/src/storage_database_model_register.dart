import 'storage_database_exception.dart';
import 'storage_database_model.dart';

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
