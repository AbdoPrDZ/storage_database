import 'package:flutter/material.dart';
import 'package:storage_database/storage_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StorageDatabase storageDatabase;
  late ExplorerFile chatsFile, camFile;
  int chatIndex = 0;
  String lastChat = "";

  Future<bool> initStorage() async {
    await StorageDatabase.initInstance();

    storageDatabase = StorageDatabase.instance;

    await storageDatabase.initExplorer();
    await storageDatabase.clear();

    chatsFile = storageDatabase.explorer.file("chats.json");
    camFile = storageDatabase.explorer.file("camp.png");

    await addChat();

    return true;
  }

  Future addChat() async {
    chatIndex += 1;

    await chatsFile.setJson(["chat $chatIndex"]);

    lastChat = "chat $chatIndex";

    await storageDatabase.collection("chats").set([lastChat]);
  }

  Future removeChat() async {
    storageDatabase.collection("chats").deleteItem(lastChat);

    await chatsFile.setJson(["chat $chatIndex"], setMode: SetMode.remove);

    chatIndex -= 1;

    lastChat = "chat $chatIndex";
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Storage Database Test App")),
        body: FutureBuilder<bool>(
          future: initStorage(),
          builder: (context, snapshot) {
            return snapshot.hasData && snapshot.data == true
                ? Flex(
                    direction: Axis.vertical,
                    children: [
                      Flexible(
                        child: StreamBuilder<dynamic>(
                          stream: camFile.bytesStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            } else {
                              return Image.memory(
                                snapshot.data,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text("$error \n $stackTrace");
                                },
                              );
                              // return ListView(
                              //   children: List.generate(
                              //     snapshot.data.length,
                              //     (index) =>
                              //         Text(snapshot.data[index].toString()),
                              //   ),
                              // );
                            }
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: addChat,
                        child: const Text("Add Chat"),
                      ),
                      ElevatedButton(
                        onPressed: removeChat,
                        child: const Text("Remove Chat"),
                      )
                    ],
                  )
                : const CircularProgressIndicator();
          },
        ),
      );
}
