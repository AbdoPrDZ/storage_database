import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import '../storage_database.dart';
import 'storage_cache.dart';

class EncryptedStorageSource extends StorageDatabaseSource {
  final Directory _sourceDir;
  final String _sourcePassword, _sourceFileName;
  final IV _iv;

  late StorageCache _cache;

  EncryptedStorageSource(
    this._sourceDir,
    this._sourceFileName,
    this._sourcePassword,
    this._iv,
  ) {
    _cache = StorageCache<Map>(
      data: {},
      expiredData: {},
      source: () => _fileData,
    );
  }

  File get _source => File("${_sourceDir.path}/$_sourceFileName");

  static Future<EncryptedStorageSource> getInstance(
    String sourcePath,
    String sourcePassword, {
    String iv = "dz.abdo_pr.flutter.packages.sd23",
    String sourceFileName = "source.sd",
  }) async {
    IV _iv = IV.fromUtf8(iv);
    Directory source = Directory(sourcePath);
    if (!await source.exists()) source = await source.create();

    File sourceFile = File('$sourcePath/$sourceFileName');
    if (!await sourceFile.exists()) sourceFile = await sourceFile.create();

    String fileContent = await sourceFile.readAsString();
    if (fileContent.isNotEmpty) {
      try {
        decryptData(fileContent, sourcePassword, _iv);
      } catch (e) {
        throw Exception('Invalid Password');
      }
    } else {
      sourceFile = await sourceFile
          .writeAsString(encryptData('{}', sourcePassword, _iv));
    }

    return EncryptedStorageSource(source, sourceFileName, sourcePassword, _iv);
  }

  static Encrypter encrypter(String password) => Encrypter(AES(
        Key.fromUtf8(password.padLeft(32)),
        mode: AESMode.cbc,
      ));

  static String encryptData(String data, String password, IV iv) =>
      encrypter(password).encrypt(data, iv: iv).base64;

  static String decryptData(String crypto, String password, IV iv) =>
      encrypter(password).decrypt(Encrypted.fromBase64(crypto), iv: iv);

  Future<Map> get _fileData async => Map.from(jsonDecode(decryptData(
        await _source.readAsString(),
        _sourcePassword,
        _iv,
      )));

  Future setFileData(Map data) async {
    _cache.hasData = false;
    await _source.writeAsString(encryptData(
      jsonEncode(data),
      _sourcePassword,
      _iv,
    ));
  }

  @override
  Future setData(String id, data) async {
    Map sourceData = await _cache.getData();
    sourceData[id] = data;
    await setFileData(sourceData);
  }

  @override
  Future getData(String id) async {
    Map sourceData = await _cache.getData();
    return sourceData[id];
  }

  @override
  Future<bool> containsKey(String id) async {
    Map sourceData = await _cache.getData();
    return sourceData.containsKey(id);
  }

  @override
  Future remove(String id) async {
    Map sourceData = await _cache.getData();
    sourceData.remove(id);
    await setFileData(sourceData);
  }

  @override
  Future clear() => setFileData({});
}
