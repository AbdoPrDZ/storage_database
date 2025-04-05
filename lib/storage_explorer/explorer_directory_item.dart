import 'explorer_directory.dart';
import 'explorer_file.dart';

class ExplorerDirectoryItem<T> {
  final String itemName;
  final T item;
  final ExplorerDirectory directoryParent;

  const ExplorerDirectoryItem(this.itemName, this.item, this.directoryParent)
    : assert(item is ExplorerFile || item is ExplorerDirectory);

  Type get itemType => item.runtimeType;
}
