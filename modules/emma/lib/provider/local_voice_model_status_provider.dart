import 'dart:async';

import 'package:emma/provider/local_llm_model_status_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

enum EmmaLocalVoiceCapability {
  stt,
  tts,
}

@immutable
class EmmaLocalVoiceModelUiState {
  final EmmaLocalVoiceCapability capability;
  final bool available;
  final bool loaded;
  final bool loading;

  final String loadedModel;
  final String loadedModelName;
  final String displayName;
  final String subtitle;
  final String tooltip;
  final String? error;

  const EmmaLocalVoiceModelUiState({
    required this.capability,
    required this.available,
    required this.loaded,
    required this.loading,
    required this.loadedModel,
    required this.loadedModelName,
    required this.displayName,
    required this.subtitle,
    required this.tooltip,
    this.error,
  });

  factory EmmaLocalVoiceModelUiState.desktopOnly({
    required EmmaLocalVoiceCapability capability,
  }) {
    final label = _capabilityLabel(capability);

    return EmmaLocalVoiceModelUiState(
      capability: capability,
      available: false,
      loaded: false,
      loading: false,
      loadedModel: '',
      loadedModelName: '',
      displayName: label,
      subtitle: 'desktop_only_subtitle'.tr,
      tooltip: '$label ${'desktop_only_tooltip'.tr}'
    );
  }

  factory EmmaLocalVoiceModelUiState.unavailable({
    required EmmaLocalVoiceCapability capability,
    required Object error,
  }) {
    final label = _capabilityLabel(capability);

    return EmmaLocalVoiceModelUiState(
      capability: capability,
      available: false,
      loaded: false,
      loading: false,
      loadedModel: '',
      loadedModelName: '',
      displayName: '$label offline',
      subtitle: 'engine_unavailable_subtitle'.tr,
      tooltip: '$label ${'engine_not_responding_tooltip'.tr}\n$error',
      error: error.toString(),
    );
  }

  factory EmmaLocalVoiceModelUiState.fromResponse({
    required EmmaLocalVoiceCapability capability,
    required Map<String, dynamic> response,
  }) {
    final label = _capabilityLabel(capability);
    final modelState = _asMap(response['model_state']);
    final runtime = _asMap(response['runtime']);
    final providerStatus = _asMap(runtime['provider_status']);

    final loaded = _asBool(modelState['loaded']) ??
        _asBool(runtime['loaded']) ??
        _asBool(providerStatus['loaded']) ??
        false;

    final loading = _asBool(modelState['loading']) ??
        _asBool(runtime['loading']) ??
        _asBool(providerStatus['loading']) ??
        false;

    final loadedModel = _firstString([
          modelState['loaded_model'],
          modelState['loaded_model_id'],
          modelState['loaded_model_path'],
          runtime['loaded_model'],
          runtime['loaded_model_id'],
          runtime['model'],
          runtime['model_id'],
          providerStatus['loaded_model'],
          providerStatus['loaded_model_id'],
          providerStatus['model'],
          providerStatus['model_id'],
        ]) ??
        '';

    final loadedModelName = _firstString([
          modelState['loaded_model_name'],
          _basename(loadedModel),
        ]) ??
        '';

    final displayName = loading
        ? '$label ${'loading_label_display'.tr}'
        : loaded
            ? loadedModelName
            : '$label ${'no_model_label_display'.tr}';

    final subtitle = loading
        ? 'loading_status'.tr
        : loaded
            ? 'loaded_status'.tr
            : 'not_loaded_status'.tr;

    final tooltip = [
      '$label ${'status_tooltip_prefix'.tr}',
      if (loadedModelName.isNotEmpty) '${'model_tooltip_prefix'.tr} $loadedModelName',
      if (loadedModel.isNotEmpty) '${'id_path_tooltip_prefix'.tr} $loadedModel',
      if (!loaded) 'no_loaded_model_tooltip'.tr,
    ].join('\n');

    return EmmaLocalVoiceModelUiState(
      capability: capability,
      available: true,
      loaded: loaded,
      loading: loading,
      loadedModel: loadedModel,
      loadedModelName: loadedModelName,
      displayName: displayName,
      subtitle: subtitle,
      tooltip: tooltip,
    );
  }

  static String _capabilityLabel(EmmaLocalVoiceCapability capability) {
    switch (capability) {
      case EmmaLocalVoiceCapability.stt:
        return 'STT';
      case EmmaLocalVoiceCapability.tts:
        return 'TTS';
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final clean = value.trim().toLowerCase();
      if (clean == 'true' || clean == '1' || clean == 'yes') return true;
      if (clean == 'false' || clean == '0' || clean == 'no') return false;
    }

    return null;
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static String? _basename(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final clean = text.replaceAll('\\', '/');
    final parts = clean.split('/').where((item) => item.trim().isNotEmpty).toList();

    if (parts.isEmpty) return text;
    return parts.last;
  }
}

final emmaLocalVoiceModelStatusRefreshProvider = StateProvider<int>((ref) => 0);

final emmaLocalVoiceModelStatusTickerProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  yield 0;

  await for (final value in Stream.periodic(
    const Duration(seconds: 5),
    (index) => index + 1,
  )) {
    yield value;
  }
});

final emmaLocalSttModelStatusProvider =
    FutureProvider.autoDispose<EmmaLocalVoiceModelUiState>((ref) async {
  ref.watch(emmaLocalVoiceModelStatusRefreshProvider);
  ref.watch(emmaLocalVoiceModelStatusTickerProvider);

  if (kIsWeb) {
    return EmmaLocalVoiceModelUiState.desktopOnly(
      capability: EmmaLocalVoiceCapability.stt,
    );
  }

  final api = ref.watch(emmaLocalEngineApiProvider);

  try {
    final response = await api.sttHealth();

    return EmmaLocalVoiceModelUiState.fromResponse(
      capability: EmmaLocalVoiceCapability.stt,
      response: response,
    );
  } catch (error) {
    return EmmaLocalVoiceModelUiState.unavailable(
      capability: EmmaLocalVoiceCapability.stt,
      error: error,
    );
  }
});

final emmaLocalTtsModelStatusProvider =
    FutureProvider.autoDispose<EmmaLocalVoiceModelUiState>((ref) async {
  ref.watch(emmaLocalVoiceModelStatusRefreshProvider);
  ref.watch(emmaLocalVoiceModelStatusTickerProvider);

  if (kIsWeb) {
    return EmmaLocalVoiceModelUiState.desktopOnly(
      capability: EmmaLocalVoiceCapability.tts,
    );
  }

  final api = ref.watch(emmaLocalEngineApiProvider);

  try {
    final response = await api.ttsHealth();

    return EmmaLocalVoiceModelUiState.fromResponse(
      capability: EmmaLocalVoiceCapability.tts,
      response: response,
    );
  } catch (error) {
    return EmmaLocalVoiceModelUiState.unavailable(
      capability: EmmaLocalVoiceCapability.tts,
      error: error,
    );
  }
});