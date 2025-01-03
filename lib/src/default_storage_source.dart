import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'storage_database_source.dart';

class DefaultStorageSource extends StorageDatabaseSource {
  final SharedPreferences storage;

  const DefaultStorageSource(this.storage);

  static Future<DefaultStorageSource> get instance async =>
      DefaultStorageSource(await SharedPreferences.getInstance());

  @override
  Future<bool> setData(String id, dynamic data) =>
      storage.setString(id, jsonEncode(data));

  @override
  Future<dynamic> getData(String id) async {
    String? data = storage.getString(id);

    if (data != null) {
      return jsonDecode(data);
    } else {
      return null;
    }
  }

  @override
  Future<bool> containsKey(String id) async => storage.containsKey(id);

  @override
  Future<bool> remove(String id) async => await storage.remove(id);

  @override
  Future<bool> clear() async => await storage.clear();
}
