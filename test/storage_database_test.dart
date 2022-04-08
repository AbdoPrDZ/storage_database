import 'package:flutter_test/flutter_test.dart';

import 'package:storage_database/storage_database.dart';

void main() {
  test("test storage database", () async {
    final StorageDatabase storageDatabase = await StorageDatabase.getInstance();
    storageDatabase.collection("test").set("data");
    storageDatabase.collection("test").stream().listen((event) {
      print(event);
    });
  });
  return;
  test(
    'test storage database',
    () async {
      final StorageDatabase storageDatabase =
          await StorageDatabase.getInstance();
      expect(
        storageDatabase.collection("testCollection").set("testDataString"),
        3,
      );
      expect(
        storageDatabase
            .collection("testCollection")
            .document("testDocument")
            .set(
          {
            "Test Map Key 1": "Test Map Value 1",
            "Test Map Key 2": 2,
          },
        ),
        4,
      );
      expect(
        storageDatabase
            .collection("testCollection")
            .document("testDocument/Test Map Key 3")
            .set(
          [
            "Test Item 1",
            "Test Item 2",
          ],
        ),
        5,
      );
      expect(
        storageDatabase.document("testCollection/testDocument").set(
          {
            "Test Map Key 4": true,
            "Test Map Key 5": null,
          },
        ),
        6,
      );
    },
  );
}
