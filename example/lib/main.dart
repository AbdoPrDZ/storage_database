import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:storage_database/storage_database.dart';
import 'package:storage_database/storage_explorer/explorer_network_files.dart';

void main() => runApp(const MyApp());

class UserModel extends StorageModel {
  final String name;

  const UserModel({
    super.id,
    required this.name,
  });

  factory UserModel.fromMap(Map map) => UserModel(
        id: map['id'],
        name: map['name'],
      );

  @override
  Map toMap() => {
        'name': name,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Storage Database Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StorageDatabase? storageDatabase;

  void snackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.black,
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {},
      ),
    ));
  }

  void initStorageDatabase() async {
    if (storageDatabase != null) {
      snackbar('StorageDatabase already initialized');
      return;
    }

    await StorageDatabase.initInstance();
    storageDatabase = StorageDatabase.instance;
    await storageDatabase!.clear();

    StorageModelRegister.register<UserModel>(
      (data) => UserModel.fromMap(data),
      'users',
    );

    await storageDatabase!.collection('messages').set({});
    storageDatabase!
        .collection('messages')
        .stream()
        .listen((data) => setState(() => messages = data));

    setState(() {});

    snackbar('StorageDatabase initializing successfully');
  }

  TextEditingController explorerPathController = TextEditingController();
  void initStorageExplorer() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (StorageExplorer.hasInstance) {
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

  void initNetworkFiles() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (!StorageExplorer.hasInstance) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (ExplorerNetworkFiles.hasInstance) {
      snackbar('NetworkFiles already initialized');
      return;
    }

    storageDatabase!.explorer.initNetWorkFiles();
    await storageDatabase!.clear();

    snackbar('NetworkFiles initializing successfully');
  }

  TextEditingController imageUrlController = TextEditingController();
  TextEditingController tokenController = TextEditingController();
  Widget? networkImage;
  void getNetworkImage() {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (!StorageExplorer.hasInstance) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (!ExplorerNetworkFiles.hasInstance) {
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
      networkImage = ExplorerNetworkFiles.instance.networkImage(
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

  void initStorageAPI() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (apiUrlController.text.isEmpty) {
      snackbar("Api Url required");
      return;
    }

    storageDatabase!.initAPI(apiUrl: apiUrlController.text);

    snackbar('StorageExplorer initializing successfully');
  }

  TextEditingController collectionController = TextEditingController();
  TextEditingController collectionDataController = TextEditingController();
  void createCollection() async {
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

    dynamic data = collectionDataController.text;

    try {
      data = jsonDecode(data);
    } catch (e) {
      log('Error: $e');
    }

    await storageDatabase!.collection(collectionController.text).set(data);

    final collectionData =
        await storageDatabase!.collection(collectionController.text).get();

    log(collectionData.toString());

    snackbar('StorageCollection created successfully');
  }

  void createUserCollection() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    }

    // await storageDatabase!.collection("user").set(
    //       UserModel(
    //         id: '1',
    //         name: 'John Doe',
    //         // type: 'user',
    //       ),
    //     );

    // UserModel user = await storageDatabase!.collection("user").getAsModel();

    // log(user.toString());

    final newUser = UserModel(
      name: 'Abdo Pr',
    );

    snackbar(newUser.toString());

    await newUser.save();

    snackbar((await storageDatabase!.collection('users').get()).toString());

    final user = await StorageModel.find<UserModel>('1');
    snackbar(user.toString());

    snackbar((await StorageModel.all<UserModel>()).toString());

    snackbar('User StorageCollection created successfully');
  }

  void getCollectionData() async {
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
  void choseImage() async {
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
  void uploadImage() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (!storageDatabase!.storageAPIIsInitialized) {
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

    await storageDatabase!.storageAPI.request(
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
  void createDir() async {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    } else if (!StorageExplorer.hasInstance) {
      snackbar('You need to init StorageExplorer first');
      return;
    } else if (dirPathController.text.isEmpty) {
      snackbar('Please enter directory Path');
      return;
    }
    storageDatabase!.explorer.directory(dirPathController.text);
    snackbar('Directory created successfully');
  }

  TextEditingController echoTokenController = TextEditingController();
  String broadcaster = 'socket.io';
  bool laravelEchoConnected = false;
  Map messages = {};
  void connectLaravelEcho() {
    if (storageDatabase == null) {
      snackbar("You need to init StorageDatabase first");
      return;
    }

    if (broadcaster == 'socket.io') {
      storageDatabase!.initSocketLaravelEcho(
        'http://localhost:6001',
        [MessageMigration(storageDatabase!, 'messages')],
        autoConnect: false,
        authHeaders: {'Authorization': 'Bearer ${echoTokenController.text}'},
        moreOptions: {
          'transports': ['websocket'],
        },
      );
    } else if (broadcaster == 'pusher') {
      const String key = "PUSHER_KEY";
      const String cluster = 'PUSHER_CLUSTER';
      const String hostEndPoint = "PUSHER_HOST";
      const String hostAuthEndPoint = "http://$hostEndPoint/broadcasting/auth";
      const int port = 6001;

      storageDatabase!.initPusherLaravelEcho(
        key,
        [
          MessageMigration(storageDatabase!, 'messages'),
        ],
        host: hostEndPoint,
        wsPort: port,
        cluster: cluster,
        encrypted: true,
        authEndPoint: hostAuthEndPoint,
        authHeaders: {
          'Authorization': 'Bearer ${echoTokenController.text}',
        },
        autoConnect: false,
        enableLogging: true,
      );
    }

    storageDatabase!.laravelEcho.connector.onConnect((data) {
      setState(() => laravelEchoConnected = true);
      log('socket connected');
    });
    storageDatabase!.laravelEcho.connector.onDisconnect((data) {
      setState(() => laravelEchoConnected = false);
      log('socket disconnected');
    });
    storageDatabase!.laravelEcho.connector.onConnectError((err) {
      setState(() => laravelEchoConnected = false);
      log('socketConnectError: $err');
    });
    storageDatabase!.laravelEcho.connector.onError((err) {
      log('socketError: $err');
    });
    storageDatabase!.laravelEcho.connect();

    snackbar('Laravel echo connected successfully');
  }

  void getLaravelEchoChannels() {
    storageDatabase!.laravelEcho.connector.channels.forEach((name, channel) {
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
          title: const Text('StorageDatabase Example'),
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
                  ElevatedButton(
                    onPressed: createUserCollection,
                    child: const Text('Create User Collection'),
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
                                image: FileImage(io.File(imagePath!)),
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
                  Row(
                    children: [
                      const Text('Broadcaster:'),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: broadcaster,
                        items: const [
                          DropdownMenuItem(
                            value: 'socket.io',
                            child: Text('Socket.io'),
                          ),
                          DropdownMenuItem(
                            value: 'pusher',
                            child: Text('Pusher'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => broadcaster = value ?? broadcaster,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: laravelEchoConnected
                        ? storageDatabase!.laravelEcho.disconnect
                        : connectLaravelEcho,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
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
                    //   stream: storageDatabase!.collection('messages').stream(),
                    //   builder: (context, snapshot) =>
                    Container(
                      height: 200,
                      color: const Color(0xFFE4E4E4),
                      padding: const EdgeInsets.all(5),
                      child: SingleChildScrollView(
                        // child: Text(snapshot.data?.toString() ?? 'None'),
                        child: Text(const JsonEncoder.withIndent('  ')
                            .convert(messages)),
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

class MessageMigration extends LaravelEchoMigration {
  MessageMigration(super.storageDatabase, super.collectionId);

  @override
  String get migrationName => 'messages';

  @override
  String get itemName => 'message';

  @override
  Channel get channel => storageDatabase.laravelEcho.private('messages');

  @override
  Map<EventsType, String> get eventsNames => {
        EventsType.create: 'MessageCreatedEvent',
        EventsType.update: 'MessageUpdatedEvent',
        EventsType.delete: 'MessageDeletedEvent',
      };

  @override
  setup() {
    super.setup();
    channel.listen('channel_subscribe_success', (Map messages) {
      log('messages: $messages');
      set(messages, keepData: false);
    });
  }

  @override
  onCreate(Map data) {
    log('Message Created $data');
    return super.onCreate(data);
  }

  @override
  onUpdate(Map data) {
    log('Message Updated $data');
    return super.onUpdate(data);
  }

  @override
  onDelete(Map data) {
    log('Message Deleted $data');
    return super.onDelete(data);
  }
}
