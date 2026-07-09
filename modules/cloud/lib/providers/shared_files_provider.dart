import 'dart:convert';
import 'package:cloud/cloud_urls.dart';

import 'package:cloud/widgets/share_file_dialog.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:cloud/models/file_share_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/material.dart';

class SharedFilesNotifier extends StateNotifier<SharedFilesState> {
  SharedFilesNotifier(this.ref) : super(SharedFilesState.initial());

  final Ref ref;

  Future<void> fetchSharedFiles({
    int page = 1,
    int pageSize = 20,
    String? ordering,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;
    if (state.initialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiServices.get(
        CloudUrls.filaShares,
        ref: ref,
        hasToken: true,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (ordering != null && ordering.trim().isNotEmpty)
            'ordering': ordering,
        },
      );

      if (response == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch shared files.',
          initialized: true,
        );
        return;
      }

      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed with status ${response.statusCode}',
          initialized: true,
        );
        return;
      }

      final raw = response.data;
      Map<String, dynamic> map;

      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      } else if (raw is List<int>) {
        map = json.decode(utf8.decode(raw)) as Map<String, dynamic>;
      } else if (raw is String) {
        map = json.decode(raw) as Map<String, dynamic>;
      } else {
        throw Exception('Unsupported response format: ${raw.runtimeType}');
      }

      final rawResults = map['results'];
      final list = rawResults is List
          ? rawResults
          .whereType<Map>()
          .map((e) => FileShare.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : <FileShare>[];

      state = state.copyWith(
        isLoading: false,
        items: list,
        count: map['count'] is int
            ? map['count'] as int
            : int.tryParse('${map['count']}') ?? list.length,
        next: map['next']?.toString(),
        previous: map['previous']?.toString(),
        initialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        initialized: true,
      );
    }
  }

  Future<void> refresh() async {
    await fetchSharedFiles(forceRefresh: true);
  }

  void resetDialogState() {
    ref.invalidate(shareDialogTargetTypeProvider);
    ref.invalidate(shareDialogSelectedOptionIdProvider);
    ref.invalidate(shareDialogEmailProvider);
    ref.invalidate(shareDialogSearchQueryProvider);
    ref.invalidate(shareDialogInlinePickerOpenProvider);
    ref.invalidate(shareDialogStepProvider);
    ref.invalidate(shareDialogCanEditProvider);
    ref.invalidate(shareDialogNoteProvider);
    ref.invalidate(shareDialogExpiresAtProvider);
    ref.invalidate(shareDialogSubmitLoadingProvider);
    ref.invalidate(shareDialogSubmitErrorProvider);
  }

  Future<void> submitShare({
    required BuildContext context,
    required String resourceId,
    required ShareResourceType resourceType,
    required BuildContext parentContext,
  }) async {
    final targetType = ref.read(shareDialogTargetTypeProvider);
    final selectedId = ref.read(shareDialogSelectedOptionIdProvider);
    final email = ref.read(shareDialogEmailProvider);
    final canEdit = ref.read(shareDialogCanEditProvider);
    final note = ref.read(shareDialogNoteProvider);
    final expiresAt = ref.read(shareDialogExpiresAtProvider);

    ref.read(shareDialogSubmitLoadingProvider.notifier).state = true;
    ref.read(shareDialogSubmitErrorProvider.notifier).state = null;

    final endpoint = resourceType == ShareResourceType.file
        ? CloudUrls.filaShares
        : CloudUrls.folderShares;

    final resourceKey =
    resourceType == ShareResourceType.file ? 'file' : 'folder';

    final resourceLabel =
    resourceType == ShareResourceType.file ? 'file' : 'folder';

    try {
      final Map<String, dynamic> data = {
        resourceKey: resourceId,
        'can_edit': canEdit,
        'user': null,
        'company': null,
        'team': null,
        'email': null,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        if (expiresAt != null)
          'expires_at': DateTime(
            expiresAt.year,
            expiresAt.month,
            expiresAt.day,
            23,
            59,
            59,
          ).toUtc().toIso8601String(),
      };

      switch (targetType) {
        case ShareTargetType.user:
          if (selectedId == null || selectedId.isEmpty) {
            ref.read(shareDialogSubmitErrorProvider.notifier).state =
                'Please select user'.tr;
            return;
          }
          data['user'] = int.parse(selectedId);
          break;

        case ShareTargetType.company:
          if (selectedId == null || selectedId.isEmpty) {
            ref.read(shareDialogSubmitErrorProvider.notifier).state =
                'Please select company'.tr;
            return;
          }
          data['company'] = int.parse(selectedId);
          break;

        case ShareTargetType.team:
          if (selectedId == null || selectedId.isEmpty) {
            ref.read(shareDialogSubmitErrorProvider.notifier).state =
                'Please select team'.tr;
            return;
          }
          data['team'] = int.parse(selectedId);
          break;

        case ShareTargetType.email:
          if (email.trim().isEmpty) {
            ref.read(shareDialogSubmitErrorProvider.notifier).state =
                'Please enter email'.tr;
            return;
          }
          data['email'] = email.trim();
          break;
      }

      debugPrint('FINAL SHARE PAYLOAD => $data');

      final response = await ApiServices.post(
        endpoint,
        data: data,
        hasToken: true,
        ref: ref,
      );

      debugPrint('SHARE STATUS => ${response?.statusCode}');
      debugPrint('SHARE RESPONSE => ${response?.data}');

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        resetDialogState();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  resourceType == ShareResourceType.file
                      ? 'File shared successfully'.tr
                      : 'Folder shared successfully'.tr,
                ),
              ),
            );
          }
        });

        return;
      }

      String errorText = resourceType == ShareResourceType.file
          ? 'Failed to share file'.tr
          : 'Failed to share folder'.tr;

      if (response?.data != null) {
        final raw = response!.data;

        if (raw is Map && raw['detail'] != null) {
          errorText = raw['detail'].toString();
        } else if (raw is Map && raw['non_field_errors'] != null) {
          final errors = raw['non_field_errors'];
          final message = errors is List ? errors.join(' ') : errors.toString();

          if (message.contains('$resourceLabel, company')) {
            errorText = resourceType == ShareResourceType.file
                ? 'This file is already shared with this company.'.tr
                : 'This folder is already shared with this company.'.tr;
          } else if (message.contains('$resourceLabel, user')) {
            errorText = resourceType == ShareResourceType.file
                ? 'This file is already shared with this user.'.tr
                : 'This folder is already shared with this user.'.tr;
          } else if (message.contains('$resourceLabel, team')) {
            errorText = resourceType == ShareResourceType.file
                ? 'This file is already shared with this team.'.tr
                : 'This folder is already shared with this team.'.tr;
          } else if (message.contains('$resourceLabel, email')) {
            errorText = resourceType == ShareResourceType.file
                ? 'This file is already shared with this email.'.tr
                : 'This folder is already shared with this email.'.tr;
          } else {
            errorText = message;
          }
        } else if (raw is List<int>) {
          errorText = utf8.decode(raw);
        } else {
          errorText = raw.toString();
        }
      }

      ref.read(shareDialogSubmitErrorProvider.notifier).state = errorText;
    } catch (e) {
      ref.read(shareDialogSubmitErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(shareDialogSubmitLoadingProvider.notifier).state = false;
    }
  }

  Future<void> updateShare({
    required BuildContext context,
    required String shareId,
    required ShareResourceType resourceType,
    required BuildContext parentContext,
  }) async {
    final canEdit = ref.read(shareDialogCanEditProvider);
    final note = ref.read(shareDialogNoteProvider);
    final expiresAt = ref.read(shareDialogExpiresAtProvider);

    ref.read(shareDialogSubmitLoadingProvider.notifier).state = true;
    ref.read(shareDialogSubmitErrorProvider.notifier).state = null;

    final baseEndpoint = resourceType == ShareResourceType.file
        ? CloudUrls.filaShares
        : CloudUrls.folderShares;

    final endpoint = '$baseEndpoint$shareId/';

    try {
      final data = <String, dynamic>{
        'can_edit': canEdit,
        'note': note.trim(),
        if (expiresAt != null)
          'expires_at': DateTime(
            expiresAt.year,
            expiresAt.month,
            expiresAt.day,
            23,
            59,
            59,
          ).toUtc().toIso8601String(),
      };

      final response = await ApiServices.patch(
        endpoint,
        data: data,
        hasToken: true,
        ref: ref,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 202)) {
        if (context.mounted) Navigator.of(context).pop();

        resetDialogState();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Share updated successfully'.tr)),
            );
          }
        });

        return;
      }

      ref.read(shareDialogSubmitErrorProvider.notifier).state =
          response?.data?.toString() ?? 'Failed to update share'.tr;
    } catch (e) {
      ref.read(shareDialogSubmitErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(shareDialogSubmitLoadingProvider.notifier).state = false;
    }
  }

  void reset() {
    state = SharedFilesState.initial();
  }
}

final sharedFilesProvider =
StateNotifierProvider<SharedFilesNotifier, SharedFilesState>((ref) {
  return SharedFilesNotifier(ref);
});

final shareDialogTargetTypeProvider = StateProvider<ShareTargetType>((ref) {
  return ShareTargetType.user;
});

final shareDialogSelectedOptionIdProvider = StateProvider<String?>((ref) {
  return null;
});

final shareDialogEmailProvider = StateProvider<String>((ref) {
  return '';
});

final shareDialogSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final shareDialogInlinePickerOpenProvider = StateProvider<bool>((ref) {
  return false;
});

final shareDialogStepProvider = StateProvider<int>((ref) {
  return 1;
});

final shareDialogCanEditProvider = StateProvider<bool>((ref) {
  return false;
});

final shareDialogNoteProvider = StateProvider<String>((ref) {
  return '';
});

final shareDialogExpiresAtProvider = StateProvider<DateTime?>((ref) {
  return null;
});

final shareDialogSubmitLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

final shareDialogSubmitErrorProvider = StateProvider<String?>((ref) {
  return null;
});