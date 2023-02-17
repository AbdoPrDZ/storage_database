import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:storage_database/storage_database.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StorageDatabase? storageDatabase;

  snackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.black,
      action: SnackBarAction(
        label: 'dismiss',
        onPressed: () {},
      ),
    ));
  }

  initStorageDatabase() async {
    if (storageDatabase != null) {
      snackbar('StorageDatabase already inited');
      return;
    }
    storageDatabase = await StorageDatabase.getInstance();
    snackbar('storageDatabase inited successfully');
  }

  initStorageExplorer() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (storageDatabase!.explorer != null) {
      snackbar('StorageExplorer already inited');
      return;
    }
    await storageDatabase!.initExplorer();
    snackbar('storageExplorer inited successfully');
  }

  initNetworkFiles() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (storageDatabase!.explorer == null) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (storageDatabase!.explorer!.networkFiles != null) {
      snackbar('NetworkFiles already inited');
      return;
    }
    await storageDatabase!.explorer!.initNetWorkFiles();
    await storageDatabase!.clear();
    snackbar('NetworkFiles inited successfully');
  }

  TextEditingController imageUrlController = TextEditingController(
    text: "http://service-electronic.ddns.net/file/api/u-3-pi",
  );
  TextEditingController tokenController = TextEditingController(
    text: "Bearer 264|8MJ2nxcxs0PWnqpCVM7J4k9JVOg0f5YSIDt9TYTp",
  );
  Widget? networkImage;
  getNetworkImage() {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (storageDatabase!.explorer == null) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (storageDatabase!.explorer!.networkFiles == null) {
      snackbar('You need to init NetworkFiles first');
      return;
    } else if (imageUrlController.text.isEmpty) {
      snackbar('Image Url has been required');
      return;
    }
    setState(() {
      networkImage = null;
    });
    setState(() {
      networkImage = storageDatabase!.explorer!.networkFiles!.networkImage(
        imageUrlController.text,
        height: 300,
        headers: {
          if (tokenController.text.isNotEmpty)
            'Authorization': tokenController.text
        },
        refresh: true,
        log: true,
      );
    });
    print(networkImage);
    print("'Authorization': ${tokenController.text}");
    snackbar('Successfully getting image');
  }

  TextEditingController apiUrlController = TextEditingController(
    text: 'http://localhost/api',
  );

  initStorageAPI() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (apiUrlController.text.isEmpty) {
      snackbar("Api Url required");
      return;
    }
    await storageDatabase!.initAPI(apiUrl: apiUrlController.text);
    snackbar('storageExplorer inited successfully');
  }

  TextEditingController collectionController = TextEditingController();
  TextEditingController collectionDataController = TextEditingController();
  createCollection() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (collectionController.text.isEmpty) {
      snackbar("Collection name required");
      return;
    } else if (collectionDataController.text.isEmpty) {
      snackbar("Collection Data required");
      return;
    }
    await storageDatabase!
        .collection(collectionController.text)
        .set(collectionDataController.text);
    print(await storageDatabase!.collection(collectionController.text).get());
    snackbar('storageCollection created successfully');
  }

  getCollectionData() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (collectionController.text.isEmpty) {
      snackbar("Collection name required");
      return;
    }

    snackbar(
      'Collection Data: "${await storageDatabase!.collection(collectionController.text).get()}"',
    );
  }

  String? imagePath;
  choseImage() async {
    setState(() {});
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'ico', 'gif', 'bmp'],
    );
    imagePath = result?.files.single.path!;
    setState(() {});
    print(imagePath);
    if (imagePath != null) snackbar('Successfully choseing image');
  }

  TextEditingController targetController = TextEditingController();
  int bytes = 0;
  int totalBytes = 1;
  upladImage() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabse first");
      return;
    } else if (storageDatabase!.storageAPI == null) {
      snackbar('You need to init StorageAPI first');
      return;
    } else if (imagePath == null) {
      snackbar('You need to chose image first');
      return;
    } else if (targetController.text.isEmpty) {
      snackbar('Target has been required');
      return;
    }
    bytes = 0;
    totalBytes = 1;
    await storageDatabase!.storageAPI!.request(
      targetController.text,
      RequestType.post,
      files: [
        await http.MultipartFile.fromPath('image', imagePath!),
      ],
      data: {
        'text': '121',
      },
      log: true,
      onFilesUpload: (bytes, totalBytes) {
        print("progress: ${bytes / totalBytes * 100}%");
        this.bytes = bytes;
        this.totalBytes = totalBytes;
        setState(() {});
      },
    );
    snackbar('Successfully uplading file');
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    SizedBox gap = SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(
        title: const Text('StorageDatabase Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: formKey,
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(),
                ElevatedButton(
                  onPressed: initStorageDatabase,
                  child: const Text('Init StorageDatabase'),
                ),
                Divider(),
                ElevatedButton(
                  onPressed: initStorageExplorer,
                  child: const Text('Init StorageExplorer'),
                ),
                Divider(),
                TextField(
                  controller: apiUrlController,
                  decoration: const InputDecoration(hintText: 'API URL'),
                ),
                gap,
                ElevatedButton(
                  onPressed: initStorageAPI,
                  child: const Text('Init StorageAPI'),
                ),
                Divider(),
                TextField(
                  controller: collectionController,
                  decoration: const InputDecoration(hintText: 'Collection'),
                ),
                gap,
                TextField(
                  controller: collectionDataController,
                  decoration:
                      const InputDecoration(hintText: 'Collection Data'),
                ),
                gap,
                ElevatedButton(
                  onPressed: createCollection,
                  child: const Text('Create Collection'),
                ),
                Divider(),
                ElevatedButton(
                  onPressed: getCollectionData,
                  child: const Text('Get Collection Data'),
                ),
                Divider(),
                InkWell(
                  onTap: choseImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 217, 217, 217),
                      image: imagePath != null
                          ? DecorationImage(
                              image: FileImage(
                                File(imagePath!),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                gap,
                LinearProgressIndicator(
                  value: bytes / totalBytes,
                ),
                gap,
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(hintText: 'Target'),
                ),
                ElevatedButton(
                  onPressed: upladImage,
                  child: const Text('Upload Image'),
                ),
                Divider(),
                ElevatedButton(
                  onPressed: initNetworkFiles,
                  child: const Text('init NetworkFiles'),
                ),
                Divider(),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(hintText: 'Image Url'),
                ),
                gap,
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(hintText: 'Toekn'),
                ),
                ElevatedButton(
                  onPressed: getNetworkImage,
                  child: const Text('get NetworkImage'),
                ),
                if (networkImage != null) networkImage!
              ],
            ),
          ),
        ),
      ),
    );
  }
}
