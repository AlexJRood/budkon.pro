import 'dart:developer';

import 'package:cloud/models/cloud_drag_payload.dart';
import 'package:cloud/providers/providers.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mail/utils/mail_filters.dart';
import 'package:network_monitoring/providers/saved_search/add_client.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

/// Result class for drop operations
class DropResult {
  final bool success;
  final String message;

  DropResult(this.success, this.message);
}

class ClientAppbarDropService {
  static final DropResult success = DropResult(true, 'Success');
  static DropResult failure(String message) => DropResult(false, message);

  static Map<String, dynamic> _payloadMap(dynamic data) {
    final raw = data.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _isSuccessStatus(dynamic response) {
    final code = response?.statusCode;
    return code != null && code >= 200 && code < 300;
  }

  static void _refreshCloudState(ProviderContainer container) {
    container.read(cloudSidebarRefreshTriggerProvider.notifier).state++;
    container.read(cloudExplorerRefreshTriggerProvider.notifier).state++;
    container.read(clientExplorerRefreshTriggerProvider.notifier).state++;

    container.invalidate(cloudSidebarProvider);
    container.invalidate(cloudExplorerProvider);
    container.invalidate(clientCloudExplorerProvider);
    container.invalidate(storageQuotaProvider);
  }

  static Future<bool> _assignCloudItemsToObject({
    required WidgetRef ref,
    required String appLabel,
    required String model,
    required String objectId,
    required List<String> files,
    required List<String> folders,
    String relationType = 'documents',
    String note = 'Assigned via drag and drop',
  }) async {
    final response = await ApiServices.post(
      'https://www.superbee.cloud/storage/assignments/bulk-assign/',
      data: {
        'app_label': appLabel,
        'model': model,
        'object_id': objectId,
        'relation_type': relationType,
        'note': note,
        'files': files,
        'folders': folders,
      },
      hasToken: true,
      ref: ref,
    );

    log(
      'Cloud assign response for $appLabel.$model:$objectId -> ${response?.statusCode}',
    );

    return _isSuccessStatus(response);
  }

  static ({List<String> files, List<String> folders}) _extractCloudItems(
    dynamic data,
  ) {
    List<String> files = [];
    List<String> folders = [];

    if (data.type == DndPayloadType.multipleCloudItems) {
      final raw = data.data;
      if (raw is Map<String, dynamic>) {
        final cloudPayload = CloudDragPayload.fromJson(raw);
        files = cloudPayload.files.map((e) => e.toString()).toList();
        folders = cloudPayload.folders.map((e) => e.toString()).toList();
      } else if (raw is Map) {
        final cloudPayload = CloudDragPayload.fromJson(
          Map<String, dynamic>.from(raw),
        );
        files = cloudPayload.files.map((e) => e.toString()).toList();
        folders = cloudPayload.folders.map((e) => e.toString()).toList();
      }
    } else if (data.type == DndPayloadType.cloudFile) {
      files = [data.id.toString()];
    } else if (data.type == DndPayloadType.cloudFolder) {
      folders = [data.id.toString()];
    }

    return (files: files, folders: folders);
  }

  static Future<DropResult> handleDrop({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic data,
    required UserContactModel client,
    int? transactionId,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final payloadData = _payloadMap(data);

    final int resolvedClientId = _asInt(payloadData['client']) ?? client.id;
    final int? resolvedTransactionId =
        _asInt(payloadData['transaction']) ?? transactionId;

    log('DND type: ${data.type}');
    log('DND id: ${data.id}');
    log('DND payload data: $payloadData');
    log('Resolved client: $resolvedClientId');
    log('Resolved transaction: $resolvedTransactionId');

    if (data.type == DndPayloadType.task) {
      final requestData = <String, dynamic>{
        'client_id': resolvedClientId,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/tms/assign-client/${data.id}/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Task assigned to client successfully.');
      }
      return DropResult(false, 'Failed to assign task to client.');
    }

    if (data.type == DndPayloadType.calendarEvent) {
      final requestData = <String, dynamic>{
        'client_id': resolvedClientId,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/calendar/event/${data.id}/assign-client/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Event assigned to client successfully.');
      }
      return DropResult(false, 'Failed to assign event to client.');
    }

    if (data.type == DndPayloadType.expenses) {
      final requestData = <String, dynamic>{
        'client_id': resolvedClientId,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/finance/expenses/${data.id}/assign-client/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Expense assigned to client successfully.');
      }
      return DropResult(false, 'Failed to assign expense to client.');
    }

    if (data.type == DndPayloadType.revenue) {
      final requestData = <String, dynamic>{
        'client_id': resolvedClientId,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/finance/revenues/${data.id}/assign-client/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Revenue assigned to client successfully.');
      }
      return DropResult(false, 'Failed to assign revenue to client.');
    }

    if (data.type == DndPayloadType.email) {
      final emailIds = data.data?['emails'] as List<dynamic>?;
      if (emailIds == null || emailIds.isEmpty) {
        return DropResult(false, 'No emails selected for assignment.');
      }

      final requestData = <String, dynamic>{
        'app_label': 'user_contacts',
        'model': 'usercontact',
        'object_id': resolvedClientId.toString(),
        'relation_type': 'messages',
        'note': 'Assigned via drag and drop',
        'emails': emailIds,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/mail/assignments/bulk-assign/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        container.read(selectedMailIdsProvider.notifier).state = {};
        container.read(mailSelectionModeProvider.notifier).state = false;

        return DropResult(
          true,
          '${emailIds.length} email(s) assigned to client successfully.',
        );
      }
      return DropResult(false, 'Failed to assign emails to client.');
    }

    if (data.type == DndPayloadType.nm_ad) {
      final adId =
          payloadData['advertisement'] ??
          payloadData['advertisement_id'] ??
          data.id;

      if (adId == null || adId.toString().isEmpty) {
        return DropResult(false, 'No ad selected.');
      }

      final requestData = <String, dynamic>{
        'client': resolvedClientId,
        if (resolvedTransactionId != null) 'transaction': resolvedTransactionId,
      };

      final response = await ApiServices.post(
        'https://www.superbee.cloud/networkmonitoring/favorite/add/$adId/',
        data: requestData,
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Ad added to favorites successfully.');
      }
      return DropResult(false, 'Failed to add ad to favorites.');
    }

    if (data.type == DndPayloadType.savedSearch) {
      try {
        await container
            .read(addClientToSavedSearch)
            .addClientToSavedSearch(resolvedClientId, int.parse(data.id));

        return DropResult(
          true,
          'Saved search assigned to client successfully.',
        );
      } catch (_) {
        return DropResult(false, 'Failed to assign saved search to client.');
      }
    }

    if (data.type == DndPayloadType.cloudFile ||
        data.type == DndPayloadType.cloudFolder ||
        data.type == DndPayloadType.multipleCloudItems) {
      final cloudItems = _extractCloudItems(data);
      final files = cloudItems.files;
      final folders = cloudItems.folders;

      if (files.isEmpty && folders.isEmpty) {
        return DropResult(false, 'No cloud items selected.');
      }

      final clientAssigned = await _assignCloudItemsToObject(
        ref: ref,
        appLabel: 'user_contacts',
        model: 'usercontact',
        objectId: resolvedClientId.toString(),
        relationType: 'documents',
        files: files,
        folders: folders,
      );

      if (!clientAssigned) {
        return DropResult(false, 'Failed to assign cloud items to client.');
      }

      if (resolvedTransactionId != null) {
        final txAssigned = await _assignCloudItemsToObject(
          ref: ref,
          appLabel: 'estate_agent',
          model: 'agenttransaction',
          objectId: resolvedTransactionId.toString(),
          relationType: 'documents',
          files: files,
          folders: folders,
        );

        _refreshCloudState(container);

        if (!txAssigned) {
          return DropResult(
            false,
            'Cloud items assigned to client, but failed to assign to transaction.',
          );
        }

        return DropResult(
          true,
          'Cloud items assigned to client and transaction successfully.',
        );
      }

      _refreshCloudState(container);
      return DropResult(true, 'Cloud items assigned to client successfully.');
    }

    if (data.type == DndPayloadType.favAd) {
      final adId = data.id;

      if (adId.isEmpty) {
        return DropResult(false, 'No ad selected.');
      }

      final response = await ApiServices.post(
        URLs.apiFavoriteAdd(adId),
        data: {'client': resolvedClientId},
        hasToken: true,
        ref: ref,
      );

      if (_isSuccessStatus(response)) {
        return DropResult(true, 'Ad assigned to client successfully.');
      }
      return DropResult(false, 'Failed to assign ad to client.');
    }

    return DropResult(false, 'Unknown drop type.');
  }
}