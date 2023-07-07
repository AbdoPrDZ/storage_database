// CLients
import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../storage_database.dart';

export './laravel_echo_migration.dart';
export 'package:laravel_echo_null/laravel_echo_null.dart';

class LaravelEcho<ClientType, ChannelType>
    extends Echo<ClientType, ChannelType> {
  StorageDatabase storageDatabase;

  LaravelEcho(this.storageDatabase, super.connector);

  setupMigrations(List<LaravelEchoMigration> migrations) {
    for (LaravelEchoMigration migration in migrations) {
      if (migration.eventsNames.containsKey(EventsType.create)) {
        migration.channel.listen(
          migration.eventsNames[EventsType.create]!,
          migration.onCreate,
        );
      }
      if (migration.eventsNames.containsKey(EventsType.update)) {
        migration.channel.listen(
          migration.eventsNames[EventsType.update]!,
          migration.onUpdate,
        );
      }
      if (migration.eventsNames.containsKey(EventsType.delete)) {
        migration.channel.listen(
          migration.eventsNames[EventsType.delete]!,
          migration.onDelete,
        );
      }
    }
  }

  static LaravelEcho<Socket, SocketIoChannel> socket(
    StorageDatabase storageDatabase,
    String host, {
    Map? auth,
    String? authEndpoint,
    String? key,
    String? namespace,
    bool autoConnect = false,
    Map moreOptions = const {},
  }) =>
      LaravelEcho<Socket, SocketIoChannel>(
          storageDatabase,
          SocketIoConnector(
            io(host, {'autoConnect': autoConnect, ...moreOptions}),
            auth: auth,
            authEndpoint: authEndpoint,
            host: host,
            key: key,
            namespace: namespace,
            autoConnect: autoConnect,
            moreOptions: moreOptions,
          ));

  static LaravelEcho<PusherClient, PusherChannel> pusher(
    StorageDatabase storageDatabase,
    String appKey,
    PusherOptions options, {
    Map? auth,
    String? authEndpoint,
    String? host,
    String? key,
    String? namespace,
    bool autoConnect = true,
    bool enableLogging = true,
    Map moreOptions = const {},
  }) =>
      LaravelEcho<PusherClient, PusherChannel>(
        storageDatabase,
        PusherConnector(
          PusherClient(
            appKey,
            options,
            autoConnect: autoConnect,
            enableLogging: enableLogging,
          ),
          auth: auth,
          authEndpoint: authEndpoint,
          host: host,
          key: key,
          namespace: namespace,
          autoConnect: autoConnect,
          moreOptions: moreOptions,
        ),
      );
}
