// cloud/api/move.dart

import 'dart:developer';

import 'package:cloud/models/file.dart';
import 'package:cloud/models/folder.dart';
import 'package:cloud/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/platform/api_services.dart';

class CloudMoveResult {
  final bool success;
  final String message;

  const CloudMoveResult({
    required this.success,
    required this.message,
  });
}

void _refreshCloudAfterMove(WidgetRef ref) {
  ref.read(cloudSidebarRefreshTriggerProvider.notifier).state++;
  ref.read(cloudExplorerRefreshTriggerProvider.notifier).state++;
  ref.read(clientExplorerRefreshTriggerProvider.notifier).state++;

  ref.invalidate(cloudSidebarProvider);
  ref.invalidate(cloudExplorerProvider);
  ref.invalidate(clientCloudExplorerProvider);
  ref.invalidate(storageQuotaProvider);
}

bool _isSuccessStatus(dynamic response) {
  final code = response?.statusCode;
  return code != null && code >= 200 && code < 300;
}

String _extractErrorMessage(dynamic response) {
  try {
    final dynamic body = response?.body ?? response?.data;

    if (body is Map) {
      if (body['detail'] != null) return body['detail'].toString();
      if (body['message'] != null) return body['message'].toString();
      if (body['error'] != null) return body['error'].toString();

      if (body.isNotEmpty) {
        final firstValue = body.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) {
          return firstValue.toString();
        }
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }
  } catch (_) {}

  final code = response?.statusCode;
  return 'unknown error${code != null ? ' ($code)' : ''}';
}

Future<CloudMoveResult> moveFileToFolder(
  WidgetRef ref,
  CloudFile file,
  CloudFolder targetFolder,
) async {
  final String? sourceFolderId = file.folderId;
  final String targetFolderId = targetFolder.id;

  if (sourceFolderId == targetFolderId) {
    return CloudMoveResult(
      success: true,
      message: 'file_already_in_this_folder'.tr,
    );
  }

  try {
    final response = await ApiServices.patch(
      'https://www.superbee.cloud/storage/files/${file.id}/',
      hasToken: true,
      data: {'folder': targetFolderId},
    );

    if (_isSuccessStatus(response)) {
      _refreshCloudAfterMove(ref);

      return CloudMoveResult(
        success: true,
         message: 'moved_file_to_folder'.tr + file.name + 'moved_file_to_folder_middle'.tr + targetFolder.name + 'moved_file_to_folder_end'.tr
      );
    }

    return CloudMoveResult(
      success: false,
      message: 'error_moving_file'.tr + _extractErrorMessage(response)
    );
  } catch (e, stackTrace) {
    log(
      'moveFileToFolder failed',
      error: e,
      stackTrace: stackTrace,
    );

    return CloudMoveResult(
      success: false,
       message: 'error_moving_file'.tr + e.toString(),
    );
  }
}

Future<CloudMoveResult> moveFolderToFolder(
  WidgetRef ref,
  CloudFolder moved,
  CloudFolder target, {
  List<CloudFolder>? allFolders,
}) async {
  final String? sourceParentId = moved.parent;
  final String targetParentId = target.id;

  if (moved.id == target.id) {
    return CloudMoveResult(
      success: false,
      message: 'cannot_move_folder_to_itself'.tr,
    );
  }

  if (sourceParentId == targetParentId) {
    return CloudMoveResult(
      success: true,
      message: 'folder_already_in_this_location'.tr,
    );
  }

  if (allFolders != null && isDescendant(moved, target, allFolders)) {
    return CloudMoveResult(
      success: false,
      message: 'cannot_move_folder_to_own_subfolder'.tr,
    );
  }

  try {
    final response = await ApiServices.patch(
      'https://www.superbee.cloud/storage/folders/${moved.id}/',
      hasToken: true,
      data: {'parent': targetParentId},
    );

    if (_isSuccessStatus(response)) {
      _refreshCloudAfterMove(ref);

      return CloudMoveResult(
        success: true,
         message: 'moved_folder_to_folder'.trParams({
                  'folderName': moved.name,
                  'targetName': target.name,
                  }),
      );
    }

    return CloudMoveResult(
      success: false,
      message: 'error_moving_folder'.tr + _extractErrorMessage(response)
    );
  } catch (e, stackTrace) {
    log(
      'moveFolderToFolder failed',
      error: e,
      stackTrace: stackTrace,
    );

    return CloudMoveResult(
      success: false,
      message: 'error_moving_folder'.tr + e.toString(),
    );
  }
}

/// Checks whether [target] is a descendant of [moved]
/// (or the same folder).
bool isDescendant(
  CloudFolder moved,
  CloudFolder target,
  List<CloudFolder> all,
) {
  if (moved.id == target.id) return true;

  CloudFolder? current = target;

  while (current != null &&
      current.parent != null &&
      current.parent!.isNotEmpty) {
    if (current.parent == moved.id) return true;

    final parentId = current.parent;
    final index = all.indexWhere((f) => f.id == parentId);

    if (index == -1) break;
    current = all[index];
  }

  return false;
}

final CloudFolder rootFolder = CloudFolder(
  id: 'root',
  name: 'Cloud Storage'.tr,
  filesCount: 0,
);