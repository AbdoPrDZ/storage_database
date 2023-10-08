import 'directory_manager.dart';
import 'file_manager.dart';

abstract class ExplorerSource {
  DirectoryManager dir(String path);
  FileManager file(String path);
}
