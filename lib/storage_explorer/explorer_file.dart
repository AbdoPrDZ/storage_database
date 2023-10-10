import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'dart:typed_data';

import '../src/storage_database_exception.dart';
import '../src/values.dart';
import '../src/storage_listeners.dart';
import 'src/explorer_source.dart';
import 'src/file_manager.dart';

class ExplorerFile {
  final ExplorerSource explorerSource;
  FileManager ioFile;
  final String dirPath, filename;
  final StorageListeners storageListeners;

  ExplorerFile(this.explorerSource, this.ioFile, this.dirPath, this.filename,
      this.storageListeners);

  bool get exists => ioFile.existsSync();

  String get path => ioFile.path;

  Future<String> get({String? streamId}) async {
    if (!exists) {
      throw StorageDatabaseException("The file ($filename) not exists yet.");
    }

    String data = await ioFile.read();
    if (streamId != null &&
        storageListeners.hasStreamId(_fileShortPath, streamId)) {
      storageListeners.getDate(_fileShortPath, streamId);
    }
    return data;
  }

  Future<Uint8List> getBytes({String? streamId}) async {
    if (!exists) {
      throw StorageDatabaseException("The file ($filename) not exists yet.");
    }
    if (streamId != null &&
        storageListeners.hasStreamId(_fileShortPath, streamId)) {
      storageListeners.getDate(_fileShortPath, streamId);
    }
    return await ioFile.readBytes();
  }

  Future<T?> getJson<T>({String? streamId}) async {
    if (!exists) {
      throw StorageDatabaseException("The file ($filename) not exists yet.");
    }
    try {
      String strData = await get(streamId: streamId);
      if (strData.isNotEmpty) {
        return jsonDecode(strData);
      } else {
        return null;
      }
    } catch (e) {
      dev.log("DecodeError: $e");
      throw StorageDatabaseException("Can't decode file ($filename) content.");
    }
  }

  Future set(
    var data, {
    bool log = true,
    bool append = false,
    String appendSplit = "\n",
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    if (data.runtimeType != String) {
      data = data.toString();
    }

    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(_fileShortPath)) {
        if (storageListeners.hasStreamId(_fileShortPath, streamId)) {
          storageListeners.getDate(_fileShortPath, streamId);
        }
      }
    }
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(dirPath)) {
        if (storageListeners.hasStreamId(dirPath, streamId)) {
          storageListeners.getDate(dirPath, streamId);
        }
      }
    }
    if (append) {
      String currentData = await get();
      data = "$currentData$appendSplit$data";
    }

    ioFile = await ioFile.write(data);
  }

  Future setJson(
    dynamic data, {
    bool log = true,
    SetMode setMode = SetMode.append,
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    dynamic currentData = await getJson();
    if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType.toString().contains("Map") &&
        data.runtimeType.toString().contains("Map")) {
      for (var key in data.keys) {
        if (setMode == SetMode.append) {
          currentData[key] = data[key];
        } else if (setMode == SetMode.remove && currentData.containsKey(key)) {
          currentData.remove(key);
        }
      }
    } else if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType.toString().contains("List") &&
        data.runtimeType.toString().contains("List")) {
      for (var item in data) {
        if (!currentData.contains(item) && setMode == SetMode.append) {
          currentData.add(item);
        } else if (currentData.contains(item) && setMode == SetMode.remove) {
          currentData.remove(item);
        }
      }
    } else if (setMode != SetMode.replace &&
        currentData != null &&
        currentData.runtimeType != data.runtimeType) {
      throw const StorageDatabaseException("Can't append different data");
    } else {
      currentData = data;
    }
    await set(
      jsonEncode(currentData),
      log: log,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  Future setBytes(
    Uint8List bytes, {
    bool log = true,
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    ioFile = await ioFile.writeBytes(bytes);
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(_fileShortPath)) {
        if (storageListeners.hasStreamId(_fileShortPath, streamId)) {
          storageListeners.getDate(_fileShortPath, streamId);
        }
      }
    }
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(dirPath)) {
        if (storageListeners.hasStreamId(dirPath, streamId)) {
          storageListeners.getDate(dirPath, streamId);
        }
      }
    }
  }

  Future delete({bool log = true}) async {
    await ioFile.delete();
    if (log) {
      for (var streamId in storageListeners.getPathStreamIds(_fileShortPath)) {
        if (storageListeners.hasStreamId(_fileShortPath, streamId)) {
          storageListeners.getDate(_fileShortPath, streamId);
        }
      }
    }
  }

  String get _fileShortPath => "$dirPath/$filename";

  Stream<String?> stream(
          {Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream<String>(delayCheck, StreamMode.string);

  Stream<T?> jsonStream<T>(
          {Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream<T>(delayCheck, StreamMode.json);

  Stream<Uint8List?> bytesStream(
          {Duration delayCheck = const Duration(milliseconds: 50)}) =>
      _stream<Uint8List>(delayCheck, StreamMode.bytes);

  String get randomStreamId => String.fromCharCodes(
        List.generate(8, (index) => Random().nextInt(33) + 89),
      );

  Stream<T?> _stream<T>(Duration delayCheck, StreamMode streamMode) async* {
    String streamId = randomStreamId;
    storageListeners.initStream(_fileShortPath, streamId);
    while (true) {
      await Future.delayed(delayCheck);
      Map dates = storageListeners.getDates(_fileShortPath, streamId);
      int lastModified = (await ioFile.lastModified()).microsecondsSinceEpoch;
      if (dates["set_date"] >= dates["get_date"] ||
          lastModified >= dates["get_date"]) {
        storageListeners.setDate(
          _fileShortPath,
          streamId,
          microseconds: lastModified,
        );
        if (streamMode == StreamMode.json) {
          yield await getJson<T>();
        }
        if (streamMode == StreamMode.bytes) {
          yield await getBytes() as T?;
        } else {
          yield await get() as T?;
        }
      }
    }
  }
}
