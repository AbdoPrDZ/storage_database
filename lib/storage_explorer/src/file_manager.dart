import 'dart:typed_data';

abstract class FileManager {
  final String path;

  const FileManager(this.path);

  Future<bool> create();
  bool createSync();

  Future<bool> exists();
  bool existsSync();

  Future<String> read();
  String readSync();

  Future<Uint8List> readBytes();
  Uint8List readBytesSync();

  Future write(String data);
  void writeSync(String data);

  Future writeBytes(Uint8List bytes);
  void writeBytesSync(Uint8List bytes);

  Future<bool> delete();
  bool deleteSync();

  Future<DateTime> lastModified();
}
