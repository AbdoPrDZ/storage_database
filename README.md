# Getting started

Please read the readme file carefully so that your project runs without problems.

## StorageDatabase

### Importing

```dart
import 'package:storage_database/storage_database.dart';
```

### Initializing

```dart
// You have to give source class extended by 'StorageDatabaseSource'
// Default source is 'DefaultStorageSource' class
StorageDatabase storage = await StorageDatabase.getInstance(); 
// In this example you should to create source class extended with 'StorageDatabaseSource'
StorageDatabase storageEx2 = StorageDatabase(await MyStorageSourceClass.getInstance());
```

### SourceClass

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_database/src/storage_database_source.dart';

class MyStorageSourceClass extends StorageDatabaseSource {
  final SharedPreferences storage;

  MyStorageSourceClass(this.storage);

  // initializing function
  static Future<MyStorageSourceClass> getInstance() async =>
      MyStorageSourceClass(await SharedPreferences.getInstance());

  // setting data function
  @override
  Future<bool> setData (String id, dynamic data ) async {
    data = jsonEncode(data);
    return storage.setString(id, data);
  }

  // getting data function
  @override
  Future<dynamic> getData (String id) {
    String? data = storage.getString(id);
    if (data != null) {
      return jsonDecode(data);
    } else {
      return null;
    }
  }

  // check for id function
  @override
  Future<bool> containsKey(String key) async => storage.containsKey(key);

  // remove function
  @override
  Future<bool> remove(String id) => storage.remove(id);

  // clear function
  @override
  Future<bool> clear(String id) => storage.clear();
}
```

### Create Collection

```dart
await storage.collection("collection-1")
             .set("any data && any type"); // c-1
await storage.collection("collection-1")
             .set("any new data but some type"); // c-2

// Map data : 
await storage.collection("collection-2") // c-3
             .collection("subColId")
             .set({'item 1': 'data 1', 'item 2': 'data 2'}); // sc-1
await storage.collection("collection-2")
             .collection("subColId")
             .set({'item 3': 'data 3'}); // sc-2
await storage.collection("collection-2")
             .collection("subColId")
             .set({'item 4': 'data 4'}, keep = false); // sc-3

// List data :
await storage.collection("collection-3") 
             .collection("subColId")
             .set(["item 1", "item 2"]); // sc-4
await storage.collection("collection-3")
             .collection("subColId")
             .set(['item 3']); // sc-5
await storage.collection("collection-3")
             .collection("subColId")
             .set(["item 4"], keep = false); // sc-6
```

### Getting Collection data

```dart
await storage.collection("collection-1").get(); // c-1 => 'any data && any type'
await storage.collection("collection-1").get(); // c-2 => 'any data but some type'
await storage.collection("collection-2").get(); // c-3 => {"subColId": {'item 1': 'data 1', 'item 2': 'data 2'}}

//// Map:
storage.collection("collection-2").collection("subColId").get()
// d-1 => {'item 1': 'data 1', 'item 2': 'data 2'}
storage.collection("collection-2").collection("subColId").get()
// d-2 => {'item 1': 'data 1', 'item 2': 'data 2', 'item 3': 'data 3'}
storage.collection("collection-2").collection("subColId").get()
// d-3 => {'item 4': 'data 4'}

//// List: 
storage.collection("collection-3").collection("subColId").get()
// d-4 => ['item 1', 'item 2']
storage.collection("collection-3").collection("subColId").get()
// d-5 => ['item 1', 'item 2', 'item 3']
storage.collection("collection-3").collection("subColId").get()
// d-6 => ['item 4']
```

### Working with stream

```dart
List collData = [];
int itemIndex = 0;
String lastItem = "";
Column(
  children: [
    StreamBuilder(
      stream: storage.collection("collection-3").collection("subColId").stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.data != null) {
            collData = snapshot.data!;
          }
          return SingleChildScrollView(
            child: Column(
              children: List.generate(
                collData.length,
                (index) => Text(
                  collData[index].toString(),
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
        storage.collection("collection-3").collection("subColId").set([lastItem]);
      },
      child: const Text("Add item"),
    ),
    ElevatedButton(
      onPressed: () {
        storage.collection("collection-3").collection("subColId").deleteItem(lastChat);
        itemIndex -= 1;
        lastItem = "item $itemIndex";
      },
      child: const Text("Remove item"),
    ),
  ],
);
```

## StorageExplorer

This feature use to manage files and directories.

### Importing

```dart
import 'package:storage_database/storage_explorer/storage_explorer.dart';
```

### Initializing

```dart
// 1: normal initializing
StorageDatabase storageDatabase = await StorageDatabase.getInstance(); // you need to init storageDatabase first

Directory localIODirectory = await getApplicationDocumentsDirectory() // this function from path_provider package
StorageExplorer storageExplorer = StorageExplorer(storageDatabase, localIODirectory);
//or
StorageExplorer storageExplorer = StorageExplorer.getInstance(storageDatabase, customPath: "your/custom/path");

// 2: initializing from StorageDatabase Class
await storageDatabase.initExplorer();
// for use it
storageDatabase.explorer!.<FunctionName> // <FunctionName>: name of function you want to use
```

### Create Directory

```dart
// into local directory
ExplorerDirectory dir = explorer!.directory("dirName");

// into directory
ExplorerDirectory otherDir = dir.directory("other dirName");

// using path
ExplorerDirectory otherDir = explorer!.directory("dirName/other dirName");
// Notes:
// 1- working with local directory and normal directory.
// 2- don't use real path:
//    - false Path: "C:\users\user\document\dirName\other dirName"
//    - true Path: "dirName/other dirName"
// 3- don't use backslash:
//    - false path: "dir\other dir"
//    - true path:  "dir/other dir"
```

### Create File

```dart
// into local directory
ExplorerFile file = explorer!.file("filename.txt");

// into normal directory
ExplorerFile file = dir.file("filename.txt");
```

### Get Directory items

```dart
List<ExplorerDirectoryItem> dirItems = dir.get();
```

### Set File Data

```dart
// normal: setting String data
await file.set("file data");

// bytes: setting Bytes data
await bytesFile.setBytes(bytes);

// json: setting Json data
await jsonFile.set({"key": "val"}); // Map
await jsonFile.set(["item 1", "item 2"]); // List
//// setMode (only with Map and List data, default mode is <append>)
await jsonFile.set({"other key": "other val"}, setMode: SetMode.append); // this mode for append values
// when get => {"key": "val", "other key": "other val"}
await jsonFile.set({"key": "val"}, setMode: SetMode.remove); // this mode for remove values
// when get => {"other key": "other val"}
await jsonFile.set({"new key": "new val"}, setMode: SetMode.replace); // this mode for replace all old values with new values
// when get => {"new key": "new val"}
```

### Get File Data

```dart
// normal: getting as String
String fileData = await file.get(); // => "file data"

// bytes: getting as Bytes
Uint8List fileBytes = await bytesFile.getBytes();

// json: getting as json
Map fileJsonData = await mapJsonFile.getJson(); // with Map => {"key": "val"}
List fileJsonData = await listJsonFile.getJson(); // with List => ["item 1", "item 2"]
...
```

### Working with Directory Stream

```dart
// used for watch directory items
List<ExplorerDirectoryItem> dirItems = [];
StreamBuilder<List<ExplorerDirectoryItem>>(
  stream: dir.stream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      dirItems = snapshot.data;
    }
    return ListView(
      children: List.generate(
        dirItems.length,
        (index) => Text("<${item.itemType}>: ${dirItems[index].itemName}"),
      );
    )
  }
)
```

### Working with File Stream

```dart
// used for watch file data

// normal: stream file data as String
file.stream();

// bytes: stream bytes of file
file.bytesStream();

// json: stream file data as json
file.jsonStream();
```

### Working with Network File

This feature downloads the file from the Internet, then stores it where the file can be used later without re-downloading it, and it can also work even in an offline state.

```dart
// you need to initial it from explorer
await storageDatabase.explorer!.initNetWorkFiles();

// call it like that
ExplorerFile file = await storageDatabase.explorer!.networkFiles!.networkFile('http://your.url.file');
// now you can use ExplorerFile features
```

The feature contains a ready-made widget, especially for images, where it displays an animated shimmer while loading the image and then displays the image, and in case the image is damaged, an icon is displayed.

```dart
await storageDatabase.explorer!.networkFiles!.networkImage(
  'http://your.image.url',
  width: 100,
  heigh: 100,
  borderRadius: 8,
  fit: BoxFit.fill,
);
```

## StorageAPI

This feature used for api requests and responses, and it has the feature of storing requests in an offline state, to be re-request it again later on online.

### Importing

```dart
import 'package:storage_database/api/api.dart';
```

### Initializing

```dart
// 1: normal initializing
StorageDatabase storageDatabase = await StorageDatabase.getInstance(); // you need to init storageDatabase first

StorageAPI storageApi = StorageExplorer(
  storageDatabase: storageDatabase,
  tokenSource: () => 'api-token',
  apiUrl: 'http://your.api.url',
  // requests cache removed for now
  //cacheOnOffline: true, // for store requests on offline
  //onReRequestResponse: (response) => print(response.value),
);

// 2: initializing from StorageDatabase Class
await storageDatabase.initAPI(
  tokenSource: () async => 'api-token',
  apiUrl: 'http://your.api.url',
  cacheOnOffline: true, // for store requests on offline
  onReRequestResponse: (response) => print(response.value),
);
// for use it
storageDatabase.storageAPI!.<FunctionName> // <FunctionName>: name of function you want to use
```

### Working with APIRequest

```dart
APIResponse response = storageAPI.request<TypeOfResponseValue>(
  'target',
  RequestTypes.post, // request type (get, post, put, patch, delete)
  log: true, // print on console request steps
  data: {"key": "value"}, // request data
  auth: true, // to send request with auth token
  onNoConnection: (reqId) => print('field to request $reqId'), // this requestId used for re-request later
);

// to re-request
storageAPI.resendRequest(reqId);
// to re-request multi requests ids
storageAPI.resendRequests(
  [requestIds], // when is empty automatically is re-request all ids stored
  onResponse: (response) => print(response.message),
);

// to clear all request ids stored
await storageAPI.clear();
```

### Working with APIResponse

```dart
APIResponse<TypeOfValue> response = APIResponse<TypeOfValue>(
  bool success,
  String message,
  int statusCode,
  TypeOfValue? value,
);
// to get value
TypeOfValue value = response.value;


// Note: your api response data must be like that
{
  "success": true, //or false
  "message": "your message",
  "value": {"key1": "val1", "key2": ["val1"]}, // excepted any type this just example
}

// you can use this also
{
  "success": true, //or false
  "message": "your message",
  "key1": "val1",
}
// response.value => "val1"

// or this
{
  "success": true, //or false
  "message": "your message",
  "key1": "val1",
  "key2": ["val1"],
}
// response.value => {"key1": "val1", "key2": ["val1"]}
```

## Laravel Echo (Beta)

This feature used to laravel echo connection, and you listen to Laravel Models.

### Importing

```dart
import 'package:storage_database/laravel_echo/laravel_echo.dart';
```

### Initializing

```dart
// Laravel Echo Connector, migrations
storageDatabase.initLaravelEcho(connector, <LaravelEchoMigration>[]);

storageDatabase.initSocketLaravelEcho(<connector parameters>, <LaravelEchoMigration>[]);

storageDatabase.initPusherLaravelEcho(<connector parameters>, <LaravelEchoMigration>[]);

```

#### Note: Please read [laravel_echo_null](https://pub.dev/packages/laravel_echo_null) for more information if you use connector to initializing

### Working with migrations

This used to create migration to listen to Laravel Model events (Create, Update, Delete).

```dart
class MessageMigration extends LaravelEchoMigration {
  MessageMigration(super.storageDatabase, super.collectionId);

  @override
  String get migrationName => 'Message';

  @override
  String get itemName => 'message';

  @override
  Channel get channel => storageDatabase.laravelEcho!.private('messages');

  // you can custom your events names and remove what you don't need
  @override
  Map<EventsType, String> get eventsNames => {
        EventsType.create: '${migrationName}CreatedEvent',
        EventsType.update: '${migrationName}UpdatedEvent',
        EventsType.delete: '${migrationName}DeletedEvent',
      };

  @override
  setup() {
    super.setup();
    // get messages
    channel.listen('channel_subscribe_success', (Map messages) {
      print('messages: $messages');
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
```

#### Your Events must be like that:

- Create:

  ```php
  class MessageCreatedEvent implements ShouldBroadcast {

    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
    * @var Message
    */
    private $message;

    /**
    * Create a new event instance.
    * @param Message $message
    */
    public function __construct(Message $message) {
      $this->message = $message;
    }

    /**
    * Get the channels the event should broadcast on.
    *
    * @return array<int, \Illuminate\Broadcasting\Channel>
    */
    public function broadcastOn(): array {
      return [
        new PrivateChannel('messages'),
      ];
    }

    /**
    * The event's broadcast name.
    *
    * @return string
    */
    public function broadcastAs() {
      return 'MessageCreatedEvent';
    }

    /**
    * The event's broadcast name.
    *
    * @return array
    */
    public function broadcastWith() {
      return [
        'message' // Item Name
            => $this->message->toArray()
      ];
    }
  }
  ```

- Update:

  ```php
  class MessageUpdatedEvent implements ShouldBroadcast {

    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
    * @var Message
    */
    private $message;

    /**
    * Create a new event instance.
    * @param Message $message
    */
    public function __construct(Message $message) {
      $this->message = $message;
    }

    /**
    * Get the channels the event should broadcast on.
    *
    * @return array<int, \Illuminate\Broadcasting\Channel>
    */
    public function broadcastOn(): array {
      return [
        new PrivateChannel('messages'),
      ];
    }

    /**
    * The event's broadcast name.
    *
    * @return string
    */
    public function broadcastAs() {
      return 'MessageUpdatedEvent';
    }

    /**
    * The event's broadcast name.
    *
    * @return array
    */
    public function broadcastWith() {
      return [
        'message' // Item Name
            => $this->message->toArray()
      ];
    }
  }
  ```

- Delete:

  ```php
  class MessageDeletedEvent implements ShouldBroadcast {

    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
    * @var Message
    */
    private $message;

    /**
    * Create a new event instance.
    * @param Message $message
    */
    public function __construct(Message $message) {
      $this->message = $message;
    }

    /**
    * Get the channels the event should broadcast on.
    *
    * @return array<int, \Illuminate\Broadcasting\Channel>
    */
    public function broadcastOn(): array {
      return [
        new PrivateChannel('messages'),
      ];
    }

    /**
    * The event's broadcast name.
    *
    * @return string
    */
    public function broadcastAs() {
      return 'MessageDeletedEvent';
    }

    /**
    * The event's broadcast name.
    *
    * @return array
    */
    public function broadcastWith() {
      return ['id' => $this->message->id];
    }
  }
  ```
#### You should connect events like that to model

```php
class Message extends Model {
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'title',
        'content',
    ];

    protected $dispatchesEvents = [
        'created' => MessageCreatedEvent::class,
        'updated' => MessageUpdatedEvent::class,
        'deleted' => MessageDeletedEvent::class,
    ];
}
```

#### You must to return all messages when channel subscribed like that:
```php
Broadcast::channel('messages', function ($user) {
    foreach (App\Models\Message::all() as $message) {
        $messages[$message->id] = $message;
    }
    return $messages;
});
```

# Contact Us

GitHub Profile: <https://github.com/AbdoPrDZ>

<!-- WhatsApp + Telegram (+213778185797) -->

Facebook Account: <https://www.facebook.com/profile.php?id=100008024286034>
