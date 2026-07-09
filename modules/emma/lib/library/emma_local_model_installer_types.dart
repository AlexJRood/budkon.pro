import 'emma_local_models_models.dart';

class EmmaLocalInstallerProgress {
  const EmmaLocalInstallerProgress({
    required this.message,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
  });

  final String message;
  final int receivedBytes;
  final int totalBytes;
  final double? progress;

  String get label {
    if (progress == null) return message;

    final percent = (progress!.clamp(0, 1) * 100).toStringAsFixed(0);
    return '$message $percent%';
  }
}

class EmmaLocalInstalledModel {
  const EmmaLocalInstalledModel({
    required this.modelId,
    required this.name,
    required this.taskBucket,
    required this.fileId,
    required this.fileName,
    required this.localPath,
    required this.sizeBytes,
    required this.sha256,
    required this.installedAt,
    required this.sourceType,
    required this.downloadType,
    required this.isActive,
  });

  final String modelId;
  final String name;
  final String taskBucket;
  final String fileId;
  final String fileName;
  final String localPath;
  final int? sizeBytes;
  final String sha256;
  final DateTime installedAt;
  final String sourceType;
  final String downloadType;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'name': name,
      'task_bucket': taskBucket,
      'file_id': fileId,
      'file_name': fileName,
      'local_path': localPath,
      'size_bytes': sizeBytes,
      'sha256': sha256,
      'installed_at': installedAt.toIso8601String(),
      'source_type': sourceType,
      'download_type': downloadType,
      'is_active': isActive,
    };
  }

  factory EmmaLocalInstalledModel.fromJson(Map<String, dynamic> json) {
    return EmmaLocalInstalledModel(
      modelId: _string(json['model_id']),
      name: _string(json['name']),
      taskBucket: _string(json['task_bucket']).isEmpty
          ? 'llm'
          : _string(json['task_bucket']),
      fileId: _string(json['file_id']),
      fileName: _string(json['file_name']),
      localPath: _string(json['local_path']),
      sizeBytes: _intOrNull(json['size_bytes']),
      sha256: _string(json['sha256']),
      installedAt: _dateOrNow(json['installed_at']),
      sourceType: _string(json['source_type']),
      downloadType: _string(json['download_type']),
      isActive: _bool(json['is_active']),
    );
  }

  factory EmmaLocalInstalledModel.fromResolved({
    required EmmaLocalResolveDownloadResponse resolved,
    required String taskBucket,
    required String localPath,
    bool isActive = false,
  }) {
    return EmmaLocalInstalledModel(
      modelId: resolved.model.modelId,
      name: resolved.model.name,
      taskBucket: taskBucket,
      fileId: resolved.file.fileId,
      fileName: resolved.download.fileName.isNotEmpty
          ? resolved.download.fileName
          : resolved.file.fileName,
      localPath: localPath,
      sizeBytes: resolved.download.sizeBytes ?? resolved.file.sizeBytes,
      sha256: resolved.download.sha256.isNotEmpty
          ? resolved.download.sha256
          : resolved.file.sha256,
      installedAt: DateTime.now(),
      sourceType: resolved.file.sourceType,
      downloadType: resolved.download.type,
      isActive: isActive,
    );
  }

  EmmaLocalInstalledModel copyWith({
    String? modelId,
    String? name,
    String? taskBucket,
    String? fileId,
    String? fileName,
    String? localPath,
    int? sizeBytes,
    bool clearSizeBytes = false,
    String? sha256,
    DateTime? installedAt,
    String? sourceType,
    String? downloadType,
    bool? isActive,
  }) {
    return EmmaLocalInstalledModel(
      modelId: modelId ?? this.modelId,
      name: name ?? this.name,
      taskBucket: taskBucket ?? this.taskBucket,
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      sizeBytes: clearSizeBytes ? null : sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      installedAt: installedAt ?? this.installedAt,
      sourceType: sourceType ?? this.sourceType,
      downloadType: downloadType ?? this.downloadType,
      isActive: isActive ?? this.isActive,
    );
  }
}

String _string(dynamic value) {
  return value?.toString() ?? '';
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  if (value is String) {
    final lower = value.trim().toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'tak';
  }

  return false;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

DateTime _dateOrNow(dynamic value) {
  if (value is DateTime) return value;

  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return DateTime.now();

  return DateTime.tryParse(text) ?? DateTime.now();
}