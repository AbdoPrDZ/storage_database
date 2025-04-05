import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'storage_database_source.dart';

class SecureStorageSource extends StorageDatabaseSource {
  final File _source;
  final String _sourcePassword;

  SecureStorageSource(this._source, this._sourcePassword);

  // 16 bytes for AES-128
  static String _appIV = 'AbdoPrDZ@2132025';

  static Future<SecureStorageSource> instance(
    String sourcePath,
    String sourcePassword, {
    String? appIV,
  }) async {
    if (appIV != null && appIV.length != 16) {
      throw Exception('IV must be 16 bytes long');
    }

    if (appIV != null) _appIV = appIV;

    final sourceDirParts = sourcePath.split('/');
    String sourceDirPath = sourceDirParts
        .sublist(0, sourceDirParts.length - 1)
        .join('/');

    Directory sourceDir = Directory(sourceDirPath);
    if (!await sourceDir.exists()) sourceDir = await sourceDir.create();

    File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) sourceFile = await sourceFile.create();

    String fileContent = await sourceFile.readAsString();
    if (fileContent.isNotEmpty) {
      try {
        decryptData(fileContent, sourcePassword);
      } catch (e) {
        throw Exception('Invalid Password');
      }
    } else {
      sourceFile = await sourceFile.writeAsString(
        encryptData('{}', sourcePassword),
      );
    }

    return SecureStorageSource(sourceFile, sourcePassword);
  }

  static IV iv = IV.fromUtf8(_appIV);

  static Encrypter encrypter(String password) =>
      Encrypter(AES(Key.fromUtf8(password.padLeft(32)), mode: AESMode.cbc));

  static String encryptData(String data, String password) =>
      encrypter(password).encrypt(data, iv: iv).base64;

  static String decryptData(String crypto, String password) =>
      encrypter(password).decrypt(Encrypted.fromBase64(crypto), iv: iv);

  Timer? _cacheTimer;
  void setupCacheTimer() {
    _cacheTimer?.cancel();
    _cacheTimer = Timer(const Duration(seconds: 5), () {
      _cacheData = null;
      _cacheTimer = null;
    });
  }

  Map? _cacheData;
  Future<Map> get getFileData async {
    if (_cacheData == null) {
      String content = await _source.readAsString();
      try {
        _cacheData = Map.from(
          jsonDecode(decryptData(content, _sourcePassword)),
        );
      } catch (e) {
        await setFileData({});
        _cacheData = {};
      }
    }
    setupCacheTimer();
    return _cacheData!;
  }

  Future setFileData(Map data) =>
      _source.writeAsString(encryptData(jsonEncode(data), _sourcePassword));

  @override
  Future setData(String id, data) async {
    Map sourceData = await getFileData;
    sourceData[id] = data;
    await setFileData(sourceData);
  }

  @override
  Future getData(String id) async {
    Map sourceData = await getFileData;
    return sourceData[id];
  }

  @override
  Future<bool> containsKey(String id) async {
    Map sourceData = await getFileData;
    return sourceData.containsKey(id);
  }

  @override
  Future remove(String id) async {
    Map sourceData = await getFileData;
    sourceData.remove(id);
    await setFileData(sourceData);
  }

  @override
  Future clear() => setFileData({});
}
