class StorageDatabaseSource {
  late final Function(String id, dynamic data) setData;
  late final Function(String id) getData;
  late final Function(String id) containsKey;
  late final Function clear;
  late final Function remove;
}
