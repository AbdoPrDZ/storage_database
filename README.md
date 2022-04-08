
# Getting started


## Importing:
```dart
import 'package:storage_database/storage_database.dart';
import 'package:storage_database/defualt_storage_source.dart';
import 'package:storage_database/storage_database_collection.dart';
import 'package:storage_database/storage_database_document.dart';
```

## Initializing:
```dart
// You have to give source class extended by 'StorageDatabaseSource'
// Defualt source is 'DefualtStorageSource' class
StorageDatabase storage = await StorageDatabase.getInctance(); 
// In this example you should to create source class extended with 'StorageDatabaseSource'
StorageDatabase storageEx2 = StorageDatabase(await MyStorageSourceClass.getInctance());
```

## SourceClass:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_data bease/src/storage_database_source.dart';

class MyStorageSourceClass extends StorageDatabaseSource {
  final SharedPreferences storage;

  MyStorageSourceClass(this.storage) {
    // you sould be to create all this functions
    setdata = _setdata ;
    getdata = _getdata ;
    containsKey = _containsKey;
    clear = storage.clear; // clear function
    remove = _remove;
  }

  // initializing function
  static Future<MyStorageSourceClass> getInstance() async =>
      MyStorageSourceClass(await SharedPreferences.getInstance());

  // setting data function
  Future<bool> _setdata (String id, dynamic data ) async {
    data = jsonEncode(data );
    return storage.setString(id, data );
  }

  // getting data function
  dynamic _getdata (String id) {
    String? data = storage.getString(id);
    if (data != null) {
      return jsonDecode(data );
    } else {
      return null;
    }
  }

  // check for id function
  bool _containsKey(String key) => storage.containsKey(key);

  // remove function
  Future<bool> _remove(String id) async => await storage.remove(id);
}
```

## Create Collection:
```dart
storage.collection("collection-1").set("any data && any type"); // c-1
storage.collection("collection-1").set("any new data but some type"); // c-2
```

## Create Document into Collection:
```dart
// Map data : 
storage.collection("collection-2") // c-3
       .document("documentId").set({'item 1': 'data 1', 'item 2': 'data 2'}); // d-1
storage.collection("collection-2")
       .document("documentId").set({'item 3': 'data 3'}); // d-2
storage.collection("collection-2")
       .document("documentId").set({'item 4': 'data 4'}, keep = false); // d-3
// List data :
storage.collection("collection-3") 
       .document("documentId").set(["item 1", "item 2"]); // d-4
storage.collection("collection-3")
       .document("documentId").set(['item 3']); // d-5
storage.collection("collection-3")
       .document("documentId").set(["item 4"], keep = false); // d-6
```

## Getting Collection data :
```dart
storage.collection("collection-1").get(); // c-1 => 'any data && any type'
storage.collection("collection-1").get(); // c-2 => 'any data but some type'
storage.collection("collection-2").get(); // c-3 => {"documentId": {'item 1': 'data 1', 'item 2': 'data 2'}}
```

## Getting Document data :
```dart
//// Map:
storage.collection("collection-2").document("documentId").get()
// d-1 => {'item 1': 'data 1', 'item 2': 'data 2'}
storage.collection("collection-2").document("documentId").get()
// d-2 => {'item 1': 'data 1', 'item 2': 'data 2', 'item 3': 'data 3'}
storage.collection("collection-2").document("documentId").get()
// d-3 => {'item 4': 'data 4'}

//// List: 
storage.collection("collection-3").document("documentId").get()
// d-4 => ['item 1', 'item 2']
storage.collection("collection-3").document("documentId").get()
// d-5 => ['item 1', 'item 2', 'item 3']
storage.collection("collection-3").document("documentId").get()
// d-6 => ['item 4']
```

## Deleteing data:
```dart
// delete collection
storage.collection("testCollection").delete();
// delete document
storage.collection("testCollection").document("testDocument").delete();
// delete item from collection
storage.collection("testCollection").deleteItem("testDocument");
// delete item from document
storage.collection("testCollection").document("testDocument").deleteItem("testDocument");
// note: 'delteItem' working with only with map and list type
```

## Getting Document using document path:
```dart
StorageDocument document1 =  storage.collection('collection-2').document('documentId/item 1');
StorageDocument document2 =  storage.document('collection-3/documentId');
```

## Working with stream:
```dart
List documentData = [];
int itemIndex = 0;
String lastItem = "";
Column(
  children: [
    StreamBuilder(
      stream: storage.collection("collection-3").document("documentId").stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.data != null) {
            documentData = snapshot.data!;
          }
          return SingleChildScrollView(
            child: Column(
              children: List.generate(
                documentData.length,
                (index) => Text(
                  documentData[index].toString(),
                ),
              ),
            ),
          );
        }
      }
    ),
    ElevatedButton(
      onPressed: () {
        itemIndex += 1;
        lastItem = "item $itemIndex";
        storage.collection("collection-3").document("documentId").set([lastItem]);
      },
      child: const Text("Add item"),
    ),
    ElevatedButton(
      onPressed: () {
        storage.collection("collection-3").document("documentId").deleteItem(lastChat);
        itemIndex -= 1;
        lastItem = "item $itemIndex";
      },
      child: const Text("Remove item"),
    ),
  ],
);
```

# Contact Us:
### [GitHub Profile]("https://github.com/AIabdoPr")

### [Facebook Account]("https://www.facebook.com/profile.php?id=100008024286034")
