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

  Map<EventsType, bool> isSetuped = {
    EventsType.create: false,
    EventsType.update: false,
    EventsType.delete: false,
  };

  @mustCallSuper
  setup() {
    if (!isSetuped[EventsType.create]! &&
        eventsNames.containsKey(EventsType.create)) {
      channel.listen(
        eventsNames[EventsType.create]!,
        onCreate,
      );
      isSetuped[EventsType.create] = true;
    } else if (!eventsNames.containsKey(EventsType.create)) {
      isSetuped[EventsType.create] = false;
    }
    if (!isSetuped[EventsType.update]! &&
        eventsNames.containsKey(EventsType.update)) {
      channel.listen(
        eventsNames[EventsType.update]!,
        onUpdate,
      );
      isSetuped[EventsType.update] = true;
    } else if (!eventsNames.containsKey(EventsType.update)) {
      isSetuped[EventsType.update] = false;
    }
    if (!isSetuped[EventsType.delete]! &&
        eventsNames.containsKey(EventsType.delete)) {
      channel.listen(
        eventsNames[EventsType.delete]!,
        onDelete,
      );
      isSetuped[EventsType.delete] = true;
    } else if (!eventsNames.containsKey(EventsType.delete)) {
      isSetuped[EventsType.delete] = false;
    }
  }

  @mustCallSuper
  onCreate(Map data) async {
    Map item = data[itemName] ?? {};
    await document(item[indexName].toString()).set(item, keepData: false);
  }

  @mustCallSuper
  onUpdate(Map data) async {
    Map item = data[itemName] ?? {};
    await document(item[indexName].toString()).set(item, keepData: false);
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
