// CLients
import 'dart:typed_data';

import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../storage_database.dart';

export './laravel_echo_migration.dart';
export 'package:laravel_echo_null/laravel_echo_null.dart';

class LaravelEcho<ClientType, ChannelType>
    extends Echo<ClientType, ChannelType> {
  final StorageDatabase storageDatabase;

  List<LaravelEchoMigration> migrations;

  LaravelEcho(this.storageDatabase, super.connector, this.migrations) {
    connector.onConnect((data) => _setupMigrations());
  }

  removeMigration(LaravelEchoMigration migration) {
    migration.channel.unsubscribe();
    migrations.remove(migration);
  }

  _setupMigrations() {
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
  }) =>
      LaravelEcho<Socket, SocketIoChannel>(
        storageDatabase,
        SocketIoConnector(
          host,
          authHeaders: authHeaders,
          namespace: nameSpace,
          autoConnect: autoConnect,
          moreOptions: moreOptions,
        ),
        migrations,
      );

  static LaravelEcho<PusherClient, PusherChannel> pusher(
    StorageDatabase storageDatabase,
    String appKey,
    List<LaravelEchoMigration> migrations, {
    required String authEndPoint,
    Map<String, String> authHeaders = const {
      'Content-Type': 'application/json'
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
  }) =>
      LaravelEcho<PusherClient, PusherChannel>(
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
        migrations,
      );

  @override
  void disconnect() {
    for (var migration in migrations) {
      migration.delete();
    }
    super.disconnect();
  }
}
