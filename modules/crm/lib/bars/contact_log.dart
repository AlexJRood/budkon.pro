import 'dart:developer';

import 'package:crm/data/clients/client_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class ContactOpenLogResponse {
  final bool ok;
  final int? contactId;
  final int? viewsCount;
  final DateTime? lastViewedAt;
  final String? detail;
  final Map<String, dynamic> raw;

  const ContactOpenLogResponse({
    required this.ok,
    required this.contactId,
    required this.viewsCount,
    required this.lastViewedAt,
    required this.raw,
    this.detail,
  });

  factory ContactOpenLogResponse.fromJson(Map<String, dynamic> json) {
    return ContactOpenLogResponse(
      ok: json['ok'] == true,
      contactId: _toInt(json['contact_id']),
      viewsCount: _toInt(json['views_count']),
      lastViewedAt: _parseDateTime(json['last_viewed_at']),
      detail: json['detail']?.toString(),
      raw: json,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ContactOpenLogApi {
  final Ref ref;
  final String baseUrl;

  ContactOpenLogApi({
    required this.ref,
    required this.baseUrl,
  });

  Future<ContactOpenLogResponse> logOpen(
    int contactId, {
    String source = 'client_list_button',
    Map<String, dynamic>? meta,
  }) async {
    final payload = <String, dynamic>{
      'meta': {
        'source': source,
        ...?meta,
      },
    };

    final Response? response = await ApiServices.post(
      '$baseUrl$contactId/log-open/',
      data: payload,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from log-open endpoint.');
    }

    final dynamic data = response.data;

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (data is Map<String, dynamic>) {
        return ContactOpenLogResponse.fromJson(data);
      }
      throw Exception('Invalid response format from log-open endpoint.');
    }

    if (data is Map<String, dynamic>) {
      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Failed to log contact open.',
      );
    }

    throw Exception('Failed to log contact open.');
  }

  Future<ContactOpenLogResponse> logOpenLegacy(
    int contactId, {
    String source = 'client_list_button',
    Map<String, dynamic>? meta,
  }) async {
    final payload = <String, dynamic>{
      'contact_id': contactId,
      'meta': {
        'source': source,
        ...?meta,
      },
    };

    final Response? response = await ApiServices.post(
      '${baseUrl}log-open/',
      data: payload,
      hasToken: true,
      ref: ref,
    );

    if (response == null) {
      throw Exception('No response from legacy log-open endpoint.');
    }

    final dynamic data = response.data;

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (data is Map<String, dynamic>) {
        return ContactOpenLogResponse.fromJson(data);
      }
      throw Exception('Invalid response format from legacy log-open endpoint.');
    }

    if (data is Map<String, dynamic>) {
      throw Exception(
        data['detail']?.toString() ??
            data['error']?.toString() ??
            'Failed to log contact open.',
      );
    }

    throw Exception('Failed to log contact open.');
  }
}

final contactOpenLogBaseUrlProvider = Provider<String>((ref) {
  return 'https://www.superbee.cloud/contacts/';
});

final contactOpenLogApiProvider = Provider<ContactOpenLogApi>((ref) {
  return ContactOpenLogApi(
    ref: ref,
    baseUrl: ref.watch(contactOpenLogBaseUrlProvider),
  );
});

class ContactOpenLogState {
  final bool isLoading;
  final ContactOpenLogResponse? lastResponse;
  final String? error;

  const ContactOpenLogState({
    this.isLoading = false,
    this.lastResponse,
    this.error,
  });

  ContactOpenLogState copyWith({
    bool? isLoading,
    ContactOpenLogResponse? lastResponse,
    String? error,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return ContactOpenLogState(
      isLoading: isLoading ?? this.isLoading,
      lastResponse: clearResponse ? null : (lastResponse ?? this.lastResponse),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ContactOpenLogNotifier extends StateNotifier<ContactOpenLogState> {
  final Ref ref;

  ContactOpenLogNotifier(this.ref) : super(const ContactOpenLogState());

  Future<ContactOpenLogResponse?> logOpen(
    int contactId, {
    String source = 'client_list_button',
    Map<String, dynamic>? meta,
    bool useLegacyEndpoint = false,
    bool silent = true,
    bool optimisticUi = true,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    // optimistic move to top instantly
    if (optimisticUi) {
      ref.read(clientProvider.notifier).moveClientToTopLocally(
            contactId,
            viewedAt: DateTime.now(),
            incrementViewCount: true,
          );
    }

    try {
      final api = ref.read(contactOpenLogApiProvider);

      final result = useLegacyEndpoint
          ? await api.logOpenLegacy(
              contactId,
              source: source,
              meta: meta,
            )
          : await api.logOpen(
              contactId,
              source: source,
              meta: meta,
            );

      // sync exact values from backend
      ref.read(clientProvider.notifier).applyOpenedClientServerData(
            contactId,
            lastViewedAt: result.lastViewedAt,
            viewsCount: result.viewsCount,
          );

      state = state.copyWith(
        isLoading: false,
        lastResponse: result,
        clearError: true,
      );

      return result;
    } catch (e, s) {
      log('Contact open log error: $e', stackTrace: s);

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      if (!silent) {
        rethrow;
      }

      return null;
    }
  }

  void clear() {
    state = const ContactOpenLogState();
  }
}

final contactOpenLogProvider = StateNotifierProvider.autoDispose<
    ContactOpenLogNotifier, ContactOpenLogState>(
  (ref) => ContactOpenLogNotifier(ref),
);