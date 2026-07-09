import 'dart:convert';

import 'package:crm/contact_panel/tabs/employee_settlements/models/compensation_notification_preferences_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

class CompensationNotificationPreferencesNotifier extends AsyncNotifier<
    CompensationNotificationPreferencesModel> {
  static const String _endpoint =
      'https://www.superbee.cloud/finance/compensation/notification-preferences/';

  @override
  Future<CompensationNotificationPreferencesModel> build() async {
    return _requestPreferences();
  }

  Future<CompensationNotificationPreferencesModel> _requestPreferences() async {
    final response = await ApiServices.get(
      _endpoint,
      ref: ref,
      hasToken: true,
    );

    _ensureSuccess(
      response,
      'Failed to fetch compensation notification preferences',
    );

    return CompensationNotificationPreferencesModel.fromJson(
      _decodeResponse(response?.data),
    );
  }

  Future<void> fetch({
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final preferences = await _requestPreferences();
      state = AsyncData(preferences);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<CompensationNotificationPreferencesModel> save(
    CompensationNotificationPreferencesModel model,
  ) async {
    final previous = state.asData?.value;

    // Optimistic update
    state = AsyncData(model);

    try {
      final response = await ApiServices.patch(
        _endpoint,
        data: model.toPatchJson(),
        ref: ref,
        hasToken: true,
      );

      _ensureSuccess(
        response,
        'Failed to save compensation notification preferences',
      );

      final saved = CompensationNotificationPreferencesModel.fromJson(
        _decodeResponse(response?.data),
      );

      state = AsyncData(saved);
      return saved;
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }

      rethrow;
    }
  }
}

final compensationNotificationPreferencesProvider =
    AsyncNotifierProvider<
        CompensationNotificationPreferencesNotifier,
        CompensationNotificationPreferencesModel>(
  CompensationNotificationPreferencesNotifier.new,
);

Map<String, dynamic> _decodeResponse(dynamic data) {
  dynamic decoded = data;

  // ApiServices can return UTF-8 bytes.
  if (decoded is List<int>) {
    decoded = jsonDecode(
      utf8.decode(decoded),
    );
  }

  // It can also return a raw JSON string.
  if (decoded is String) {
    decoded = jsonDecode(decoded);
  }

  // Optional support for wrapped API responses.
  if (decoded is Map && decoded['data'] is Map) {
    decoded = decoded['data'];
  }

  if (decoded is! Map) {
    throw Exception(
      'Unexpected notification preferences response format: '
      '${decoded.runtimeType}',
    );
  }

  return Map<String, dynamic>.from(decoded);
}

void _ensureSuccess(
  dynamic response,
  String message,
) {
  if (response == null ||
      response.statusCode == null ||
      response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(message);
  }
}