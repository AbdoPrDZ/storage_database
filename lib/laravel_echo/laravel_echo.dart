import 'dart:typed_data';

import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../src/storage_database_exception.dart';
import '../storage_database.dart';

export 'package:laravel_echo_null/laravel_echo_null.dart';
export './laravel_echo_migration.dart';

class LaravelEcho<ClientType, ChannelType>
    extends Echo<ClientType, ChannelType> {
  final StorageDatabase storageDatabase;

  List<LaravelEchoMigration> migrations;

  LaravelEcho(
    this.storageDatabase,
    super.connector, {
    this.migrations = const [],
  }) : assert(
         ClientType == Socket || ClientType == PusherClient,
         'ClientType must be either Socket or PusherClient',
       ),
       assert(
         ChannelType == SocketIoChannel || ChannelType == PusherChannel,
         'ChannelType must be either SocketIoChannel or PusherChannel',
       ),
       assert(
         ClientType == Socket && ChannelType == SocketIoChannel ||
             ClientType == PusherClient && ChannelType == PusherChannel,
         'ClientType and ChannelType must be either Socket and SocketIoChannel or PusherClient and PusherChannel',
       ) {
    connector.onConnect((data) => _setupMigrations());

    if (ClientType == Socket) {
      _socketInstance = this as LaravelEcho<Socket, SocketIoChannel>;
    } else if (ClientType == PusherClient) {
      _pusherInstance = this as LaravelEcho<PusherClient, PusherChannel>;
    }
  }

  static LaravelEcho<Socket, SocketIoChannel>? _socketInstance;
  static bool get hasSocketInstance => _socketInstance != null;
  static LaravelEcho<Socket, SocketIoChannel> get socketInstance {
    if (!hasSocketInstance) {
      throw const StorageDatabaseException(
        'LaravelEcho socket instance has not initialized yet',
      );
    }

    return _socketInstance!;
  }

  static LaravelEcho<PusherClient, PusherChannel>? _pusherInstance;
  static bool get hasPusherInstance => _pusherInstance != null;
  static LaravelEcho<PusherClient, PusherChannel> get pusherInstance {
    if (!hasPusherInstance) {
      throw const StorageDatabaseException(
        'LaravelEcho pusher instance has not initialized yet',
      );
    }

    return _pusherInstance!;
  }

  static bool get hasInstance => hasSocketInstance || hasPusherInstance;

  static LaravelEcho get instance {
    if (hasSocketInstance) {
      return socketInstance;
    } else if (hasPusherInstance) {
      return pusherInstance;
    } else {
      throw const StorageDatabaseException(
        'LaravelEcho instance has not initialized yet',
      );
    }
  }

  void removeMigration(LaravelEchoMigration migration) {
    migration.channel.unsubscribe();
    migrations.remove(migration);
  }

  void _setupMigrations() {
    for (LaravelEchoMigration migration in migrations) {
      migration.setup();
    }
  }

  static LaravelEcho<Socket, SocketIoChannel> socket(
    StorageDatabase storageDatabase,
    String host,
    List<LaravelEchoMigration> migrations, {
    Map<String, String>? authHeaders,
    String? nameSpace,
    bool autoConnect = true,
    Map moreOptions = const {},
    Map<String, dynamic> Function(String, Map<dynamic, dynamic>)?
    channelDecryption,
  }) => LaravelEcho<Socket, SocketIoChannel>(
    storageDatabase,
    SocketIoConnector(
      host,
      authHeaders: authHeaders,
      namespace: nameSpace,
      autoConnect: autoConnect,
      moreOptions: moreOptions,
      channelDecryption: channelDecryption,
    ),
    migrations: migrations,
  );

  static LaravelEcho<PusherClient, PusherChannel> pusher(
    StorageDatabase storageDatabase,
    String appKey,
    List<LaravelEchoMigration> migrations, {
    required String authEndPoint,
    Map<String, String> authHeaders = const {
      'Content-Type': 'application/json',
    },
    String? cluster,
    String? host,
    Map<String, dynamic> Function(Uint8List, Map<String, dynamic>)?
    channelDecryption,
    int wsPort = 80,
    int wssPort = 443,
    bool encrypted = true,
    int activityTimeout = 120000,
    int pongTimeout = 30000,
    int maxReconnectionAttempts = 6,
    Duration reconnectGap = const Duration(seconds: 2),
    bool enableLogging = true,
    bool autoConnect = true,
    String? nameSpace,
  }) => LaravelEcho<PusherClient, PusherChannel>(
    storageDatabase,
    PusherConnector(
      appKey,
      authEndPoint: authEndPoint,
      authHeaders: authHeaders,
      cluster: cluster,
      host: host,
      channelDecryption: channelDecryption,
      wsPort: wsPort,
      wssPort: wssPort,
      encrypted: encrypted,
      activityTimeout: activityTimeout,
      pongTimeout: pongTimeout,
      maxReconnectionAttempts: maxReconnectionAttempts,
      reconnectGap: reconnectGap,
      enableLogging: enableLogging,
      autoConnect: autoConnect,
      nameSpace: nameSpace,
    ),
    migrations: migrations,
  );

  @override
  void disconnect() {
    for (var migration in migrations) {
      migration.delete();
    }
    migrations.clear();
    if (ClientType == Socket) {
      _socketInstance = null;
    } else if (ClientType == PusherClient) {
      _pusherInstance = null;
    }
    super.disconnect();
  }
}
