import 'package:core/platform/enum/cloud_item_ref.dart';
import 'package:core/platform/provider/cloud_selection_state.dart';

class CloudDragPayload {
  final List<String> files;
  final List<String> folders;

  CloudDragPayload({required this.files, required this.folders});

  factory CloudDragPayload.fromSelection(CloudSelectionState s) {
    return CloudDragPayload(
      files: s.selectedFileIds.toList(),
      folders: s.selectedFolderIds.toList(),
    );
  }

  Map<String, dynamic> toJson() => {'files': files, 'folders': folders};

  factory CloudDragPayload.fromJson(Map<String, dynamic> json) {
    return CloudDragPayload(
      files: List<String>.from(json['files'] ?? []),
      folders: List<String>.from(json['folders'] ?? []),
    );
  }
}

CloudDragPayload payloadForDrag(CloudSelectionState s, CloudItemRef item) {
  final isSelected =
      item.kind == CloudItemKind.file
          ? s.selectedFileIds.contains(item.id)
          : s.selectedFolderIds.contains(item.id);

  if (isSelected) return CloudDragPayload.fromSelection(s);

  return CloudDragPayload(
    files: item.kind == CloudItemKind.file ? [item.id] : [],
    folders: item.kind == CloudItemKind.folder ? [item.id] : [],
  );
}
