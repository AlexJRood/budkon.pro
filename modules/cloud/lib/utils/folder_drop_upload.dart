import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:core/platform/api_services.dart';
import 'package:cloud/api/upload.dart';

class LocalFolderFile {
  final File file;
  final String relativePath;

  LocalFolderFile({
    required this.file,
    required this.relativePath,
  });
}

Future<String> createCloudFolder({
  required String name,
  String? parentId,
  required dynamic ref,
}) async {
  final resp = await ApiServices.post(
    'https://www.superbee.cloud/storage/folders/',
    hasToken: true,
    data: {
      'name': name,
      if (parentId != null) 'parent': parentId,
    },
    ref: ref,
  );

  if (resp == null || (resp.statusCode ?? 500) >= 400) {
    throw Exception('Create folder failed: ${resp?.statusCode} ${resp?.data}');
  }

  final data = resp.data;

  if (data is Map && data['id'] != null) {
    return data['id'].toString();
  }

  if (data is Map && data['data'] is Map && data['data']['id'] != null) {
    return data['data']['id'].toString();
  }

  throw Exception('Folder created but id not returned: $data');
}

Future<List<LocalFolderFile>> collectFilesFromDirectory(String rootPath) async {
  final dir = Directory(rootPath);

  if (!await dir.exists()) {
    throw Exception('Directory not found: $rootPath');
  }

  final result = <LocalFolderFile>[];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final relative = p.relative(entity.path, from: rootPath).replaceAll('\\', '/');
      result.add(LocalFolderFile(file: entity, relativePath: relative));
    }
  }

  return result;
}

Future<String> ensureCloudFolderPathExists({
  required String relativeFolderPath,
  required String rootCloudFolderId,
  required dynamic ref,
  required Map<String, String> folderCache,
}) async {
  if (relativeFolderPath.trim().isEmpty || relativeFolderPath == '.') {
    return rootCloudFolderId;
  }

  final parts = relativeFolderPath
      .split('/')
      .where((e) => e.trim().isNotEmpty)
      .toList();

  String currentPath = '';
  String currentParentId = rootCloudFolderId;

  for (final part in parts) {
    currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

    final cached = folderCache[currentPath];
    if (cached != null) {
      currentParentId = cached;
      continue;
    }

    final newId = await createCloudFolder(
      name: part,
      parentId: currentParentId,
      ref: ref,
    );

    folderCache[currentPath] = newId;
    currentParentId = newId;
  }

  return currentParentId;
}

/// Uploads a dropped desktop folder path into cloud storage.
/// If [parentCloudFolderId] is set, the dropped folder is created inside that cloud folder.
Future<void> uploadDroppedDirectory({
  required String localDirectoryPath,
  required dynamic ref,
  String? parentCloudFolderId,
  void Function(String message)? onStatus,
  void Function(double progress)? onProgress,
}) async {
  final rootName = p.basename(localDirectoryPath);

  onStatus?.call('Scanning folder: $rootName');
  final files = await collectFilesFromDirectory(localDirectoryPath);

  if (files.isEmpty) {
    onStatus?.call('Folder is empty');
    return;
  }

  onStatus?.call('Creating root folder: $rootName');
  final rootCloudFolderId = await createCloudFolder(
    name: rootName,
    parentId: parentCloudFolderId,
    ref: ref,
  );

  final folderCache = <String, String>{};

  int uploaded = 0;
  final total = files.length;

  for (final item in files) {
    final relativeDir = p.dirname(item.relativePath).replaceAll('\\', '/');

    String targetFolderId = rootCloudFolderId;

    if (relativeDir != '.' && relativeDir.trim().isNotEmpty) {
      targetFolderId = await ensureCloudFolderPathExists(
        relativeFolderPath: relativeDir,
        rootCloudFolderId: rootCloudFolderId,
        ref: ref,
        folderCache: folderCache,
      );
    }

    onStatus?.call('Uploading ${item.relativePath}');

    await uploadFileToCloud(
      file: item.file,
      uploadUrl: 'https://www.superbee.cloud/storage/upload/',
      folderId: targetFolderId,
      ref: ref,
      onProgress: (fileProgress) {
        final overall = (uploaded + fileProgress) / total;
        onProgress?.call(overall);
      },
    );

    uploaded++;
    onProgress?.call(uploaded / total);
  }

  onStatus?.call('Folder uploaded successfully');
}

/// Detect whether dropped XFile is a file or directory on desktop.
/// Returns:
/// - 'file'
/// - 'directory'
/// - 'unknown'
Future<String> getDroppedEntryKind(XFile xfile) async {
  final path = xfile.path;
  if (path.isEmpty) return 'unknown';

  final type = await FileSystemEntity.type(path, followLinks: false);

  switch (type) {
    case FileSystemEntityType.file:
      return 'file';
    case FileSystemEntityType.directory:
      return 'directory';
    default:
      return 'unknown';
  }
}