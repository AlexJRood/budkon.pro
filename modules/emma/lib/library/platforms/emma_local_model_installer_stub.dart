import 'package:flutter/foundation.dart';
import 'package:get/get_utils/get_utils.dart';

import '../emma_local_model_installer_types.dart';
import '../emma_local_models_models.dart';

class EmmaLocalModelInstaller {
  static bool get isSupported => false;

  static Future<String> resolveBaseDir() async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<String> resolveModelsDir() async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<String> resolveManifestPath() async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<String> resolveConfigPath() async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<void> ensureDirs() async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<List<EmmaLocalInstalledModel>> listInstalled() async {
    return const <EmmaLocalInstalledModel>[];
  }

  static Future<bool> isInstalled({
    required String modelId,
    String? fileId,
  }) async {
    return false;
  }

  static Future<EmmaLocalInstalledModel?> findInstalled({
    required String modelId,
    String? fileId,
  }) async {
    return null;
  }

  static Future<EmmaLocalInstalledModel> install(
    EmmaLocalResolveDownloadResponse resolved, {
    String? hfToken,
    ValueChanged<EmmaLocalInstallerProgress>? onProgress,
    bool activateAfterInstall = true,
  }) async {
    throw UnsupportedError(
      'local_model_installer_desktop_only'.tr
    );
  }

  static Future<void> activateInstalled(
    EmmaLocalInstalledModel installed,
  ) async {
    throw UnsupportedError(
      'local_model_activator_desktop_only'.tr
    );
  }

  static Future<bool> deleteInstalled({
    required String modelId,
    String? fileId,
    bool deleteFiles = true,
  }) async {
    return false;
  }
}