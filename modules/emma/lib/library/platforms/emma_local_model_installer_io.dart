import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:path/path.dart' as p;

import '../emma_local_model_installer_types.dart';
import '../emma_local_models_models.dart';

class EmmaLocalModelInstaller {
  static bool get isSupported {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static Future<String> resolveBaseDir() async {
    final env = Platform.environment;

    final custom = env['SUPERBEE_BASE_DIR'];
    if (custom != null && custom.trim().isNotEmpty) {
      return p.normalize(custom.trim());
    }

    if (Platform.isWindows) {
      final localAppData = env['LOCALAPPDATA'];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        return p.join(localAppData, 'Superbee', 'LocalEngine');
      }

      final userProfile = env['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        return p.join(
          userProfile,
          'AppData',
          'Local',
          'Superbee',
          'LocalEngine',
        );
      }
    }

    if (Platform.isMacOS) {
      final home = env['HOME'] ?? '';
      return p.join(
        home,
        'Library',
        'Application Support',
        'Superbee',
        'LocalEngine',
      );
    }

    final xdgDataHome = env['XDG_DATA_HOME'];
    if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
      return p.join(xdgDataHome, 'Superbee', 'LocalEngine');
    }

    final home = env['HOME'] ?? '';
    return p.join(home, '.local', 'share', 'Superbee', 'LocalEngine');
  }

  static Future<String> resolveModelsDir() async {
    final baseDir = await resolveBaseDir();
    return p.join(baseDir, 'models');
  }

  static Future<String> resolveManifestPath() async {
    final baseDir = await resolveBaseDir();
    return p.join(baseDir, 'models', 'installed_models.json');
  }

  static Future<String> resolveConfigPath() async {
    final baseDir = await resolveBaseDir();
    return p.join(baseDir, 'config.json');
  }

  static Future<void> ensureDirs() async {
    final baseDir = await resolveBaseDir();

    await Directory(baseDir).create(recursive: true);
    await Directory(p.join(baseDir, 'models')).create(recursive: true);
    await Directory(p.join(baseDir, 'models', 'llm')).create(recursive: true);
    await Directory(p.join(baseDir, 'models', 'stt')).create(recursive: true);
    await Directory(p.join(baseDir, 'models', 'tts')).create(recursive: true);
    await Directory(p.join(baseDir, 'logs')).create(recursive: true);

    final manifestFile = File(
      p.join(baseDir, 'models', 'installed_models.json'),
    );

    if (!await manifestFile.exists()) {
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'models': <dynamic>[],
        }),
        encoding: utf8,
      );
    }
  }

  static Future<List<EmmaLocalInstalledModel>> listInstalled() async {
    if (!isSupported) {
      return const <EmmaLocalInstalledModel>[];
    }

    await ensureDirs();

    final baseDir = await resolveBaseDir();
    final manifestFile = File(
      p.join(baseDir, 'models', 'installed_models.json'),
    );

    final manifest = await _readJsonFile(
      manifestFile,
      fallback: {
        'version': 1,
        'models': <dynamic>[],
      },
    );

    final rawModels = manifest['models'];
    if (rawModels is! List) {
      return const <EmmaLocalInstalledModel>[];
    }

    final result = <EmmaLocalInstalledModel>[];

    for (final item in rawModels) {
      if (item is! Map) continue;

      try {
        final installed = EmmaLocalInstalledModel.fromJson(
          Map<String, dynamic>.from(item),
        );

        if (installed.localPath.trim().isEmpty) continue;

        result.add(installed);
      } catch (_) {}
    }

    result.sort((a, b) {
      final bucketCompare = a.taskBucket.compareTo(b.taskBucket);
      if (bucketCompare != 0) return bucketCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return result;
  }

  static Future<bool> isInstalled({
    required String modelId,
    String? fileId,
  }) async {
    final installed = await listInstalled();

    return installed.any((item) {
      final modelMatches = item.modelId == modelId;
      final fileMatches = fileId == null || fileId.isEmpty || item.fileId == fileId;

      if (!modelMatches || !fileMatches) return false;

      return File(item.localPath).existsSync();
    });
  }

  static Future<EmmaLocalInstalledModel?> findInstalled({
    required String modelId,
    String? fileId,
  }) async {
    final installed = await listInstalled();

    for (final item in installed) {
      final modelMatches = item.modelId == modelId;
      final fileMatches = fileId == null || fileId.isEmpty || item.fileId == fileId;

      if (modelMatches && fileMatches) {
        return item;
      }
    }

    return null;
  }

  static Future<EmmaLocalInstalledModel> install(
    EmmaLocalResolveDownloadResponse resolved, {
    String? hfToken,
    ValueChanged<EmmaLocalInstallerProgress>? onProgress,
    bool activateAfterInstall = true,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'local_model_installer_desktop_only'.tr,
      );
    }

    await ensureDirs();

    final baseDir = await resolveBaseDir();
    final modelsDir = Directory(p.join(baseDir, 'models'));

    final bucket = _taskBucketForModel(resolved.model);
    final modelDir = Directory(
      p.join(
        modelsDir.path,
        bucket,
        _safePathSegment(resolved.model.modelId),
      ),
    );

    await modelDir.create(recursive: true);

    final fileName = _safeFileName(
      resolved.download.fileName.isNotEmpty
          ? resolved.download.fileName
          : resolved.file.fileName,
    );

    final targetFile = File(p.join(modelDir.path, fileName));
    final partialFile = File('${targetFile.path}.part');

    final expectedSha = _bestSha256(resolved);
    final expectedSize = resolved.download.sizeBytes ?? resolved.file.sizeBytes;

    if (await targetFile.exists()) {
      final valid = await _isExistingFileValid(
        targetFile,
        expectedSha: expectedSha,
        expectedSize: expectedSize,
        onProgress: onProgress,
      );

      if (valid) {
        final installed = EmmaLocalInstalledModel.fromResolved(
          resolved: resolved,
          taskBucket: bucket,
          localPath: targetFile.path,
        );

        await _writeInstalledManifest(
          baseDir: baseDir,
          installed: installed,
        );

        if (activateAfterInstall) {
          await activateInstalled(installed);
        }

        onProgress?.call(
          EmmaLocalInstallerProgress(
            message:'model_already_installed'.tr,
            receivedBytes: 0,
            totalBytes: 0,
            progress: 1,
          ),
        );

        return installed;
      }

      await targetFile.delete();
    }

    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final url = _downloadUrlForResolved(resolved);
    final headers = _headersForResolved(
      resolved,
      hfToken: hfToken,
    );

    onProgress?.call(
       EmmaLocalInstallerProgress(
        message: 'downloading_model'.tr,
        receivedBytes: 0,
        totalBytes: 0,
        progress: null,
      ),
    );

    final dio = Dio();

    try {
      await dio.download(
        url,
        partialFile.path,
        options: Options(
          headers: headers,
          followRedirects: true,
          receiveTimeout: const Duration(hours: 6),
          sendTimeout: const Duration(minutes: 2),
          validateStatus: (status) {
            return status != null && status >= 200 && status < 400;
          },
        ),
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          onProgress?.call(
            EmmaLocalInstallerProgress(
              message: 'downloading_model'.tr,
              receivedBytes: received,
              totalBytes: total,
              progress: total > 0 ? received / total : null,
            ),
          );
        },
      );
    } on DioException catch (e) {
      if (await partialFile.exists()) {
        await partialFile.delete();
      }

      final status = e.response?.statusCode;
      final message = e.response?.data?.toString().trim();

      if (status == 401 || status == 403) {
        throw StateError(
          'access_denied_model_download'.tr,
        );
      }

      if (message != null && message.isNotEmpty) {
        throw StateError('${'failed_to_download_model'.tr} $message');
      }

      throw StateError('${'failed_to_download_model_generic'.tr} ${e.message}');
    }

    if (!await partialFile.exists()) {
      throw StateError('download_complete_temp_file_missing'.tr);
    }

    if (expectedSha.isNotEmpty) {
      onProgress?.call(
        EmmaLocalInstallerProgress(
          message: 'verifying_sha256'.tr,
          receivedBytes: 0,
          totalBytes: 0,
          progress: null,
        ),
      );

      final actualSha = await _sha256File(partialFile);

      if (actualSha.toLowerCase() != expectedSha.toLowerCase()) {
        await partialFile.delete();

        throw StateError(
          '${'sha256_mismatch_error'.tr} $expectedSha, got $actualSha.',
        );
      }
    }

    if (expectedSize != null && expectedSize > 0) {
      final stat = await partialFile.stat();

      if (stat.size != expectedSize) {
        await partialFile.delete();

        throw StateError(
          '${'file_size_mismatch_error'.tr} $expectedSize bytes, got ${stat.size} bytes.',
        );
      }
    }

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await partialFile.rename(targetFile.path);

    final installed = EmmaLocalInstalledModel.fromResolved(
      resolved: resolved,
      taskBucket: bucket,
      localPath: targetFile.path,
    );

    await _writeInstalledManifest(
      baseDir: baseDir,
      installed: installed,
    );

    if (activateAfterInstall) {
      await activateInstalled(installed);
    }

    onProgress?.call(
       EmmaLocalInstallerProgress(
        message: 'model_installed'.tr,
        receivedBytes: 0,
        totalBytes: 0,
        progress: 1,
      ),
    );

    return installed;
  }

  static Future<void> activateInstalled(
    EmmaLocalInstalledModel installed,
  ) async {
    if (!isSupported) return;

    final baseDir = await resolveBaseDir();

    await _patchEngineConfig(
      baseDir: baseDir,
      installed: installed,
    );

    await _markActiveInManifest(
      baseDir: baseDir,
      installed: installed,
    );
  }

  static Future<bool> deleteInstalled({
    required String modelId,
    String? fileId,
    bool deleteFiles = true,
  }) async {
    if (!isSupported) return false;

    await ensureDirs();

    final baseDir = await resolveBaseDir();
    final manifestFile = File(
      p.join(baseDir, 'models', 'installed_models.json'),
    );

    final manifest = await _readJsonFile(
      manifestFile,
      fallback: {
        'version': 1,
        'models': <dynamic>[],
      },
    );

    final rawModels = manifest['models'];
    final models = rawModels is List ? List<dynamic>.from(rawModels) : <dynamic>[];

    var removed = false;
    final pathsToDelete = <String>[];

    final nextModels = models.where((item) {
      if (item is! Map) return true;

      final itemModelId = item['model_id']?.toString() ?? '';
      final itemFileId = item['file_id']?.toString() ?? '';

      final modelMatches = itemModelId == modelId;
      final fileMatches = fileId == null || fileId.isEmpty || itemFileId == fileId;

      if (modelMatches && fileMatches) {
        removed = true;

        final localPath = item['local_path']?.toString() ?? '';
        if (localPath.trim().isNotEmpty) {
          pathsToDelete.add(localPath);
        }

        return false;
      }

      return true;
    }).toList();

    if (!removed) return false;

    manifest['version'] = 1;
    manifest['updated_at'] = DateTime.now().toIso8601String();
    manifest['models'] = nextModels;

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );

    if (deleteFiles) {
      for (final path in pathsToDelete) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }

          final parent = file.parent;
          if (await parent.exists()) {
            final isEmpty = await parent.list().isEmpty;
            if (isEmpty) {
              await parent.delete();
            }
          }
        } catch (_) {}
      }
    }

    await _cleanupConfigAfterDelete(
      baseDir: baseDir,
      modelId: modelId,
      fileId: fileId,
      removedPaths: pathsToDelete,
    );

    return true;
  }

  static String _downloadUrlForResolved(
    EmmaLocalResolveDownloadResponse resolved,
  ) {
    final download = resolved.download;

    if (download.type == 'ovh_presigned_url' || download.type == 'external_url') {
      if (download.url.trim().isEmpty) {
        throw StateError('download_url_empty'.tr);
      }

      return download.url;
    }

    if (download.type == 'huggingface') {
      final repoId = download.repoId.trim();
      final filename = download.filename.trim();
      final revision = download.revision.trim().isEmpty
          ? 'main'
          : download.revision.trim();

      if (repoId.isEmpty || filename.isEmpty) {
        throw StateError('huggingface_repo_or_filename_empty'.tr);
      }

      final repoParts = repoId.split('/').map(Uri.encodeComponent);
      final filenameParts = filename.split('/').map(Uri.encodeComponent);

      final path = [
        ...repoParts,
        'resolve',
        Uri.encodeComponent(revision),
        ...filenameParts,
      ].join('/');

      return 'https://huggingface.co/$path?download=true';
    }

    throw UnsupportedError('${'unsupported_download_type'.tr} ${download.type}');
  }

  static Map<String, String> _headersForResolved(
    EmmaLocalResolveDownloadResponse resolved, {
    String? hfToken,
  }) {
    final headers = <String, String>{};

    if (resolved.download.type == 'huggingface') {
      final token = hfToken?.trim() ?? '';

      if (resolved.download.requiresUserToken && token.isEmpty) {
        throw StateError(
          'huggingface_token_required'.tr,
        );
      }

      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static String _taskBucketForModel(EmmaLocalModelDto model) {
    final task = model.taskType.toLowerCase().trim();
    final format = model.modelFormat.toLowerCase().trim();
    final runtime = model.runtime.toLowerCase().trim();
    final capabilities = model.capabilities.join(' ').toLowerCase();
    final tags = model.tags.join(' ').toLowerCase();

    final combined = '$task $format $runtime $capabilities $tags';

    if (combined.contains('stt') ||
        combined.contains('speech_to_text') ||
        combined.contains('speech-to-text') ||
        combined.contains('speech to text') ||
        combined.contains('transcription') ||
        combined.contains('whisper')) {
      return 'stt';
    }

    if (combined.contains('tts') ||
        combined.contains('text_to_speech') ||
        combined.contains('text-to-speech') ||
        combined.contains('text to speech') ||
        combined.contains('voice') ||
        combined.contains('piper')) {
      return 'tts';
    }

    return 'llm';
  }

  static Future<bool> _isExistingFileValid(
    File file, {
    required String expectedSha,
    required int? expectedSize,
    required ValueChanged<EmmaLocalInstallerProgress>? onProgress,
  }) async {
    final stat = await file.stat();

    if (expectedSize != null && expectedSize > 0 && stat.size != expectedSize) {
      return false;
    }

    if (expectedSha.trim().isEmpty) {
      return true;
    }

    onProgress?.call(
      EmmaLocalInstallerProgress(
        message: 'checking_existing_file'.tr,
        receivedBytes: 0,
        totalBytes: 0,
        progress: null,
      ),
    );

    final actualSha = await _sha256File(file);
    return actualSha.toLowerCase() == expectedSha.toLowerCase();
  }

  static Future<String> _sha256File(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static String _bestSha256(EmmaLocalResolveDownloadResponse resolved) {
    final fromDownload = resolved.download.sha256.trim();
    if (fromDownload.isNotEmpty) return fromDownload;

    return resolved.file.sha256.trim();
  }

  static String _safePathSegment(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) return 'model';
    return cleaned;
  }

  static String _safeFileName(String value) {
    final base = p.basename(value.trim());

    final cleaned = base
        .replaceAll(RegExp(r'[^a-zA-Z0-9._() -]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) return 'model.bin';
    return cleaned;
  }

  static Future<void> _writeInstalledManifest({
    required String baseDir,
    required EmmaLocalInstalledModel installed,
  }) async {
    final manifestFile = File(
      p.join(baseDir, 'models', 'installed_models.json'),
    );

    await manifestFile.parent.create(recursive: true);

    final manifest = await _readJsonFile(
      manifestFile,
      fallback: {
        'version': 1,
        'models': <dynamic>[],
      },
    );

    final rawModels = manifest['models'];
    final models = rawModels is List ? List<dynamic>.from(rawModels) : <dynamic>[];

    final nextModels = models.where((item) {
      if (item is! Map) return true;

      return item['model_id'] != installed.modelId ||
          item['file_id'] != installed.fileId;
    }).toList();

    nextModels.add(installed.toJson());

    manifest['version'] = 1;
    manifest['updated_at'] = DateTime.now().toIso8601String();
    manifest['models'] = nextModels;

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
  }

  static Future<void> _markActiveInManifest({
    required String baseDir,
    required EmmaLocalInstalledModel installed,
  }) async {
    final manifestFile = File(
      p.join(baseDir, 'models', 'installed_models.json'),
    );

    final manifest = await _readJsonFile(
      manifestFile,
      fallback: {
        'version': 1,
        'models': <dynamic>[],
      },
    );

    final rawModels = manifest['models'];
    final models = rawModels is List ? List<dynamic>.from(rawModels) : <dynamic>[];

    final nextModels = models.map((item) {
      if (item is! Map) return item;

      final map = Map<String, dynamic>.from(item);
      final sameBucket = map['task_bucket'] == installed.taskBucket;
      final sameModel = map['model_id'] == installed.modelId;
      final sameFile = map['file_id'] == installed.fileId;

      if (sameBucket) {
        map['is_active'] = sameModel && sameFile;
      }

      return map;
    }).toList();

    manifest['version'] = 1;
    manifest['updated_at'] = DateTime.now().toIso8601String();
    manifest['models'] = nextModels;

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
  }

  static Future<void> _patchEngineConfig({
    required String baseDir,
    required EmmaLocalInstalledModel installed,
  }) async {
    final configFile = File(p.join(baseDir, 'config.json'));

    await configFile.parent.create(recursive: true);

    final config = await _readJsonFile(
      configFile,
      fallback: <String, dynamic>{},
    );

    config['models_manifest_path'] = p.join(
      baseDir,
      'models',
      'installed_models.json',
    );

    switch (installed.taskBucket) {
      case 'llm':
        config['model_path'] = installed.localPath;
        config['llm_model_path'] = installed.localPath;
        config['active_llm_model_id'] = installed.modelId;
        break;
      case 'stt':
        config['stt_model_path'] = installed.localPath;
        config['active_stt_model_id'] = installed.modelId;
        break;
      case 'tts':
        config['tts_model_path'] = installed.localPath;
        config['active_tts_model_id'] = installed.modelId;
        break;
    }

    config['updated_at'] = DateTime.now().toIso8601String();

    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
      encoding: utf8,
    );
  }

  static Future<void> _cleanupConfigAfterDelete({
    required String baseDir,
    required String modelId,
    required String? fileId,
    required List<String> removedPaths,
  }) async {
    final configFile = File(p.join(baseDir, 'config.json'));

    if (!await configFile.exists()) return;

    final config = await _readJsonFile(
      configFile,
      fallback: <String, dynamic>{},
    );

    var changed = false;

    bool pathWasRemoved(String? pathValue) {
      if (pathValue == null || pathValue.trim().isEmpty) return false;

      return removedPaths.any((path) {
        return p.normalize(path) == p.normalize(pathValue);
      });
    }

    if (pathWasRemoved(config['model_path']?.toString())) {
      config['model_path'] = '';
      changed = true;
    }

    if (pathWasRemoved(config['llm_model_path']?.toString())) {
      config['llm_model_path'] = '';
      config['active_llm_model_id'] = '';
      changed = true;
    }

    if (pathWasRemoved(config['stt_model_path']?.toString())) {
      config['stt_model_path'] = '';
      config['active_stt_model_id'] = '';
      changed = true;
    }

    if (pathWasRemoved(config['tts_model_path']?.toString())) {
      config['tts_model_path'] = '';
      config['active_tts_model_id'] = '';
      changed = true;
    }

    if (config['active_llm_model_id'] == modelId) {
      config['active_llm_model_id'] = '';
      changed = true;
    }

    if (config['active_stt_model_id'] == modelId) {
      config['active_stt_model_id'] = '';
      changed = true;
    }

    if (config['active_tts_model_id'] == modelId) {
      config['active_tts_model_id'] = '';
      changed = true;
    }

    if (!changed) return;

    config['updated_at'] = DateTime.now().toIso8601String();

    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
      encoding: utf8,
    );
  }

  static Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required Map<String, dynamic> fallback,
  }) async {
    if (!await file.exists()) {
      return Map<String, dynamic>.from(fallback);
    }

    try {
      final raw = await file.readAsString(encoding: utf8);
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return Map<String, dynamic>.from(fallback);
  }
}