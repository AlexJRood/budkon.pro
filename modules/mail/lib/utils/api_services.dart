import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:mail/models/email_account_model.dart';
import 'package:mail/models/mail_scheduled_models.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

import '../models/mail_models.dart';
import 'mail_filters.dart';

final emailConnectionErrorProvider = StateProvider<bool>((ref) => false);

class UploadedAttachmentResult {
  final String id;
  final String name;
  final String? url;
  final int sizeBytes;

  const UploadedAttachmentResult({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
  });

  factory UploadedAttachmentResult.fromJson(Map<String, dynamic> json) {
    return UploadedAttachmentResult(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'attachment').toString(),
      url: json['url']?.toString(),
      sizeBytes: int.tryParse('${json['size_bytes'] ?? 0}') ?? 0,
    );
  }
}

dynamic _decodeBody(dynamic raw) {
  if (raw == null) return null;

  if (raw is List<int>) {
    return json.decode(utf8.decode(raw));
  }

  if (raw is String) {
    return json.decode(raw);
  }

  return raw;
}

Map<String, dynamic> _decodeMap(dynamic raw) {
  final decoded = _decodeBody(raw);
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  throw Exception('Invalid response payload');
}

/// Szczegóły pojedynczej wiadomości
final emailDetailsProvider =
    FutureProvider.family<EmailMessage, int>((ref, emailId) async {
  return await EmailService.getEmailDetails(ref: ref, emailId: emailId);
});

/// ✅ Synchronizacja skrzynki e-mail przed pobraniem listy
final syncEmailsProvider = FutureProvider.autoDispose<void>((ref) async {
  debugPrint('🟡 Wywołuję POST /emails/sync/');

  final response = await ApiServices.post(
    '${URLs.emails}sync/',
    hasToken: true,
  );

  debugPrint('🟢 sync statusCode = ${response?.statusCode}');
  debugPrint('🟢 sync data = ${response?.data}');

  if (response == null || response.statusCode! >= 400) {
    ref.read(emailConnectionErrorProvider.notifier).state = true;
    throw Exception('failed_to_sync_emails'.tr);
  }

  String body = '';
  if (response.data != null) {
    if (response.data is List<int>) {
      body = utf8.decode(response.data as List<int>);
    } else if (response.data is String) {
      body = response.data as String;
    } else {
      body = response.data.toString();
    }
  }

  final notConnected = body.contains(
    "'NoneType' object has no attribute 'email_address'",
  );

  ref.read(emailConnectionErrorProvider.notifier).state = notConnected;
});

final filteredEmailsProvider =
    FutureProvider.autoDispose<PaginatedEmailResponse>((ref) async {
  final type = ref.watch(mailTypeProvider);
  final search = ref.watch(mailSearchProvider);
  final page = ref.watch(mailPageProvider);
  final pageSize = ref.watch(mailPageSizeProvider);
  final sort = ref.watch(mailSortProvider);
  final leadId = ref.watch(mailLeadIdProvider);
  final email = ref.watch(mailEmailProvider);

  String? ordering;
  switch (sort) {
    case 'received_at_desc':
      ordering = '-received_at';
      break;
    case 'received_at_asc':
      ordering = 'received_at';
      break;
  }

  return await EmailService.fetchFilteredEmails(
    ref: ref,
    params: EmailFilterParams(
      searchQuery: search.isNotEmpty ? search : null,
      isOutgoing: type == 'sent'
          ? true
          : type == 'inbox'
              ? false
              : null,
      page: page,
      pageSize: pageSize,
      ordering: ordering,
      leadId: leadId != 0 ? leadId : null,
      email: email,
    ),
  );
});

final scheduledPendingEmailsProvider =
    FutureProvider.autoDispose<PaginatedScheduledEmailResponse>((ref) async {
  final page = ref.watch(scheduledPendingPageProvider);
  final pageSize = ref.watch(mailPageSizeProvider);

  return await EmailService.fetchScheduledEmails(
    ref: ref,
    isSent: false,
    page: page,
    pageSize: pageSize,
  );
});

final scheduledEmailDetailsProvider =
    FutureProvider.family<ScheduledEmail, int>((ref, id) async {
  return EmailService.fetchScheduledEmailDetails(ref: ref, id: id);
});

final scheduledSentEmailsProvider =
    FutureProvider.autoDispose<PaginatedScheduledEmailResponse>((ref) async {
  final page = ref.watch(scheduledSentPageProvider);
  final pageSize = ref.watch(mailPageSizeProvider);

  return await EmailService.fetchScheduledEmails(
    ref: ref,
    isSent: true,
    page: page,
    pageSize: pageSize,
  );
});

class EmailService {
  static Future<PaginatedEmailResponse> fetchFilteredEmails({
    required Ref ref,
    required EmailFilterParams params,
  }) async {
    final queryParams = {
      if (params.searchQuery != null) 'search': params.searchQuery!,
      if (params.isOutgoing != null)
        'is_outgoing': params.isOutgoing! ? 'true' : 'false',
      if (params.page != null) 'page': params.page.toString(),
      if (params.pageSize != null) 'page_size': params.pageSize.toString(),
      if (params.ordering != null) 'ordering': params.ordering!,
      if (params.leadId != null) 'lead': params.leadId.toString(),
      if (params.email != null) 'email': params.email.toString(),
    };

    final uri = Uri.parse(URLs.emails).replace(queryParameters: queryParams);
    final response = await ApiServices.get(
      uri.toString(),
      hasToken: true,
      ref: ref,
    );

    if (response != null && response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.data));
      ref.read(emailConnectionErrorProvider.notifier).state = false;
      debugPrint('FETCH ordering=${params.ordering}, page=${params.page}, type=${params.isOutgoing}');
      return PaginatedEmailResponse.fromJson(decoded);
    } else {
      throw Exception('failed_to_fetch_emails'.tr);
    }
  }

  static Future<ScheduledEmail> fetchScheduledEmailDetails({
    required Ref ref,
    required int id,
  }) async {
    final url = '${URLs.baseUrl}/mail/scheduled-emails/$id/';
    final response = await ApiServices.get(url, hasToken: true, ref: ref);

    if (response != null && response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.data));
      return ScheduledEmail.fromJson(decoded);
    } else {
      throw Exception('Failed to load scheduled email details');
    }
  }

  static Future<void> deleteScheduledEmail({
    required int id,
  }) async {
    final url = '${URLs.baseUrl}/mail/scheduled-emails/$id/';

    final response = await ApiServices.delete(
      url,
      hasToken: true,
    );

    if (response == null) {
      throw Exception('Delete failed: response is null');
    }

    final status = response.statusCode ?? 0;

    if (status >= 400) {
      String msg = 'Delete failed ($status)';
      try {
        final d = response.data;
        if (d is List<int>) {
          final decoded = json.decode(utf8.decode(d));
          msg = (decoded is Map && decoded['detail'] != null)
              ? decoded['detail'].toString()
              : msg;
        } else if (d is String) {
          final decoded = json.decode(d);
          msg = (decoded is Map && decoded['detail'] != null)
              ? decoded['detail'].toString()
              : msg;
        } else if (d is Map && d['detail'] != null) {
          msg = d['detail'].toString();
        } else if (d != null) {
          msg = d.toString();
        }
      } catch (_) {}

      throw Exception(msg);
    }
  }

  static Future<PaginatedScheduledEmailResponse> fetchScheduledEmails({
    required Ref ref,
    required bool isSent,
    required int page,
    required int pageSize,
  }) async {
    final uri = Uri.parse('${URLs.baseUrl}/mail/scheduled-emails/').replace(
      queryParameters: {
        'is_sent': isSent ? 'true' : 'false',
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    final response = await ApiServices.get(
      uri.toString(),
      hasToken: true,
      ref: ref,
    );

    if (response != null && response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.data));
      return PaginatedScheduledEmailResponse.fromJson(decoded);
    } else {
      throw Exception('failed_to_fetch_scheduled_emails'.tr);
    }
  }

  static Future<EmailMessage> getEmailDetails({
    required Ref ref,
    required int emailId,
  }) async {
    final response = await ApiServices.get(
      '${URLs.emails}$emailId/',
      hasToken: true,
      ref: ref,
    );

    if (response != null &&
        response.statusCode == 200 &&
        response.data != null) {
      final decoded = json.decode(utf8.decode(response.data));
      return EmailMessage.fromJson(decoded);
    } else {
      throw Exception('failed_to_fetch_email_details'.tr);
    }
  }

  static Future<UploadedAttachmentResult> uploadAttachment({
    required PlatformFile file,
  }) async {
    MultipartFile multipartFile;

    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else if (file.path != null && file.path!.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    } else {
      throw Exception('Plik nie zawiera danych do uploadu.');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await ApiServices.post(
      '${URLs.emails}upload-attachment/',
      hasToken: true,
      formData: formData,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      },
    );

    if (response == null) {
      throw Exception('Upload failed: response is null');
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      String backendMessage = 'Nie udało się wgrać załącznika';
      try {
        final decoded = _decodeMap(response.data);
        backendMessage =
            (decoded['error'] ?? decoded['detail'] ?? backendMessage)
                .toString();
      } catch (_) {}
      throw Exception(backendMessage);
    }

    final decoded = _decodeMap(response.data);
    return UploadedAttachmentResult.fromJson(decoded);
  }

  static Future<void> sendEmail({
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('📧 [sendEmail] START');
      debugPrint('📧 [sendEmail] endpoint: ${'${URLs.emails}send/'}');
      debugPrint('📧 [sendEmail] payload keys: ${data.keys.toList()}');

      final response = await ApiServices.post(
        '${URLs.emails}send/',
        hasToken: true,
        data: data,
      );

      debugPrint('📧 [sendEmail] response is null: ${response == null}');
      if (response != null) {
        debugPrint('📧 [sendEmail] statusCode: ${response.statusCode}');
        debugPrint(
          '📧 [sendEmail] response.data runtimeType: ${response.data.runtimeType}',
        );
      }

      String body = '';
      if (response?.data != null) {
        final resData = response!.data;
        if (resData is List<int>) {
          body = utf8.decode(resData);
        } else if (resData is String) {
          body = resData;
        } else {
          body = resData.toString();
        }
      }

      final notConnected = body.contains(
        "'NoneType' object has no attribute 'email_address'",
      );

      if (notConnected) {
        throw Exception('email_not_connected_message'.tr);
      }

      if (response == null || (response.statusCode ?? 0) >= 400) {
        throw Exception('failed_to_send_email'.tr);
      }

      debugPrint('✅ [sendEmail] SUCCESS - email sent.');
      debugPrint('📧 [sendEmail] END');
    } catch (e, st) {
      debugPrint('💥 [sendEmail] ERROR: $e');
      debugPrint('💥 [sendEmail] STACK: $st');
      rethrow;
    }
  }

  static Future<void> scheduleEmail({
    required dynamic ref,
    required Map<String, dynamic> data,
  }) async {
    final response = await ApiServices.post(
      '${URLs.baseUrlMail}emails/send/',
      hasToken: true,
      data: data,
    );

    if (response == null) {
      throw Exception('Schedule failed: response is null');
    }

    final status = response.statusCode ?? 0;

    if (status >= 400) {
      final backendMsg = (() {
        try {
          final d = response.data;
          if (d is Map && d['error'] != null) return d['error'].toString();
          if (d is Map && d['detail'] != null) return d['detail'].toString();
          return d?.toString();
        } catch (_) {
          return null;
        }
      })();

      throw Exception(
        backendMsg != null && backendMsg.isNotEmpty
            ? 'Schedule failed ($status): $backendMsg'
            : 'Schedule failed ($status)',
      );
    }
  }
}

final emailAccountsProvider =
    FutureProvider.autoDispose<List<EmailAccount>>((ref) async {
  final res = await ApiServices.get(
    '${URLs.baseUrl}/mail/email-accounts/',
    hasToken: true,
    ref: ref,
  );

  if (res == null || res.statusCode != 200) return [];

  dynamic decoded;
  final d = res.data;

  if (d is List<int>) {
    decoded = json.decode(utf8.decode(d));
  } else if (d is String) {
    decoded = json.decode(d);
  } else {
    decoded = d;
  }

  if (decoded is Map && decoded['results'] is List) {
    final list = (decoded['results'] as List);
    return list
        .whereType<Map>()
        .map((e) => EmailAccount.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((a) => a.id != 0 && a.emailAddress.isNotEmpty)
        .toList();
  }

  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => EmailAccount.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((a) => a.id != 0 && a.emailAddress.isNotEmpty)
        .toList();
  }

  return [];
});

final selectedEmailAccountIdProvider = StateProvider<int?>((ref) => null);

final selectedEmailAccountProvider = Provider.autoDispose<EmailAccount?>((ref) {
  final accountsAsync = ref.watch(emailAccountsProvider);
  final selectedId = ref.watch(selectedEmailAccountIdProvider);

  return accountsAsync.maybeWhen(
    data: (accounts) {
      if (accounts.isEmpty) return null;

      if (selectedId == null) {
        Future.microtask(() {
          if (ref.read(selectedEmailAccountIdProvider) == null) {
            ref.read(selectedEmailAccountIdProvider.notifier).state =
                accounts.first.id;
          }
        });
        return accounts.first;
      }

      return accounts.firstWhere(
        (a) => a.id == selectedId,
        orElse: () => accounts.first,
      );
    },
    orElse: () => null,
  );
});