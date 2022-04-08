import './storage_database.dart';
import 'src/storage_database_excption.dart';
import 'src/storage_listeners.dart';

class StorageDocument {
  final StorageDatabase storageDatabase;
  final parrent;
  final String documentId, parrentId;
  final bool isCollection;
  final StorageListeners storageListeners;

  StorageDocument(
    this.storageDatabase,
    this.parrent,
    this.isCollection,
    this.parrentId,
    this.documentId,
    this.storageListeners,
  );

  Map getParrentData({bool log = true}) => parrent.get(log: log);

  checkType(Type dataType) {
    Map parrentData = getParrentData(log: false);
    bool isMap = dataType.toString().contains("Map");
    if (!parrentData.containsKey(documentId)) {
      parrent.set({documentId: isMap ? {} : []});
      return dataType.toString().contains("Map")
          ? {}
          : dataType.toString().contains("List")
              ? []
              : null;
    } else {
      var docData = parrentData[documentId];
      bool currectType = false;
      try {
        if (dataType.toString().contains("Map")) {
          Map.from(docData);
          currectType = true;
        } else if (dataType.toString().contains("List")) {
          List.from(docData);
          currectType = true;
        } else {
          currectType = docData.runtimeType == dataType;
        }
      } catch (e) {
        print("document check type: $e");
      }
      if (!currectType) {
        throw StorageDatabaseException(
          "The data type must be ${docData.runtimeType}",
        );
      }
      return docData;
    }
  }

  set(var data, {bool log = true, bool keepData = true}) {
    var docData = checkType(data.runtimeType);
    if (keepData &&
        (data.runtimeType.toString().contains("Map") ||
            data.runtimeType.toString().contains("List"))) {
      docData.addAll(data);
    } else {
      docData = data;
    }
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.setDate(getPath());
    }
    parrent.set({documentId: docData});
  }

  StorageDocument document(String docId) {
    try {
      Map.from(get(log: false));
    } catch (e) {
      print("document error $e");
      throw StorageDatabaseException(
        "This parrent doesn't support documents",
      );
    }
    List<String> docIds = docId.split("/");
    StorageDocument document = StorageDocument(
        storageDatabase, this, true, documentId, docIds[0], storageListeners);
    for (int i = 1; i < docIds.length; i++) {
      document.set({docIds[i - 1]: {}});
      document = document.document(docIds[i]);
    }
    return document;
  }

  get({bool log = true}) {
    Map parrentData = getParrentData(log: false);
    if (log && storageListeners.hasStreamId(getPath())) {
      storageListeners.getDate(getPath());
    }
    return parrentData[documentId];
  }

  delete({bool log = true}) {
    Map parrentData = getParrentData(log: false);
    parrentData.remove(documentId);
    parrent.set(parrentData);
    if (log) {
      storageListeners.setDate(getPath());
    }
  }

  deleteItem(itemId, {bool log = true}) {
    Map parrentData = getParrentData();
    parrentData[documentId].remove(itemId);
    parrent.set(parrentData, keepData: false);
    if (log) {
      storageListeners.setDate(getPath());
    }
  }

  String getPath() => "${parrent.getPath()}/$documentId";

  Stream stream() async* {
    storageListeners.initStream(getPath());
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));
      Map dates = storageListeners.getDates(getPath());
      if (dates["set_date"] > dates["get_date"]) {
        yield get();
      }
    }
  }
}
