import 'dart:async';

import 'package:emma/provider/urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust this import if your EmmaLocalEngineApi file lives elsewhere.
import 'package:emma/library/emma_local_engine_api.dart';
import 'package:get/get_utils/get_utils.dart';

@immutable
class EmmaLocalModelUiState {
  final bool available;
  final bool loaded;
  final bool loading;
  final bool selectedLoaded;

  final String? loadedModelPath;
  final String? loadedModelName;

  final String? selectedModelPath;
  final String? selectedModelName;

  final String displayName;
  final String subtitle;
  final String tooltip;
  final String? error;

  const EmmaLocalModelUiState({
    required this.available,
    required this.loaded,
    required this.loading,
    required this.selectedLoaded,
    required this.loadedModelPath,
    required this.loadedModelName,
    required this.selectedModelPath,
    required this.selectedModelName,
    required this.displayName,
    required this.subtitle,
    required this.tooltip,
    this.error,
  });

  factory EmmaLocalModelUiState.cloudOnly() {
    return  EmmaLocalModelUiState(
      available: true,
      loaded: false,
      loading: false,
      selectedLoaded: false,
      loadedModelPath: null,
      loadedModelName: null,
      selectedModelPath: null,
      selectedModelName: null,
      displayName: 'cloud_mode_label'.tr,
      subtitle: 'backend_model_subtitle'.tr,
      tooltip: 'cloud_mode_tooltip'.tr,
    );
  }

  factory EmmaLocalModelUiState.unavailable({
    required String error,
  }) {
    return EmmaLocalModelUiState(
      available: false,
      loaded: false,
      loading: false,
      selectedLoaded: false,
      loadedModelPath: null,
      loadedModelName: null,
      selectedModelPath: null,
      selectedModelName: null,
      displayName:'local_offline_label'.tr,
      subtitle: 'engine_unavailable_subtitle'.tr,
      tooltip: '${'local_engine_not_responding_tooltip'.tr}\n$error',
      error: error,
    );
  }

  factory EmmaLocalModelUiState.fromResponses({
    required Map<String, dynamic> modelsResponse,
    required Map<String, dynamic> settingsResponse,
  }) {
    final runtime = _asMap(modelsResponse['runtime']);
    final providerStatus = _asMap(runtime['provider_status']);
    final modelState = _asMap(
      modelsResponse['model_state'] ??
          runtime['model_state'] ??
          providerStatus['model_state'],
    );

    final items = _asMapList(modelsResponse['items']);

    final loaded = _asBool(modelState['loaded']) ??
        _asBool(runtime['loaded']) ??
        _asBool(providerStatus['loaded']) ??
        false;

    final loading = _asBool(modelState['loading']) ??
        _asBool(providerStatus['loading']) ??
        false;

    final loadedPath = _firstString([
      modelState['loaded_model_path'],
      runtime['model_path'],
      providerStatus['model_path'],
    ]);

    final selectedPath = _firstString([
      modelState['selected_model_path'],
      settingsResponse['llm_model_path'],
      settingsResponse['model_path'],
      settingsResponse['active_llm_model_id'],
    ]);

    final loadedItem = _findModelItem(
      items: items,
      pathOrId: loadedPath,
      loaded: true,
    );

    final selectedItem = _findModelItem(
      items: items,
      pathOrId: selectedPath,
      selected: true,
    );

    final loadedName = _firstString([
      modelState['loaded_model_name'],
      loadedItem?['name'],
      _basename(loadedPath),
    ]);

    final selectedName = _firstString([
      modelState['selected_model_name'],
      selectedItem?['name'],
      _basename(selectedPath),
    ]);

    final selectedLoaded = loaded &&
        loadedPath != null &&
        selectedPath != null &&
        _samePathOrId(loadedPath, selectedPath);

    final displayName = loading
        ? 'loading_model_display'.tr
        : loaded
            ? loadedName ?? 'model_loaded_display'.tr
            : selectedName != null
                ? selectedName
                : 'no_model_display'.tr;

    final subtitle = loading
        ? 'local_runtime_subtitle'.tr
        : loaded
            ? selectedLoaded
                ? 'loaded_status'.tr
                : 'loaded_other_than_selected'.tr
            : selectedName != null
                ? 'selected_not_loaded'.tr
                : 'no_model_selected'.tr;

    final tooltipLines = <String>[
      if (loadedName != null) '${'loaded_prefix'.tr} $loadedName',
      if (selectedName != null) '${'selected_prefix'.tr} $selectedName',
      if (loadedPath != null) '${'loaded_path_prefix'.tr} $loadedPath',
      if (selectedPath != null) '${'selected_path_prefix'.tr} $selectedPath',
      if (loadedName == null && selectedName == null) 'no_active_local_model'.tr,
    ];

    return EmmaLocalModelUiState(
      available: true,
      loaded: loaded,
      loading: loading,
      selectedLoaded: selectedLoaded,
      loadedModelPath: loadedPath,
      loadedModelName: loadedName,
      selectedModelPath: selectedPath,
      selectedModelName: selectedName,
      displayName: displayName,
      subtitle: subtitle,
      tooltip: tooltipLines.join('\n'),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  static Map<String, dynamic>? _findModelItem({
    required List<Map<String, dynamic>> items,
    required String? pathOrId,
    bool loaded = false,
    bool selected = false,
  }) {
    if (items.isEmpty) return null;

    if (loaded) {
      for (final item in items) {
        if (_asBool(item['loaded']) == true) {
          return item;
        }
      }
    }

    if (selected) {
      for (final item in items) {
        if (_asBool(item['selected']) == true) {
          return item;
        }
      }
    }

    if (pathOrId == null || pathOrId.trim().isEmpty) return null;

    final needle = _normalizeComparable(pathOrId);

    for (final item in items) {
      final id = item['id']?.toString();
      final path = item['path']?.toString();
      final name = item['name']?.toString();

      if (_normalizeComparable(id) == needle ||
          _normalizeComparable(path) == needle ||
          _normalizeComparable(name) == needle) {
        return item;
      }
    }

    final needleBase = _basename(pathOrId);

    if (needleBase != null) {
      for (final item in items) {
        final name = item['name']?.toString();
        if (_normalizeComparable(name) == _normalizeComparable(needleBase)) {
          return item;
        }
      }
    }

    return null;
  }

  static bool _samePathOrId(String left, String right) {
    final normalizedLeft = _normalizeComparable(left);
    final normalizedRight = _normalizeComparable(right);

    if (normalizedLeft == normalizedRight) return true;

    final leftBase = _basename(left);
    final rightBase = _basename(right);

    if (leftBase == null || rightBase == null) return false;

    return _normalizeComparable(leftBase) == _normalizeComparable(rightBase);
  }

  static String _normalizeComparable(String? value) {
    return (value ?? '')
        .replaceAll('\\', '/')
        .trim()
        .toLowerCase();
  }
}

final emmaLocalEngineApiProvider = Provider<EmmaLocalEngineApi>((ref) {
  return EmmaLocalEngineApi(
    baseUrl: URLsEmma.superbeeBaseUrl,
    token: URLsEmma.superbeeToken,
  );
});

final emmaLocalModelStatusRefreshProvider = StateProvider<int>((ref) => 0);

final emmaLocalModelStatusTickerProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield 0;

  await for (final value in Stream.periodic(
    const Duration(seconds: 5),
    (index) => index + 1,
  )) {
    yield value;
  }
});

final emmaLocalModelStatusProvider =
    FutureProvider.autoDispose<EmmaLocalModelUiState>((ref) async {
  ref.watch(emmaLocalModelStatusRefreshProvider);
  ref.watch(emmaLocalModelStatusTickerProvider);

  if (kIsWeb) {
    return EmmaLocalModelUiState.cloudOnly();
  }

  final api = ref.watch(emmaLocalEngineApiProvider);

  try {
    final modelsResponse = await api.models();

    Map<String, dynamic> settingsResponse = <String, dynamic>{};

    try {
      settingsResponse = await api.settings();
    } catch (_) {
      // Models endpoint already contains runtime info, so settings are optional.
    }

    return EmmaLocalModelUiState.fromResponses(
      modelsResponse: modelsResponse,
      settingsResponse: settingsResponse,
    );
  } catch (error) {
    return EmmaLocalModelUiState.unavailable(
      error: error.toString(),
    );
  }
});