import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../models/mail_models.dart';
import '../utils/mail_filters.dart';
import 'urls_mail.dart';

dynamic _decodeResponseData(dynamic data) {
  if (data == null) return null;

  if (data is List<int>) {
    return json.decode(utf8.decode(data));
  }

  if (data is String) {
    return json.decode(data);
  }

  return data;
}

List<T> _parseListResponse<T>(
  dynamic decoded,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  if (decoded is Map && decoded['results'] is List) {
    return (decoded['results'] as List)
        .whereType<Map>()
        .map((e) => fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  return const [];
}

Map<String, dynamic> _parseMapResponse(dynamic decoded) {
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  throw Exception('Invalid response payload');
}

void _ensureSuccess(dynamic response, String message) {
  final code = response?.statusCode ?? 0;
  if (response == null || code < 200 || code >= 300) {
    throw Exception(message);
  }
}

final emailTabsProvider = FutureProvider.autoDispose<List<EmailTab>>((ref) async {
  ref.keepAlive();
  final response = await ApiServices.get(
    EmailsURLs.emailTabs,
    hasToken: true,
    ref: ref,
  );

  if (response == null || response.statusCode != 200) {
    throw Exception('Failed to load email tabs');
  }

  final decoded = _decodeResponseData(response.data);
  return _parseListResponse(decoded, EmailTab.fromJson)
      .where((e) => e.id != 0 && e.isVisible)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});

final emailTagsProvider = FutureProvider.autoDispose<List<EmailTag>>((ref) async {
  final response = await ApiServices.get(
    EmailsURLs.emailTags,
    hasToken: true,
    ref: ref,
  );

  if (response == null || response.statusCode != 200) {
    throw Exception('Failed to load email tags');
  }

  final decoded = _decodeResponseData(response.data);
  return _parseListResponse(decoded, EmailTag.fromJson)
      .where((e) => e.id != 0)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});

class EmailTaxonomyService {
  static List<int> extractEmailIdsFromPayload(dynamic raw) {
    if (raw == null) return const [];

    if (raw is Map) {
      final emails = raw['emails'];
      if (emails is List) {
        return emails
            .map((e) => int.tryParse('$e'))
            .whereType<int>()
            .toList();
      }

      final id = int.tryParse('${raw['id']}');
      if (id != null) return [id];
    }

    return const [];
  }

  static Future<void> bulkMoveEmailsToTab({
    required WidgetRef ref,
    required List<int> emailIds,
    required int tabId,
  }) async {
    if (emailIds.isEmpty) return;

    final response = await ApiServices.post(
      EmailsURLs.bulkMoveToTab(),
      hasToken: true,
      ref: ref,
      data: {
        'email_ids': emailIds,
        'tab_id': tabId,
      },
    );

    _ensureSuccess(response, 'Failed to move emails to tab');
    triggerMailRefresh(ref);
  }

  static Future<void> setEmailTags({
    required WidgetRef ref,
    required int emailId,
    List<int> addTagIds = const [],
    List<int> removeTagIds = const [],
  }) async {
    final response = await ApiServices.post(
      EmailsURLs.setTags(emailId),
      hasToken: true,
      ref: ref,
      data: {
        'add_tag_ids': addTagIds,
        'remove_tag_ids': removeTagIds,
      },
    );

    _ensureSuccess(response, 'Failed to update email tags');
    triggerMailRefresh(ref);
  }

  // =========================
  // TAGS
  // =========================

  static Future<EmailTag> createTag({
    required WidgetRef ref,
    required String name,
    required String color,
    int? order,
  }) async {
    final response = await ApiServices.post(
      EmailsURLs.emailTags,
      hasToken: true,
      ref: ref,
      data: {
        'name': name.trim(),
        'color': color.trim(),
        if (order != null) 'order': order,
      },
    );

    _ensureSuccess(response, 'Failed to create tag');

    final decoded = _decodeResponseData(response?.data);
    final created = EmailTag.fromJson(_parseMapResponse(decoded));

    ref.invalidate(emailTagsProvider);
    triggerMailRefresh(ref);

    return created;
  }

  static Future<EmailTag> updateTag({
    required WidgetRef ref,
    required int tagId,
    required String name,
    required String color,
    int? order,
  }) async {
    final response = await ApiServices.patch(
      EmailsURLs.tagDetail(tagId),
      hasToken: true,
      ref: ref,
      data: {
        'name': name.trim(),
        'color': color.trim(),
        if (order != null) 'order': order,
      },
    );

    _ensureSuccess(response, 'Failed to update tag');

    final decoded = _decodeResponseData(response?.data);
    final updated = EmailTag.fromJson(_parseMapResponse(decoded));

    ref.invalidate(emailTagsProvider);
    triggerMailRefresh(ref);

    return updated;
  }

  static Future<void> deleteTag({
    required WidgetRef ref,
    required int tagId,
  }) async {
    final response = await ApiServices.delete(
      EmailsURLs.tagDetail(tagId),
      hasToken: true,
    );

    _ensureSuccess(response, 'Failed to delete tag');

    ref.invalidate(emailTagsProvider);
    triggerMailRefresh(ref);
  }

  // =========================
  // TABS
  // =========================

  static Future<EmailTab> createTab({
    required WidgetRef ref,
    required String name,
    required String color,
    int? order,
    bool isVisible = true,
  }) async {
    final response = await ApiServices.post(
      EmailsURLs.emailTabs,
      hasToken: true,
      ref: ref,
      data: {
        'name': name.trim(),
        'color': color.trim(),
        'is_visible': isVisible,
        if (order != null) 'order': order,
      },
    );

    _ensureSuccess(response, 'Failed to create tab');

    final decoded = _decodeResponseData(response?.data);
    final created = EmailTab.fromJson(_parseMapResponse(decoded));

    ref.invalidate(emailTabsProvider);
    triggerMailRefresh(ref);

    return created;
  }

  static Future<EmailTab> updateTab({
    required WidgetRef ref,
    required int tabId,
    required String name,
    required String color,
    bool? isVisible,
    int? order,
  }) async {
    final response = await ApiServices.patch(
      EmailsURLs.tabDetail(tabId),
      hasToken: true,
      ref: ref,
      data: {
        'name': name.trim(),
        'color': color.trim(),
        if (isVisible != null) 'is_visible': isVisible,
        if (order != null) 'order': order,
      },
    );

    _ensureSuccess(response, 'Failed to update tab');

    final decoded = _decodeResponseData(response?.data);
    final updated = EmailTab.fromJson(_parseMapResponse(decoded));

    ref.invalidate(emailTabsProvider);
    triggerMailRefresh(ref);

    return updated;
  }

  static Future<void> bulkReorderTabs({
    required WidgetRef ref,
    required List<dynamic> orderedTabs,
  }) async {
    final data = [
      for (int i = 0; i < orderedTabs.length; i++)
        {'id': orderedTabs[i].id, 'order': (i + 1) * 10},
    ];
    final response = await ApiServices.post(
      EmailsURLs.tabsBulkOrder(),
      hasToken: true,
      ref: ref,
      data: data,
    );
    _ensureSuccess(response, 'Failed to reorder tabs');
    ref.invalidate(emailTabsProvider);
  }

  static Future<void> deleteTab({
    required WidgetRef ref,
    required int tabId,
  }) async {
    final response = await ApiServices.delete(
      EmailsURLs.tabDetail(tabId),
      hasToken: true,
    );

    _ensureSuccess(response, 'Failed to delete tab');

    ref.invalidate(emailTabsProvider);
    triggerMailRefresh(ref);
  }
}