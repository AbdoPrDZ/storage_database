import 'explorer_directory.dart';

class ExplorerDirectoryItem {
  final String itemName;
  final dynamic item;
  final ExplorerDirectory directoryParrent;

  const ExplorerDirectoryItem(
    this.itemName,
    this.item,
    this.directoryParrent,
  );

  Type get itemType => item.runtimeType;
}
