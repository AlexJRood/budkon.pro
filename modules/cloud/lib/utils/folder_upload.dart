import 'dart:io';
import 'package:cloud/providers/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:core/platform/api_services.dart';

// Import your existing upload function
import 'package:cloud/api/upload.dart';

/// Represents one local file with its path relative to the picked root folder.
/// Example:
///   fullPath:     /Users/me/Desktop/MyProject/docs/a.pdf
///   relativePath: docs/a.pdf
class LocalFolderFile {
  final File file;
  final String relativePath;

  LocalFolderFile({
    required this.file,
    required this.relativePath,
  });
}

/// 1) Create a folder on backend
/// Assumed payload:
///   { "name": "...", "parent": "..." }
/// Change 'parent' to 'parent_id' if your API requires that instead.
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

  // Fallback if response is nested in some other structure
  if (data is Map && data['data'] is Map && data['data']['id'] != null) {
    return data['data']['id'].toString();
  }

  throw Exception('Folder created but no folder id returned. Response: $data');
}

/// 2) Pick a local folder path from desktop
Future<String?> pickLocalFolderPath() async {
  return await FilePicker.platform.getDirectoryPath();
}

/// 3) Scan all files inside selected local folder recursively
Future<List<LocalFolderFile>> collectFilesFromFolder(String rootFolderPath) async {
  final rootDir = Directory(rootFolderPath);

  if (!await rootDir.exists()) {
    throw Exception('Selected folder does not exist: $rootFolderPath');
  }

  final List<LocalFolderFile> result = [];

  await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final relative = p.relative(entity.path, from: rootFolderPath);

      // Normalize Windows backslashes to forward slashes
      final normalizedRelative = relative.replaceAll('\\', '/');

      result.add(
        LocalFolderFile(
          file: entity,
          relativePath: normalizedRelative,
        ),
      );
    }
  }

  return result;
}

/// 4) Create missing cloud folders for a relative folder path and return final folder id
/// Example:
///   relativeFolderPath = "docs/contracts/2026"
///
/// This will create:
///   docs
///   docs/contracts
///   docs/contracts/2026
///
/// under [rootCloudFolderId], and cache them to avoid duplicate API calls.
Future<String> ensureCloudFolderPathExists({
  required String relativeFolderPath,
  required String rootCloudFolderId,
  required dynamic ref,
  required Map<String, String> folderCache,
}) async {
  if (relativeFolderPath.trim().isEmpty) {
    return rootCloudFolderId;
  }

  final parts = relativeFolderPath
      .split('/')
      .where((e) => e.trim().isNotEmpty)
      .toList();

  String? currentParentId = rootCloudFolderId;
  String currentPath = '';

  for (final part in parts) {
    currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

    if (folderCache.containsKey(currentPath)) {
      currentParentId = folderCache[currentPath];
      continue;
    }

    final createdFolderId = await createCloudFolder(
      name: part,
      parentId: currentParentId,
      ref: ref,
    );

    folderCache[currentPath] = createdFolderId;
    currentParentId = createdFolderId;
  }

  return currentParentId!;
}

/// 5) Main function:
///    - create root folder in cloud
///    - recreate subfolder structure
///    - upload every file to correct folder
Future<void> pickAndUploadFolderTree({
  required dynamic ref,
  void Function(String message)? onStatus,
  void Function(double progress)? onProgress,
}) async {
  // Pick local folder
  final selectedFolderPath = await pickLocalFolderPath();
  if (selectedFolderPath == null || selectedFolderPath.isEmpty) {
    onStatus?.call('Folder selection cancelled.');
    return;
  }

  final rootFolderName = p.basename(selectedFolderPath);

  onStatus?.call('Scanning local folder...');
  final files = await collectFilesFromFolder(selectedFolderPath);

  if (files.isEmpty) {
    onStatus?.call('Selected folder is empty.');
    return;
  }

  onStatus?.call('Creating root folder in cloud...');
  final currentParentId = ref.read(cloudExplorerParamsProvider).parent?.toString();

  final rootCloudFolderId = await createCloudFolder(
    name: rootFolderName,
    parentId: currentParentId,
    ref: ref,
  );

  // Cache for subfolders relative to root
  // Example key: "docs/contracts"
  final Map<String, String> folderCache = {};

  int uploaded = 0;
  final total = files.length;

  for (final item in files) {
    final relativeDir = p.dirname(item.relativePath).replaceAll('\\', '/');

    String targetFolderId = rootCloudFolderId;

    // If file is in subfolder, ensure those folders exist
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
        // Overall progress:
        // completed files + current file partial progress
        final overall = (uploaded + fileProgress) / total;
        onProgress?.call(overall);
      },
    );

    uploaded++;
    onProgress?.call(uploaded / total);
  }

  onStatus?.call('Folder uploaded successfully.');
}