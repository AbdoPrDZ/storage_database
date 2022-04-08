import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'src/storage_database_source.dart';

class DefualtStorageSource extends StorageDatabaseSource {
  final SharedPreferences storage;

  DefualtStorageSource(this.storage) {
    setData = _setData;
    getData = _getData;
    containsKey = _containsKey;
    clear = storage.clear;
    remove = _remove;
  }

  static Future<DefualtStorageSource> getInstance() async =>
      DefualtStorageSource(await SharedPreferences.getInstance());

  Future<bool> _setData(String id, dynamic data) async {
    data = jsonEncode(data);
    return storage.setString(id, data);
  }

  dynamic _getData(String id) {
    String? data = storage.getString(id);
    if (data != null) {
      return jsonDecode(data);
    } else {
      return null;
    }
  }

  bool _containsKey(String key) => storage.containsKey(key);

  Future<bool> _remove(String id) async => await storage.remove(id);
}
