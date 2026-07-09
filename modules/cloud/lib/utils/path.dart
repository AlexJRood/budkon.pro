import 'package:cloud/models/folder.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void goToFolder(WidgetRef ref, CloudFolder folder, List<CloudFolder> allFolders) {
  // Zmień breadcrumbs (ścieżka do folderu)
  ref.read(selectedFolderPathProvider.notifier).state = buildPathToFolder(folder, allFolders);
  // Czyść filtr pliku w query params (to kluczowe!)
  final currentParams = ref.read(cloudExplorerParamsProvider);
  ref.read(cloudExplorerParamsProvider.notifier).state = currentParams.copyWith(
    fileType: null,
    parent: folder.id,
  );
}

/// Zwraca pełną ścieżkę od root do danego folderu
List<CloudFolder> buildPathToFolder(CloudFolder folder, List<CloudFolder> allFolders) {
  final path = <CloudFolder>[];
  CloudFolder? current = folder;
  while (current != null) {
    path.insert(0, current);
    final parentId = current.parent;
    if (parentId == null || parentId.isEmpty) break;
    current = allFolders.where((f) => f.id == parentId).cast<CloudFolder?>().firstWhere(
      (f) => true,
      orElse: () => null,
    );
  }
  return path;
}
