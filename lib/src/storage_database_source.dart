abstract class StorageDatabaseSource {
  Future setData(String id, dynamic data);
  Future<dynamic> getData(String id);
  Future<bool> containsKey(String id);
  Future clear();
  Future remove(String id);
}
