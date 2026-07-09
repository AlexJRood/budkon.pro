import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';

class CloudExplorerResponse {
  final int count;
  final int foldersCount;
  final int filesCount;
  final String? next;
  final String? previous;
  final List<CloudFolder> subfolders;
  final List<CloudFile> files;

  CloudExplorerResponse({
    required this.count,
    required this.foldersCount,
    required this.filesCount,
    required this.next,
    required this.previous,
    required this.subfolders,
    required this.files,
  });

  factory CloudExplorerResponse.fromJson(Map<String, dynamic> json) {
    return CloudExplorerResponse(
      count: json['count'] ?? 0,
      foldersCount: json['folders_count'] ?? 0,
      filesCount: json['files_count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      subfolders: (json['subfolders'] as List<dynamic>?)
              ?.map((e) => CloudFolder.fromJson(e))
              .toList() ??
          [],
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => CloudFile.fromJson(e))
              .toList() ??
          [],
    );
  }
}



class CloudSidebarResponse {
  final List<CloudFolder> folders;
  final Map<String, int> fileTypeCounts;

  CloudSidebarResponse({
    required this.folders,
    required this.fileTypeCounts,
  });

  factory CloudSidebarResponse.fromJson(Map<String, dynamic> json) {
    return CloudSidebarResponse(
      folders: (json['folders'] as List<dynamic>? ?? [])
          .map((e) => CloudFolder.fromJson(e))
          .toList(),
      fileTypeCounts: Map<String, int>.from(json['file_type_counts'] ?? {}),
    );
  }
}
