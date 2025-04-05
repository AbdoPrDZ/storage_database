import 'dart:developer';

class StorageListeners {
  final Map _listenersData = {};

  List<String> getPathStreamIds(String path) =>
      List<String>.from(_listenersData[path]?.keys.toList() ?? []);

  bool hasStreamId(String path, String streamId) {
    try {
      return _listenersData.containsKey(path) &&
          _listenersData[path].containsKey(streamId);
    } catch (e) {
      log("[StorageDatabase.StorageListener.hasStreamId]: $e");
      return false;
    }
  }

  initStream(String path, String streamId) {
    if (_listenersData[path] == null) _listenersData[path] = {};
    _listenersData[path][streamId] = {"set_date": 1, "get_date": 0};
  }

  List<String> getPathParents(String path) {
    List<String> paths = [];
    if (_listenersData.containsKey(path.split('/').first)) {
      String lastPath = '';
      for (String item in path.split('/')) {
        lastPath = '${lastPath == '' ? '' : '$lastPath/'}$item';
        if (_listenersData.containsKey(lastPath)) paths.add(lastPath);
      }
    }
    return paths;
  }

  int setDate(String path, String streamId, {int? microseconds}) {
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    _listenersData[path][streamId]["set_date"] = microsecondsSinceEpoch;
    return microsecondsSinceEpoch;
  }

  int getDate(String path, String streamId, {int? microseconds}) {
    int microsecondsSinceEpoch =
        microseconds ?? DateTime.now().microsecondsSinceEpoch;
    _listenersData[path][streamId]["get_date"] = microsecondsSinceEpoch;
    return microsecondsSinceEpoch;
  }

  Map getDates(String path, String streamId) => _listenersData[path][streamId];
}
