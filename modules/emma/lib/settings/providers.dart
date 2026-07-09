// lib/emma/settings/ai_settings_providers.dart

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';

import 'models.dart';

/// URL możesz sobie podmienić na swój router / ApiRoutes.
/// Jeśli masz np. ApiRoutes.aiSettingsSchema – wstaw tam.
const String _settingsSchemaUrl = 'https://www.superbee.cloud/emma/schema/settings/';

final aiDynamicSettingsProvider =
    StateNotifierProvider<AiDynamicSettingsNotifier, AsyncValue<List<AiDynamicSetting>>>(
  (ref) => AiDynamicSettingsNotifier(ref),
);

class AiDynamicSettingsNotifier
    extends StateNotifier<AsyncValue<List<AiDynamicSetting>>> {
  AiDynamicSettingsNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final response = await ApiServices.get(
        _settingsSchemaUrl,
        hasToken: true,
        ref: ref,
        responseType: ResponseType.json,
      );

      if (response == null) {
         throw Exception('no_response_from_server'.tr);
      }
      if (response.statusCode != 200) {
        log('AiSettings schema error: ${response.statusCode} ${response.data}');
        throw Exception('${'ai_settings_fetch_error'.tr} (${response.statusCode}).');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('invalid_json_format'.tr);
      }

      final settingsJson = data['settings'];
      if (settingsJson is! List) {
          throw Exception('settings_field_not_list'.tr);
      }

      final settings = settingsJson
          .whereType<Map>()
          .map(
            (e) => AiDynamicSetting.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      state = AsyncValue.data(settings);
    } catch (e, st) {
      log('AiDynamicSettings load error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateValue(AiDynamicSetting setting, dynamic newValue) async {
    final current = state;
    if (current is! AsyncData<List<AiDynamicSetting>>) return;

    // lokalny optimistic update
    final list = current.value;
    final updatedSetting = setting.copyWith(value: newValue);
    final newList = [
      for (final s in list) if (s.key == setting.key) updatedSetting else s,
    ];
    state = AsyncValue.data(newList);

    try {
      await ApiServices.patch(
        _settingsSchemaUrl,
        hasToken: true,
        ref: ref,
        data: {
          "values": {
            setting.key: newValue,
          },
        },
      );
    } catch (e) {
      log('AiDynamicSettings PATCH single error: $e');
      // tutaj możesz ewentualnie dodać rollback jeśli chcesz
    }
  }

  Future<void> saveAll() async {
    final current = state;
    if (current is! AsyncData<List<AiDynamicSetting>>) return;
    final list = current.value;

    final payload = {
      "values": {
        for (final s in list) s.key: s.value,
      },
    };

    try {
      await ApiServices.patch(
        _settingsSchemaUrl,
        hasToken: true,
        ref: ref,
        data: payload,
      );
    } catch (e) {
      log('AiDynamicSettings PATCH all error: $e');
    }
  }
}
