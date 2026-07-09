class EmmaLocalModelFileDto {
  const EmmaLocalModelFileDto({
    required this.id,
    required this.uuid,
    required this.fileId,
    required this.kind,
    required this.sourceType,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.sha256,
    required this.s3Key,
    required this.storageUrl,
    required this.hfRepoId,
    required this.hfFilename,
    required this.hfRevision,
    required this.externalUrl,
    required this.localPathHint,
    required this.isPrimary,
    required this.isRequired,
    required this.sortOrder,
    required this.status,
    required this.metadata,
  });

  final int? id;
  final String uuid;
  final String fileId;
  final String kind;
  final String sourceType;
  final String fileName;
  final String contentType;
  final int? sizeBytes;
  final String sha256;
  final String s3Key;
  final String storageUrl;
  final String hfRepoId;
  final String hfFilename;
  final String hfRevision;
  final String externalUrl;
  final String localPathHint;
  final bool isPrimary;
  final bool isRequired;
  final int sortOrder;
  final String status;
  final Map<String, dynamic> metadata;

  factory EmmaLocalModelFileDto.fromJson(Map<String, dynamic> json) {
    return EmmaLocalModelFileDto(
      id: _intOrNull(json['id']),
      uuid: _string(json['uuid']),
      fileId: _string(json['file_id']),
      kind: _string(json['kind']),
      sourceType: _string(json['source_type']),
      fileName: _string(json['file_name']),
      contentType: _string(json['content_type']),
      sizeBytes: _intOrNull(json['size_bytes']),
      sha256: _string(json['sha256']),
      s3Key: _string(json['s3_key']),
      storageUrl: _string(json['storage_url']),
      hfRepoId: _string(json['hf_repo_id']),
      hfFilename: _string(json['hf_filename']),
      hfRevision: _string(json['hf_revision']),
      externalUrl: _string(json['external_url']),
      localPathHint: _string(json['local_path_hint']),
      isPrimary: _bool(json['is_primary']),
      isRequired: _bool(json['is_required']),
      sortOrder: _int(json['sort_order'], fallback: 1000),
      status: _string(json['status']),
      metadata: _map(json['metadata']),
    );
  }
}

class EmmaLocalModelDto {
  const EmmaLocalModelDto({
    required this.id,
    required this.uuid,
    required this.modelId,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.taskType,
    required this.runtime,
    required this.modelFormat,
    required this.family,
    required this.version,
    required this.quantization,
    required this.parametersBillions,
    required this.contextLength,
    required this.sourceType,
    required this.distributionPolicy,
    required this.hfRepoId,
    required this.hfRevision,
    required this.hfAccessMode,
    required this.licenseName,
    required this.licenseUrl,
    required this.licenseText,
    required this.requiresLicenseAcceptance,
    required this.minRamGb,
    required this.recommendedRamGb,
    required this.minVramGb,
    required this.recommendedVramGb,
    required this.supportsCpu,
    required this.supportsGpu,
    required this.supportsMacos,
    required this.supportsWindows,
    required this.supportsLinux,
    required this.languages,
    required this.tags,
    required this.capabilities,
    required this.accessMode,
    required this.status,
    required this.isActive,
    required this.isFeatured,
    required this.sortOrder,
    required this.deprecationMessage,
    required this.releaseNotes,
    required this.metadata,
    required this.primaryFile,
    required this.files,
    required this.userHasAccess,
    required this.licenseAccepted,
  });

  final int? id;
  final String uuid;
  final String modelId;
  final String name;
  final String shortDescription;
  final String description;
  final String taskType;
  final String runtime;
  final String modelFormat;
  final String family;
  final String version;
  final String quantization;
  final double? parametersBillions;
  final int? contextLength;
  final String sourceType;
  final String distributionPolicy;
  final String hfRepoId;
  final String hfRevision;
  final String hfAccessMode;
  final String licenseName;
  final String licenseUrl;
  final String licenseText;
  final bool requiresLicenseAcceptance;
  final double? minRamGb;
  final double? recommendedRamGb;
  final double? minVramGb;
  final double? recommendedVramGb;
  final bool supportsCpu;
  final bool supportsGpu;
  final bool supportsMacos;
  final bool supportsWindows;
  final bool supportsLinux;
  final List<String> languages;
  final List<String> tags;
  final List<String> capabilities;
  final String accessMode;
  final String status;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final String deprecationMessage;
  final String releaseNotes;
  final Map<String, dynamic> metadata;
  final EmmaLocalModelFileDto? primaryFile;
  final List<EmmaLocalModelFileDto> files;
  final bool userHasAccess;
  final bool licenseAccepted;

  factory EmmaLocalModelDto.fromJson(Map<String, dynamic> json) {
    return EmmaLocalModelDto(
      id: _intOrNull(json['id']),
      uuid: _string(json['uuid']),
      modelId: _string(json['model_id']),
      name: _string(json['name']),
      shortDescription: _string(json['short_description']),
      description: _string(json['description']),
      taskType: _string(json['task_type']),
      runtime: _string(json['runtime']),
      modelFormat: _string(json['model_format']),
      family: _string(json['family']),
      version: _string(json['version']),
      quantization: _string(json['quantization']),
      parametersBillions: _doubleOrNull(json['parameters_billions']),
      contextLength: _intOrNull(json['context_length']),
      sourceType: _string(json['source_type']),
      distributionPolicy: _string(json['distribution_policy']),
      hfRepoId: _string(json['hf_repo_id']),
      hfRevision: _string(json['hf_revision']),
      hfAccessMode: _string(json['hf_access_mode']),
      licenseName: _string(json['license_name']),
      licenseUrl: _string(json['license_url']),
      licenseText: _string(json['license_text']),
      requiresLicenseAcceptance: _bool(json['requires_license_acceptance']),
      minRamGb: _doubleOrNull(json['min_ram_gb']),
      recommendedRamGb: _doubleOrNull(json['recommended_ram_gb']),
      minVramGb: _doubleOrNull(json['min_vram_gb']),
      recommendedVramGb: _doubleOrNull(json['recommended_vram_gb']),
      supportsCpu: _bool(json['supports_cpu']),
      supportsGpu: _bool(json['supports_gpu']),
      supportsMacos: _bool(json['supports_macos']),
      supportsWindows: _bool(json['supports_windows']),
      supportsLinux: _bool(json['supports_linux']),
      languages: _stringList(json['languages']),
      tags: _stringList(json['tags']),
      capabilities: _stringList(json['capabilities']),
      accessMode: _string(json['access_mode']),
      status: _string(json['status']),
      isActive: _bool(json['is_active']),
      isFeatured: _bool(json['is_featured']),
      sortOrder: _int(json['sort_order'], fallback: 1000),
      deprecationMessage: _string(json['deprecation_message']),
      releaseNotes: _string(json['release_notes']),
      metadata: _map(json['metadata']),
      primaryFile: json['primary_file'] is Map
          ? EmmaLocalModelFileDto.fromJson(
              Map<String, dynamic>.from(json['primary_file'] as Map),
            )
          : null,
      files: _mapList(json['files'])
          .map(EmmaLocalModelFileDto.fromJson)
          .toList(),
      userHasAccess: _bool(json['user_has_access']),
      licenseAccepted: _bool(json['license_accepted']),
    );
  }

  bool get canDownload {
    if (!userHasAccess) return false;
    if (requiresLicenseAcceptance && !licenseAccepted) return false;
    return true;
  }

  String get displayRequirements {
    final parts = <String>[];

    if (recommendedRamGb != null) {
      parts.add('RAM ${_formatNumber(recommendedRamGb!)} GB');
    } else if (minRamGb != null) {
      parts.add('min. RAM ${_formatNumber(minRamGb!)} GB');
    }

    if (recommendedVramGb != null && recommendedVramGb! > 0) {
      parts.add('VRAM ${_formatNumber(recommendedVramGb!)} GB');
    } else if (minVramGb != null && minVramGb! > 0) {
      parts.add('min. VRAM ${_formatNumber(minVramGb!)} GB');
    }

    if (parts.isEmpty) return 'Brak wymagań';
    return parts.join(' · ');
  }
}

class EmmaLocalDownloadInfo {
  const EmmaLocalDownloadInfo({
    required this.type,
    required this.url,
    required this.repoId,
    required this.filename,
    required this.revision,
    required this.requiresUserToken,
    required this.hfAccessMode,
    required this.sha256,
    required this.sizeBytes,
    required this.contentType,
    required this.fileName,
  });

  final String type;
  final String url;
  final String repoId;
  final String filename;
  final String revision;
  final bool requiresUserToken;
  final String hfAccessMode;
  final String sha256;
  final int? sizeBytes;
  final String contentType;
  final String fileName;

  factory EmmaLocalDownloadInfo.fromJson(Map<String, dynamic> json) {
    return EmmaLocalDownloadInfo(
      type: _string(json['type']),
      url: _string(json['url']),
      repoId: _string(json['repo_id']),
      filename: _string(json['filename']),
      revision: _string(json['revision']),
      requiresUserToken: _bool(json['requires_user_token']),
      hfAccessMode: _string(json['hf_access_mode']),
      sha256: _string(json['sha256']),
      sizeBytes: _intOrNull(json['size_bytes']),
      contentType: _string(json['content_type']),
      fileName: _string(json['file_name']),
    );
  }
}

class EmmaLocalResolveDownloadResponse {
  const EmmaLocalResolveDownloadResponse({
    required this.model,
    required this.file,
    required this.download,
  });

  final EmmaLocalModelDto model;
  final EmmaLocalModelFileDto file;
  final EmmaLocalDownloadInfo download;

  factory EmmaLocalResolveDownloadResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmmaLocalResolveDownloadResponse(
      model: EmmaLocalModelDto.fromJson(
        Map<String, dynamic>.from(json['model'] as Map),
      ),
      file: EmmaLocalModelFileDto.fromJson(
        Map<String, dynamic>.from(json['file'] as Map),
      ),
      download: EmmaLocalDownloadInfo.fromJson(
        Map<String, dynamic>.from(json['download'] as Map),
      ),
    );
  }
}

String formatEmmaLocalBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'Nieznany rozmiar';

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fixed = value >= 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(2);
  return '$fixed ${units[unitIndex]}';
}

String _string(dynamic value) => value?.toString() ?? '';

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return ['1', 'true', 'yes', 'tak'].contains(value.toLowerCase().trim());
  }
  return false;
}

int _int(dynamic value, {required int fallback}) {
  return _intOrNull(value) ?? fallback;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return <String>[];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}





