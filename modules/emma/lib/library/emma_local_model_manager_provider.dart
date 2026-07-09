import 'package:emma/library/emma_local_engine_api.dart';
import 'package:emma/library/emma_local_model_installer.dart';
import 'package:emma/library/emma_local_model_installer_types.dart';
import 'package:emma/sync/emma_local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

final emmaLocalEngineBaseUrlProvider = StateProvider<String>((ref) {
  const fromEnv = String.fromEnvironment(
    'SUPERBEE_LOCAL_ENGINE_URL',
    defaultValue: 'http://127.0.0.1:43890',
  );

  return fromEnv;
});

final emmaLocalEngineTokenProvider = StateProvider<String>((ref) {
  const fromEnv = String.fromEnvironment(
    'SUPERBEE_LOCAL_ENGINE_TOKEN',
    defaultValue: 'dev-superbee-token',
  );

  return fromEnv;
});

final emmaLocalEngineApiProvider = Provider<EmmaLocalEngineApi>((ref) {
  return EmmaLocalEngineApi(
    baseUrl: ref.watch(emmaLocalEngineBaseUrlProvider),
    token: ref.watch(emmaLocalEngineTokenProvider),
  );
});

class EmmaLocalModelManagerState {
  const EmmaLocalModelManagerState({
    required this.installed,
    required this.isLoading,
    required this.isActionRunning,
    required this.error,
    required this.engineReachable,
    required this.runtime,
    required this.settings,
  });

  const EmmaLocalModelManagerState.initial()
      : installed = const <EmmaLocalInstalledModel>[],
        isLoading = false,
        isActionRunning = false,
        error = null,
        engineReachable = false,
        runtime = const <String, dynamic>{},
        settings = const <String, dynamic>{};

  final List<EmmaLocalInstalledModel> installed;
  final bool isLoading;
  final bool isActionRunning;
  final String? error;
  final bool engineReachable;
  final Map<String, dynamic> runtime;
  final Map<String, dynamic> settings;

  List<EmmaLocalInstalledModel> byBucket(String bucket) {
    return installed.where((item) => item.taskBucket == bucket).toList();
  }

  EmmaLocalInstalledModel? activeForBucket(String bucket) {
    for (final item in installed) {
      if (item.taskBucket == bucket && item.isActive) return item;
    }

    return null;
  }

  EmmaLocalModelManagerState copyWith({
    List<EmmaLocalInstalledModel>? installed,
    bool? isLoading,
    bool? isActionRunning,
    String? error,
    bool clearError = false,
    bool? engineReachable,
    Map<String, dynamic>? runtime,
    Map<String, dynamic>? settings,
  }) {
    return EmmaLocalModelManagerState(
      installed: installed ?? this.installed,
      isLoading: isLoading ?? this.isLoading,
      isActionRunning: isActionRunning ?? this.isActionRunning,
      error: clearError ? null : error ?? this.error,
      engineReachable: engineReachable ?? this.engineReachable,
      runtime: runtime ?? this.runtime,
      settings: settings ?? this.settings,
    );
  }
}

class EmmaLocalModelManagerNotifier
    extends StateNotifier<EmmaLocalModelManagerState> {
  EmmaLocalModelManagerNotifier(this.ref)
      : super(const EmmaLocalModelManagerState.initial());

  final Ref ref;

  Future<void> load({bool syncManifest = true}) async {
    if (kIsWeb || !EmmaLocalModelInstaller.isSupported) {
      state = state.copyWith(
        installed: const [],
        engineReachable: false,
        isLoading: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final db = EmmaLocalDb.instance;

      if (syncManifest) {
        final manifestModels = await EmmaLocalModelInstaller.listInstalled();
        for (final item in manifestModels) {
          await db.upsertInstalledModel(
            item,
            isActive: item.isActive,
          );
        }
      }

      final installed = await db.getInstalledModels();

      Map<String, dynamic> health = const {};
      Map<String, dynamic> settings = const {};
      var reachable = false;

      try {
        health = await ref.read(emmaLocalEngineApiProvider).health();
        reachable = true;

        settings = await ref.read(emmaLocalEngineApiProvider).settings();
      } catch (_) {
        reachable = false;
      }

      state = state.copyWith(
        installed: installed,
        isLoading: false,
        engineReachable: reachable,
        runtime: _safeMap(health['runtime']),
        settings: settings,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );
    }
  }

  Future<void> activateModel(
    EmmaLocalInstalledModel model, {
    bool loadIntoRuntime = true,
  }) async {
    if (state.isActionRunning) return;

    state = state.copyWith(
      isActionRunning: true,
      clearError: true,
    );

    try {
      await EmmaLocalModelInstaller.activateInstalled(model);

      await EmmaLocalDb.instance.setActiveInstalledModel(
        taskBucket: model.taskBucket,
        modelId: model.modelId,
        fileId: model.fileId,
      );

      if (loadIntoRuntime && model.taskBucket == 'llm') {
        await ref.read(emmaLocalEngineApiProvider).loadModel(
              modelPath: model.localPath,
              nCtx: _asInt(state.settings['n_ctx']),
              nGpuLayers: _asInt(state.settings['n_gpu_layers']),
              nThreads: _asInt(state.settings['n_threads']),
              chatFormat: state.settings['chat_format']?.toString(),
            );
      }

      await load(syncManifest: false);

      state = state.copyWith(
        isActionRunning: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isActionRunning: false,
        error: _cleanError(e),
      );
    }
  }

  Future<void> unloadLlm() async {
    if (state.isActionRunning) return;

    state = state.copyWith(
      isActionRunning: true,
      clearError: true,
    );

    try {
      await ref.read(emmaLocalEngineApiProvider).unloadModel();
      await load(syncManifest: false);

      state = state.copyWith(
        isActionRunning: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isActionRunning: false,
        error: _cleanError(e),
      );
    }
  }

  Future<void> deleteModel(
    EmmaLocalInstalledModel model, {
    bool deleteFiles = true,
  }) async {
    if (state.isActionRunning) return;

    state = state.copyWith(
      isActionRunning: true,
      clearError: true,
    );

    try {
      await EmmaLocalModelInstaller.deleteInstalled(
        modelId: model.modelId,
        fileId: model.fileId,
        deleteFiles: deleteFiles,
      );

      await EmmaLocalDb.instance.deleteInstalledModelRow(
        modelId: model.modelId,
        fileId: model.fileId,
      );

      await load(syncManifest: false);

      state = state.copyWith(
        isActionRunning: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isActionRunning: false,
        error: _cleanError(e),
      );
    }
  }

  Future<void> patchEngineSettings(Map<String, dynamic> updates) async {
    if (state.isActionRunning) return;

    state = state.copyWith(
      isActionRunning: true,
      clearError: true,
    );

    try {
      final settings = await ref.read(emmaLocalEngineApiProvider).patchSettings(
            updates,
          );

      state = state.copyWith(
        isActionRunning: false,
        settings: settings,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isActionRunning: false,
        error: _cleanError(e),
      );
    }
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _cleanError(Object error) {
    var text = error.toString().trim();

    if (text.startsWith('Exception:')) {
      text = text.substring('Exception:'.length).trim();
    }

    if (text.startsWith('StateError:')) {
      text = text.substring('StateError:'.length).trim();
    }

    if (text.isEmpty) return 'unknown_error_occurred'.tr;

    return text;
  }
}

final emmaLocalModelManagerProvider = StateNotifierProvider<
    EmmaLocalModelManagerNotifier, EmmaLocalModelManagerState>((ref) {
  return EmmaLocalModelManagerNotifier(ref);
});