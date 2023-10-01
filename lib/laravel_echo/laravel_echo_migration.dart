import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:laravel_echo_null/laravel_echo_null.dart';
import 'package:storage_database/storage_collection.dart';

import '../src/storage_database_values.dart';

abstract class LaravelEchoMigration extends StorageCollection {
  LaravelEchoMigration(super.storageDatabase, super.collectionId);

  String get migrationName => runtimeType.toString();

  String get itemName => migrationName;

  String indexName = 'id';

  Channel get channel;

  Map<EventsType, String> get eventsNames => {
        EventsType.create: '${migrationName}CreatedEvent',
        EventsType.update: '${migrationName}UpdatedEvent',
        EventsType.delete: '${migrationName}DeletedEvent',
      };

  @mustCallSuper
  setup() {
    if (eventsNames.containsKey(EventsType.create)) {
      channel.listen(
        eventsNames[EventsType.create]!,
        onCreate,
      );
    }
    if (eventsNames.containsKey(EventsType.update)) {
      channel.listen(
        eventsNames[EventsType.update]!,
        onUpdate,
      );
    }
    if (eventsNames.containsKey(EventsType.delete)) {
      channel.listen(
        eventsNames[EventsType.delete]!,
        onDelete,
      );
    }
  }

  @mustCallSuper
  onCreate(Map data) async {
    Map item = data[itemName] ?? {};
    await collection(item[indexName].toString()).set(item, keepData: false);
  }

  @mustCallSuper
  onUpdate(Map data) async {
    Map item = data[itemName] ?? {};
    await collection(item[indexName].toString()).set(item, keepData: false);
  }

  @mustCallSuper
  onDelete(Map data) async {
    var id = data['id'] ?? -1;
    try {
      await deleteItem(id.toString());
    } catch (e) {
      log('MigrationError[$migrationName]: Cant delete item $id.\n error: "$e"');
    }
  }
}
