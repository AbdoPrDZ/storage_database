import 'dart:convert';

import '../storage_database.dart';

class StorageListeners {
  StorageDatabase storageDatabase;

  StorageListeners(this.storageDatabase) {
    if (!storageDatabase.source.containsKey('listeners')) {
      storageDatabase.source.setData("listeners", "{}");
    }
  }

  Map getListenersData() => jsonDecode(
        storageDatabase.source.getData("listeners") ?? "{}",
      );

  Future<bool> setListenersData(Map data) => storageDatabase.source.setData(
        "listeners",
        jsonEncode(data),
      );

  bool hasStreamId(String streamId) {
    try {
      Map listenersData = getListenersData();
      return listenersData.containsKey(streamId);
    } catch (e) {
      print("has stream id: $e");
      return false;
    }
  }

  initStream(String streamId) {
    Map listenersData = getListenersData();
    listenersData[streamId] = {"set_date": 1, "get_date": 0};
    setListenersData(listenersData);
  }

  setDate(String streamId) {
    Map listenersData = getListenersData();
    listenersData[streamId]["set_date"] = DateTime.now().millisecondsSinceEpoch;
    setListenersData(listenersData);
  }

  getDate(String streamId) {
    Map listenersData = getListenersData();
    listenersData[streamId]["get_date"] = DateTime.now().millisecondsSinceEpoch;
    setListenersData(listenersData);
  }

  Map getDates(String streamId) => getListenersData()[streamId];
}
