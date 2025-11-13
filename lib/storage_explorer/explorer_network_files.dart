import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../src/storage_database_exception.dart';
import 'storage_explorer.dart';

class ExplorerNetworkFiles {
  final StorageExplorer storageExplorer;
  final ExplorerDirectory networkDirFiles;

  ExplorerNetworkFiles(this.storageExplorer, this.networkDirFiles) {
    _instance = this;
  }

  static ExplorerNetworkFiles? _instance;

  static bool get hasInstance => _instance != null;

  static ExplorerNetworkFiles get instance {
    if (!hasInstance) {
      throw const StorageDatabaseException(
        'ExplorerNetworkFiles instance has not initialized yet',
      );
    }

    return _instance!;
  }

  String encodeUrl(String url) => utf8.fuse(base64).encode(url);

  String decodeUrl(String code) => utf8.fuse(base64).decode(code);

  Future<ExplorerFile?> file(
    String url, {
    bool refresh = false,
    Map<String, String> headers = const {},
    bool getOldOnError = false,
    bool log = false,
  }) async {
    String encodedUrl = encodeUrl(url);
    ExplorerFile file = networkDirFiles.file(encodedUrl);

    if (log) {
      dev.log('[StorageExplorer.NetworkFile] reqUrl: $url');
      dev.log('[StorageExplorer.NetworkFile] reqEncodedUrl: $encodedUrl');
    }

    if (!file.exists || refresh) {
      if (log) dev.log('[StorageExplorer.NetworkFile] reqHeaders: $headers');

      Uint8List? fileData = await downloadFile(
        Uri.parse(url),
        log: log,
        headers: headers,
      );

      if (fileData != null) {
        await file.setBytes(fileData);
      } else if (!file.exists && !getOldOnError) {
        return null;
      }
    }
    return file;
  }

  Future<Uint8List?> downloadFile(
    Uri uri, {
    Map<String, String> headers = const {},
    bool log = false,
  }) async {
    http.Response response = (await http.get(uri, headers: headers));

    if (response.statusCode == 200) {
      if (log) dev.log("[StorageExplorer.NetworkFile] success");

      return response.bodyBytes;
    } else {
      if (log) {
        dev.log(
          "[StorageExplorer.NetworkFile] resCode: ${response.statusCode}",
        );
        dev.log("[StorageExplorer.NetworkFile] resBody: ${response.body}");
      }

      return null;
    }
  }

  Future clear() => networkDirFiles.clear();
}
