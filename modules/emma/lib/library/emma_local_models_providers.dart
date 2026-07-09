import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'emma_local_model_installer.dart';
import 'emma_local_model_installer_types.dart';
import 'emma_local_models_api.dart';
import 'emma_local_models_config.dart';
import 'emma_local_models_models.dart';

final emmaLocalModelsApiProvider = Provider<EmmaLocalModelsApi>((ref) {
  return EmmaLocalModelsApi(
    baseUrl: ref.watch(emmaLocalApiBaseUrlProvider),
  );
});

final emmaLocalHfTokenProvider = StateProvider<String>((ref) {
  return '';
});

class EmmaLocalCatalogState {
  const EmmaLocalCatalogState({
    required this.models,
    required this.isLoading,
    required this.error,
    required this.search,
    required this.taskType,
    required this.runtime,
    required this.modelFormat,
    required this.sourceType,
    required this.featuredOnly,
  });

  const EmmaLocalCatalogState.initial()
      : models = const <EmmaLocalModelDto>[],
        isLoading = false,
        error = null,
        search = '',
        taskType = null,
        runtime = null,
        modelFormat = null,
        sourceType = null,
        featuredOnly = false;

  final List<EmmaLocalModelDto> models;
  final bool isLoading;
  final String? error;

  final String search;
  final String? taskType;
  final String? runtime;
  final String? modelFormat;
  final String? sourceType;
  final bool featuredOnly;

  EmmaLocalCatalogState copyWith({
    List<EmmaLocalModelDto>? models,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? taskType,
    bool clearTaskType = false,
    String? runtime,
    bool clearRuntime = false,
    String? modelFormat,
    bool clearModelFormat = false,
    String? sourceType,
    bool clearSourceType = false,
    bool? featuredOnly,
  }) {
    return EmmaLocalCatalogState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      taskType: clearTaskType ? null : taskType ?? this.taskType,
      runtime: clearRuntime ? null : runtime ?? this.runtime,
      modelFormat: clearModelFormat ? null : modelFormat ?? this.modelFormat,
      sourceType: clearSourceType ? null : sourceType ?? this.sourceType,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }

  bool get hasFilters {
    return search.trim().isNotEmpty ||
        taskType?.trim().isNotEmpty == true ||
        runtime?.trim().isNotEmpty == true ||
        modelFormat?.trim().isNotEmpty == true ||
        sourceType?.trim().isNotEmpty == true ||
        featuredOnly;
  }

  List<String> get taskTypes {
    return _uniqueSorted(
      models.map((model) => model.taskType),
    );
  }

  List<String> get runtimes {
    return _uniqueSorted(
      models.map((model) => model.runtime),
    );
  }

  List<String> get modelFormats {
    return _uniqueSorted(
      models.map((model) => model.modelFormat),
    );
  }

  List<String> get sourceTypes {
    return _uniqueSorted(
      models.map((model) => model.sourceType),
    );
  }

  List<EmmaLocalModelDto> get filteredModels {
    final q = search.trim().toLowerCase();

    final filtered = models.where((model) {
      if (!_matchesExactFilter(model.taskType, taskType)) return false;
      if (!_matchesExactFilter(model.runtime, runtime)) return false;
      if (!_matchesExactFilter(model.modelFormat, modelFormat)) return false;
      if (!_matchesExactFilter(model.sourceType, sourceType)) return false;

      if (featuredOnly && !model.isFeatured) {
        return false;
      }

      if (q.isEmpty) return true;

      final haystack = [
        model.name,
        model.modelId,
        model.shortDescription,
        model.description,
        model.taskType,
        model.runtime,
        model.modelFormat,
        model.family,
        model.version,
        model.quantization,
        model.sourceType,
        model.hfRepoId,
        model.licenseName,
        ...model.tags,
        ...model.languages,
        ...model.capabilities,
      ].join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList();

    filtered.sort((a, b) {
      if (a.isFeatured != b.isFeatured) {
        return a.isFeatured ? -1 : 1;
      }

      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  static bool _matchesExactFilter(String modelValue, String? selectedValue) {
    final selected = selectedValue?.trim();
    if (selected == null || selected.isEmpty) return true;

    return modelValue.trim().toLowerCase() == selected.toLowerCase();
  }

  static List<String> _uniqueSorted(Iterable<String> values) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }
}

class EmmaLocalCatalogNotifier extends StateNotifier<EmmaLocalCatalogState> {
  EmmaLocalCatalogNotifier(this.ref)
      : super(const EmmaLocalCatalogState.initial());

  final Ref ref;

  int _requestSerial = 0;

  Future<void> load({bool force = false}) async {
    if (state.isLoading && !force) return;

    final requestId = ++_requestSerial;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final api = ref.read(emmaLocalModelsApiProvider);

      final models = await api.catalog(
        ref: ref,
      );

      if (!mounted || requestId != _requestSerial) return;

      state = state.copyWith(
        models: models,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;

      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );
    }
  }

  Future<void> refresh() {
    return load(force: true);
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setTaskType(String? value) {
    final cleaned = _cleanNullableFilter(value);

    state = state.copyWith(
      taskType: cleaned,
      clearTaskType: cleaned == null,
    );
  }

  void setRuntime(String? value) {
    final cleaned = _cleanNullableFilter(value);

    state = state.copyWith(
      runtime: cleaned,
      clearRuntime: cleaned == null,
    );
  }

  void setModelFormat(String? value) {
    final cleaned = _cleanNullableFilter(value);

    state = state.copyWith(
      modelFormat: cleaned,
      clearModelFormat: cleaned == null,
    );
  }

  void setSourceType(String? value) {
    final cleaned = _cleanNullableFilter(value);

    state = state.copyWith(
      sourceType: cleaned,
      clearSourceType: cleaned == null,
    );
  }

  void setFeaturedOnly(bool value) {
    state = state.copyWith(featuredOnly: value);
  }

  void clearFilters() {
    state = state.copyWith(
      search: '',
      clearTaskType: true,
      clearRuntime: true,
      clearModelFormat: true,
      clearSourceType: true,
      featuredOnly: false,
    );
  }

  static String? _cleanNullableFilter(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }
}

final emmaLocalCatalogProvider =
    StateNotifierProvider<EmmaLocalCatalogNotifier, EmmaLocalCatalogState>(
  (ref) {
    return EmmaLocalCatalogNotifier(ref);
  },
);

final emmaLocalModelDetailProvider =
    FutureProvider.autoDispose.family<EmmaLocalModelDto, String>(
  (ref, modelId) {
    return ref.read(emmaLocalModelsApiProvider).detail(
          ref: ref,
          modelId: modelId,
        );
  },
);

class EmmaLocalModelActions {
  const EmmaLocalModelActions(this.ref);

  final Ref ref;

  Future<void> acceptLicense(String modelId) {
    return ref.read(emmaLocalModelsApiProvider).acceptLicense(
          ref: ref,
          modelId: modelId,
        );
  }

  Future<EmmaLocalResolveDownloadResponse> resolveDownload({
    required String modelId,
    String? fileId,
  }) {
    return ref.read(emmaLocalModelsApiProvider).resolveDownload(
          ref: ref,
          modelId: modelId,
          fileId: fileId,
          platform: _platformName(),
        );
  }
}

final emmaLocalModelActionsProvider = Provider<EmmaLocalModelActions>((ref) {
  return EmmaLocalModelActions(ref);
});

typedef EmmaLocalInstallHandler = Future<EmmaLocalInstalledModel> Function(
  EmmaLocalResolveDownloadResponse resolved, {
  ValueChanged<EmmaLocalInstallerProgress>? onProgress,
  String? hfToken,
  bool activateAfterInstall,
});

final emmaLocalInstallHandlerProvider = Provider<EmmaLocalInstallHandler?>(
  (ref) {
    if (!EmmaLocalModelInstaller.isSupported) return null;

    return (
      EmmaLocalResolveDownloadResponse resolved, {
      ValueChanged<EmmaLocalInstallerProgress>? onProgress,
      String? hfToken,
      bool activateAfterInstall = true,
    }) {
      return EmmaLocalModelInstaller.install(
        resolved,
        hfToken: hfToken,
        onProgress: onProgress,
        activateAfterInstall: activateAfterInstall,
      );
    };
  },
);

enum EmmaLocalInstallPhase {
  idle,
  resolving,
  downloading,
  verifying,
  installing,
  installed,
  error,
}

class EmmaLocalInstallProgressState {
  const EmmaLocalInstallProgressState({
    required this.phase,
    required this.message,
    required this.resolved,
    required this.installed,
    required this.progress,
  });

  const EmmaLocalInstallProgressState.idle()
      : phase = EmmaLocalInstallPhase.idle,
        message = '',
        resolved = null,
        installed = null,
        progress = null;

  final EmmaLocalInstallPhase phase;
  final String message;
  final EmmaLocalResolveDownloadResponse? resolved;
  final EmmaLocalInstalledModel? installed;
  final double? progress;

  bool get isBusy {
    return phase == EmmaLocalInstallPhase.resolving ||
        phase == EmmaLocalInstallPhase.downloading ||
        phase == EmmaLocalInstallPhase.verifying ||
        phase == EmmaLocalInstallPhase.installing;
  }

  bool get isDone => phase == EmmaLocalInstallPhase.installed;
  bool get isError => phase == EmmaLocalInstallPhase.error;

  EmmaLocalInstallProgressState copyWith({
    EmmaLocalInstallPhase? phase,
    String? message,
    EmmaLocalResolveDownloadResponse? resolved,
    bool clearResolved = false,
    EmmaLocalInstalledModel? installed,
    bool clearInstalled = false,
    double? progress,
    bool clearProgress = false,
  }) {
    return EmmaLocalInstallProgressState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      resolved: clearResolved ? null : resolved ?? this.resolved,
      installed: clearInstalled ? null : installed ?? this.installed,
      progress: clearProgress ? null : progress ?? this.progress,
    );
  }
}

/// Backward-compatible alias, żeby starszy dialog z poprzedniego kodu nadal działał.
typedef EmmaLocalInstallProgress = EmmaLocalInstallProgressState;

class EmmaLocalInstallNotifier
    extends StateNotifier<Map<String, EmmaLocalInstallProgressState>> {
  EmmaLocalInstallNotifier(this.ref) : super(const {});

  final Ref ref;

  EmmaLocalInstallProgressState progressFor(String modelId) {
    return state[modelId] ?? const EmmaLocalInstallProgressState.idle();
  }

  Future<void> install({
    required EmmaLocalModelDto model,
    String? fileId,
    bool activateAfterInstall = true,
  }) async {
    final key = model.modelId.trim();

    if (key.isEmpty) {
      return;
    }

    final current = progressFor(key);
    if (current.isBusy) return;

    if (!model.userHasAccess) {
      _set(
        key,
        EmmaLocalInstallProgressState(
          phase: EmmaLocalInstallPhase.error,
          message: 'no_access_to_model'.tr,
          resolved: null,
          installed: null,
          progress: null,
        ),
      );
      return;
    }

    if (model.requiresLicenseAcceptance && !model.licenseAccepted) {
      _set(
        key,
         EmmaLocalInstallProgressState(
          phase: EmmaLocalInstallPhase.error,
          message: 'accept_license_first'.tr,
          resolved: null,
          installed: null,
          progress: null,
        ),
      );
      return;
    }

    _set(
      key,
      EmmaLocalInstallProgressState(
        phase: EmmaLocalInstallPhase.resolving,
        message: 'preparing_download'.tr,
        resolved: null,
        installed: null,
        progress: null,
      ),
    );

    try {
      final resolved = await ref.read(emmaLocalModelActionsProvider).resolveDownload(
            modelId: model.modelId,
            fileId: fileId,
          );

      if (!mounted) return;

      _set(
        key,
        EmmaLocalInstallProgressState(
          phase: EmmaLocalInstallPhase.installing,
          message: 'preparing_local_install'.tr,
          resolved: resolved,
          installed: null,
          progress: null,
        ),
      );

      final handler = ref.read(emmaLocalInstallHandlerProvider);

      if (handler == null) {
        _set(
          key,
          EmmaLocalInstallProgressState(
            phase: EmmaLocalInstallPhase.error,
            message:
                'local_install_desktop_only'.tr,
            resolved: resolved,
            installed: null,
            progress: null,
          ),
        );
        return;
      }

      final hfToken = ref.read(emmaLocalHfTokenProvider).trim();

      final installed = await handler(
        resolved,
        hfToken: hfToken.isEmpty ? null : hfToken,
        activateAfterInstall: activateAfterInstall,
        onProgress: (progress) {
          if (!mounted) return;

          _set(
            key,
            EmmaLocalInstallProgressState(
              phase: _phaseFromInstallerMessage(progress.message),
              message: progress.label,
              resolved: resolved,
              installed: null,
              progress: progress.progress,
            ),
          );
        },
      );

      if (!mounted) return;

      _set(
        key,
        EmmaLocalInstallProgressState(
          phase: EmmaLocalInstallPhase.installed,
          message: 'model_installed_locally'.tr,
          resolved: resolved,
          installed: installed,
          progress: 1,
        ),
      );

      ref.invalidate(emmaLocalInstalledModelsProvider);
    } catch (e) {
      if (!mounted) return;

      _set(
        key,
        EmmaLocalInstallProgressState(
          phase: EmmaLocalInstallPhase.error,
          message: _cleanError(e),
          resolved: null,
          installed: null,
          progress: null,
        ),
      );
    }
  }

  void reset(String modelId) {
    final key = modelId.trim();
    if (key.isEmpty) return;

    final next = Map<String, EmmaLocalInstallProgressState>.from(state);
    next.remove(key);
    state = next;
  }

  void clearAll() {
    state = const {};
  }

  void _set(String modelId, EmmaLocalInstallProgressState progress) {
    state = {
      ...state,
      modelId: progress,
    };
  }

  static EmmaLocalInstallPhase _phaseFromInstallerMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('pobier')) {
      return EmmaLocalInstallPhase.downloading;
    }

    if (lower.contains('sha') ||
        lower.contains('weryfik') ||
        lower.contains('sprawdz')) {
      return EmmaLocalInstallPhase.verifying;
    }

    return EmmaLocalInstallPhase.installing;
  }
}

final emmaLocalInstallProvider = StateNotifierProvider<
    EmmaLocalInstallNotifier, Map<String, EmmaLocalInstallProgressState>>(
  (ref) {
    return EmmaLocalInstallNotifier(ref);
  },
);

final emmaLocalInstalledModelsProvider =
    FutureProvider.autoDispose<List<EmmaLocalInstalledModel>>((ref) async {
  if (!EmmaLocalModelInstaller.isSupported) {
    return const <EmmaLocalInstalledModel>[];
  }

  try {
    return EmmaLocalModelInstaller.listInstalled();
  } catch (_) {
    return const <EmmaLocalInstalledModel>[];
  }
});

final emmaLocalInstalledModelsByIdProvider =
    Provider.autoDispose<Map<String, EmmaLocalInstalledModel>>((ref) {
  final installedAsync = ref.watch(emmaLocalInstalledModelsProvider);

  return installedAsync.maybeWhen(
    data: (items) {
      final map = <String, EmmaLocalInstalledModel>{};

      for (final item in items) {
        map[item.modelId] = item;
      }

      return map;
    },
    orElse: () => const <String, EmmaLocalInstalledModel>{},
  );
});

String _platformName() {
  if (kIsWeb) return 'unknown';

  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return 'unknown';
  }
}

String _cleanError(Object error) {
  var text = error.toString().trim();

  if (text.startsWith('Exception:')) {
    text = text.substring('Exception:'.length).trim();
  }

  if (text.startsWith('StateError:')) {
    text = text.substring('StateError:'.length).trim();
  }

  if (text.startsWith('Unsupported operation:')) {
    text = text.substring('Unsupported operation:'.length).trim();
  }

  if (text.isEmpty) {
    return 'unknown_error_occurred'.tr;
  }

  return text;
}