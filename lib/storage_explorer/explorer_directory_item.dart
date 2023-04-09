import 'explorer_directory.dart';

class ExplorerDirectoryItem {
  final String itemName;
  final dynamic item;
  final ExplorerDirectory directoryParent;

  const ExplorerDirectoryItem(
    this.itemName,
    this.item,
    this.directoryParent,
  );

  Type get itemType => item.runtimeType;
}
