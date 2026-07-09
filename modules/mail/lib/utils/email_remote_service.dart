import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../models/email_cache_sync_response.dart';
import '../models/mail_models.dart';
import '../models/mailbox_query.dart';
import '../provider/urls_mail.dart';

class EmailRemoteService {
  final Ref ref;

  const EmailRemoteService({
    required this.ref,
  });

  Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return <String, dynamic>{};

    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    throw Exception('Unexpected response format: ${data.runtimeType}');
  }

  String _stringifyBody(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;

    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _ensureSuccess(Response? response, String actionName) {
    final statusCode = response?.statusCode ?? 0;

    if (response == null || statusCode < 200 || statusCode >= 300) {
      throw Exception(
        '$actionName failed: $statusCode ${_stringifyBody(response?.data)}',
      );
    }
  }

  Future<EmailCacheSyncResponse> cacheSync({
    required MailboxQuery query,
    required String? lastCheckAt,
    required int cachedCount,
    required String? oldestCachedAt,
    required List<int> knownIds,
    bool doRemoteSync = true,
  }) async {
    final response = await ApiServices.post(
      EmailsURLs.cacheSync,
      ref: ref,
      hasToken: true,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      data: {
        ...query.toBackendJson(),
        'last_check_at': lastCheckAt,
        'cached_count': cachedCount,
        'oldest_cached_at': oldestCachedAt,
        'known_ids': knownIds,
        'do_remote_sync': doRemoteSync,
      },
    );

    _ensureSuccess(response, 'cache-sync');

    return EmailCacheSyncResponse.fromJson(_asMap(response!.data));
  }

  Future<LoadOlderEmailsResponse> loadOlder({
    required MailboxQuery query,
    required String olderThan,
    int count = 100,
  }) async {
    final response = await ApiServices.post(
      EmailsURLs.loadOlder,
      ref: ref,
      hasToken: true,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      data: {
        ...query.toBackendJson(),
        'older_than': olderThan,
        'count': count,
      },
    );

    _ensureSuccess(response, 'load-older');

    return LoadOlderEmailsResponse.fromJson(_asMap(response!.data));
  }

  Future<EmailMessage> fetchEmailDetail(int emailId) async {
    final response = await ApiServices.get(
      EmailsURLs.emailDetail(emailId),
      ref: ref,
      hasToken: true,
      headers: const {
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    _ensureSuccess(response, 'fetch-email-detail');

    return EmailMessage.fromJson(_asMap(response!.data));
  }

  Future<void> markEmailRead(int emailId) async {
    final response = await ApiServices.post(
      EmailsURLs.markRead(emailId),
      ref: ref,
      hasToken: true,
      headers: const {
        'Accept': 'application/json',
      },
    );

    _ensureSuccess(response, 'mark-read');
  }

  Future<void> markEmailUnread(int emailId) async {
    final response = await ApiServices.post(
      EmailsURLs.markUnread(emailId),
      ref: ref,
      hasToken: true,
      headers: const {
        'Accept': 'application/json',
      },
    );

    _ensureSuccess(response, 'mark-unread');
  }

  Future<void> touchEmmaSeen(int emailId) async {
    final response = await ApiServices.post(
      EmailsURLs.touchEmmaSeen(emailId),
      ref: ref,
      hasToken: true,
      headers: const {
        'Accept': 'application/json',
      },
    );

    _ensureSuccess(response, 'touch-emma-seen');
  }

  Future<void> touchEmmaUsed(int emailId) async {
    final response = await ApiServices.post(
      EmailsURLs.touchEmmaUsed(emailId),
      ref: ref,
      hasToken: true,
      headers: const {
        'Accept': 'application/json',
      },
    );

    _ensureSuccess(response, 'touch-emma-used');
  }
}