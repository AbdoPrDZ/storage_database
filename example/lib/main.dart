import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:storage_database/storage_database.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
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
        label: 'Dismiss',
        onPressed: () {},
      ),
    ));
  }

  initStorageDatabase() async {
    if (storageDatabase != null) {
      snackbar('StorageDatabase already initialized');
      return;
    }
    storageDatabase = await StorageDatabase.getInstance();
    setState(() {});
    storageDatabase!.collection('products').set({});
    snackbar('StorageDatabase initializing successfully');
  }

  TextEditingController explorerPathController = TextEditingController();
  initStorageExplorer() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (storageDatabase!.explorer != null) {
      snackbar('StorageExplorer already initialized');
      return;
    }
    await storageDatabase!.initExplorer(
      path: explorerPathController.text.isNotEmpty
          ? explorerPathController.text
          : null,
    );
    snackbar('StorageExplorer initializing successfully');
  }

  initNetworkFiles() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (storageDatabase!.explorer == null) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (storageDatabase!.explorer!.networkFiles != null) {
      snackbar('NetworkFiles already initialized');
      return;
    }
    await storageDatabase!.explorer!.initNetWorkFiles();
    await storageDatabase!.clear();
    snackbar('NetworkFiles initializing successfully');
  }

  TextEditingController imageUrlController = TextEditingController();
  TextEditingController tokenController = TextEditingController();
  Widget? networkImage;
  getNetworkImage() {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
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
    log('$networkImage');
    log("'Authorization': ${tokenController.text}");
    snackbar('Successfully getting image');
  }

  TextEditingController apiUrlController = TextEditingController(
    text: 'http://localhost/api',
  );

  initStorageAPI() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (apiUrlController.text.isEmpty) {
      snackbar("Api Url required");
      return;
    }
    await storageDatabase!.initAPI(apiUrl: apiUrlController.text);
    snackbar('StorageExplorer initializing successfully');
  }

  TextEditingController collectionController = TextEditingController();
  TextEditingController collectionDataController = TextEditingController();
  createCollection() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
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
    log(await storageDatabase!.collection(collectionController.text).get());
    snackbar('StorageCollection created successfully');
  }

  getCollectionData() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
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
    log('$imagePath');
    if (imagePath != null) snackbar('Successfully chose image');
  }

  TextEditingController targetController = TextEditingController();
  int bytes = 0;
  int totalBytes = 1;
  uploadImage() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
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
        log("progress: ${bytes / totalBytes * 100}%");
        this.bytes = bytes;
        this.totalBytes = totalBytes;
        setState(() {});
      },
    );
    snackbar('Successfully uploading file');
  }

  TextEditingController dirPathController = TextEditingController();
  createDir() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (storageDatabase!.explorer == null) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (dirPathController.text.isEmpty) {
      snackbar('Please enter directory Path');
      return;
    }
    storageDatabase!.explorer!.directory(dirPathController.text);
    snackbar('Directory created successfully');
  }

  TextEditingController echoTokenController = TextEditingController();
  bool laravelEchoConnected = false;
  Map products = {};
  connectLaravelEcho() {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    }

    storageDatabase!.initSocketLaravelEcho(
      'http://localhost:6001',
      [
        ProductMigration(
          storageDatabase!.laravelEcho!,
          storageDatabase!,
          'products',
        )
      ],
      autoConnect: false,
      auth: {
        'headers': {'Authorization': 'Bearer ${echoTokenController.text}'}
      },
      moreOptions: {
        'transports': ['websocket'],
      },
    );
    storageDatabase!.laravelEcho!.connect();
    storageDatabase!.laravelEcho!.connector.onConnect((data) {
      setState(() => laravelEchoConnected = true);
      log('socket connected');
    });
    storageDatabase!.laravelEcho!.connector.onDisconnect((data) {
      setState(() => laravelEchoConnected = false);
      log('socket disconnected');
    });
    storageDatabase!.laravelEcho!.connector.onConnectError((err) {
      setState(() => laravelEchoConnected = false);
      log('socketConnectError: $err');
    });
    storageDatabase!.laravelEcho!.connector.onError((err) {
      log('socketError: $err');
    });
    storageDatabase!
        .collection('products')
        .stream()
        .listen((data) => setState(() => products = data));
    snackbar('Laravel echo connected successfully');
  }

  getLaravelEchoChannels() {
    storageDatabase!.laravelEcho!.connector.channels.forEach((name, channel) {
      channel = channel as SocketIoChannel;
      log(' -- channel: $name');
      for (var event in channel.events.keys) {
        log(' -> event: $event');
      }
    });
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  const Divider(),
                  ElevatedButton(
                    onPressed: initStorageDatabase,
                    child: const Text('Init StorageDatabase'),
                  ),
                  const Divider(),
                  ElevatedButton(
                    onPressed: initStorageExplorer,
                    child: const Text('Init StorageExplorer'),
                  ),
                  const Divider(),
                  const Divider(),
                  TextField(
                    controller: apiUrlController,
                    decoration: const InputDecoration(hintText: 'API URL'),
                  ),
                  ElevatedButton(
                    onPressed: initStorageAPI,
                    child: const Text('Init StorageAPI'),
                  ),
                  const Divider(),
                  TextField(
                    controller: collectionController,
                    decoration: const InputDecoration(hintText: 'Collection'),
                  ),
                  TextField(
                    controller: collectionDataController,
                    decoration:
                        const InputDecoration(hintText: 'Collection Data'),
                  ),
                  ElevatedButton(
                    onPressed: createCollection,
                    child: const Text('Create Collection'),
                  ),
                  const Divider(),
                  ElevatedButton(
                    onPressed: getCollectionData,
                    child: const Text('Get Collection Data'),
                  ),
                  InkWell(
                    onTap: choseImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 217, 217, 217),
                        image: imagePath != null
                            ? DecorationImage(
                                image: FileImage(File(imagePath!)),
                              )
                            : null,
                      ),
                    ),
                  ),
                  LinearProgressIndicator(
                    value: bytes / totalBytes,
                  ),
                  TextField(
                    controller: targetController,
                    decoration: const InputDecoration(hintText: 'Target'),
                  ),
                  ElevatedButton(
                    onPressed: uploadImage,
                    child: const Text('Upload Image'),
                  ),
                  const Divider(),
                  ElevatedButton(
                    onPressed: initNetworkFiles,
                    child: const Text('Init NetworkFiles'),
                  ),
                  const Divider(),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(hintText: 'Image Url'),
                  ),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(hintText: 'Token'),
                  ),
                  ElevatedButton(
                    onPressed: getNetworkImage,
                    child: const Text('Get NetworkImage'),
                  ),
                  if (networkImage != null) networkImage!,
                  TextField(
                    controller: dirPathController,
                    decoration: const InputDecoration(hintText: 'Dir Path'),
                  ),
                  ElevatedButton(
                    onPressed: createDir,
                    child: const Text('Create Directory'),
                  ),
                  const Divider(),
                  TextField(
                    controller: echoTokenController,
                    decoration:
                        const InputDecoration(hintText: 'Laravel Echo Token'),
                  ),
                  ElevatedButton(
                    onPressed: laravelEchoConnected
                        ? storageDatabase!.laravelEcho!.disconnect
                        : connectLaravelEcho,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        laravelEchoConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      '${laravelEchoConnected ? 'Disconnect' : 'Connect'} Laravel Echo',
                    ),
                  ),
                  if (laravelEchoConnected)
                    ElevatedButton(
                      onPressed: getLaravelEchoChannels,
                      child: const Text('Get Laravel Echo Channels'),
                    ),
                  if (storageDatabase != null)
                    // StreamBuilder(
                    //   stream: storageDatabase!.collection('products').stream(),
                    //   builder: (context, snapshot) =>
                    Container(
                      height: 200,
                      color: const Color(0xFFE4E4E4),
                      padding: const EdgeInsets.all(5),
                      child: SingleChildScrollView(
                        // child: Text(snapshot.data?.toString() ?? 'None'),
                        child: Text(products.toString()),
                      ),
                    ),
                  // ),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      );
}

class ProductMigration extends LaravelEchoMigration {
  final Echo echo;
  ProductMigration(this.echo, super.storageDatabase, super.collectionId);

  @override
  String get migrationName => 'Product';

  @override
  String get itemName => 'product';

  @override
  Channel get channel => echo.private('products');

  @override
  onCreate(Map data) {
    log('Product Created $data');
    return super.onCreate(data);
  }

  @override
  onUpdate(Map data) {
    log('Product Updated $data');
    return super.onUpdate(data);
  }

  @override
  onDelete(Map data) {
    log('Product Deleted $data');
    return super.onDelete(data);
  }
}
