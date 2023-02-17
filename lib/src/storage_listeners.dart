import 'dart:developer';

class StorageListeners {
  StorageListeners();

  Map listenersData = {};

  List<String> getPathStreamIds(String path) =>
      List<String>.from(listenersData[path]?.keys.toList() ?? []);

  bool hasStreamId(String path, String streamId) {
    try {
      return listenersData.containsKey(path) &&
          listenersData[path].containsKey(streamId);
    } catch (e) {
      log("has stream id: $e");
      return false;
    }
  }

  initStream(String path, String streamId) {
    if (listenersData[path] == null) listenersData[path] = {};
    listenersData[path][streamId] = {"set_date": 1, "get_date": 0};
  }

  int setDate(String path, String streamId, {int? microseconds}) {
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    listenersData[path][streamId]["set_date"] = microsecondsSinceEpoch;
    return microsecondsSinceEpoch;
  }

  int getDate(String path, String streamId, {int? microseconds}) {
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    listenersData[path][streamId]["get_date"] = microsecondsSinceEpoch;
    return microsecondsSinceEpoch;
  }

  Map getDates(String path, String streamId) {
    return listenersData[path][streamId];
  }
}
