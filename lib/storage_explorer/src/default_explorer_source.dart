import 'default_directory_manager.dart';
import 'default_file_manager.dart';
import 'directory_manager.dart';
import 'explorer_source.dart';
import 'file_manager.dart';

export 'default_directory_manager.dart';
export 'default_file_manager.dart';

class DefaultExplorerSource extends ExplorerSource {
  @override
  DirectoryManager dir(String path) => DefaultDirectoryManager(path);

  @override
  FileManager file(String path) => DefaultFileManager(path);
}
