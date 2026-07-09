import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';

class CloudShortcutPayload {
  final String? shortcutId;
  final String itemType;
  final Object itemId;
  final Object? parentId;
  final String name;
  final String? subtitle;
  final String? extension;
  final String? mimeType;
  final String? fileType;
  final int? sizeBytes;
  final String? thumbnailUrl;
  final String cloudRoute;

  const CloudShortcutPayload({
    this.shortcutId,
    required this.itemType,
    required this.itemId,
    required this.name,
    this.parentId,
    this.subtitle,
    this.extension,
    this.mimeType,
    this.fileType,
    this.sizeBytes,
    this.thumbnailUrl,
    this.cloudRoute = '/cloud',
  });

  factory CloudShortcutPayload.fromBackendWidget(
    Map<String, dynamic> dashboardWidget,
  ) {
    final settingsRaw = dashboardWidget['settings'];
    final settings = settingsRaw is Map
        ? Map<String, dynamic>.from(settingsRaw)
        : <String, dynamic>{};

    return CloudShortcutPayload(
      shortcutId: settings['shortcutId']?.toString(),
      itemType: (settings['itemType'] ?? 'file').toString(),
      itemId: settings['itemId'] ?? '',
      parentId: settings['parentId'],
      name: (settings['name'] ??
              dashboardWidget['titleOverride'] ??
              'Cloud shortcut')
          .toString(),
      subtitle: settings['subtitle']?.toString(),
      extension: settings['extension']?.toString(),
      mimeType: settings['mimeType']?.toString(),
      fileType: settings['fileType']?.toString(),
      sizeBytes: settings['sizeBytes'] is num
          ? (settings['sizeBytes'] as num).toInt()
          : int.tryParse('${settings['sizeBytes'] ?? ''}'),
      thumbnailUrl: settings['thumbnailUrl']?.toString(),
      cloudRoute: (settings['cloudRoute'] ?? '/cloud').toString(),
    );
  }

  Map<String, dynamic> toSettings() {
    return {
      'shortcutId': shortcutId,
      'itemType': itemType,
      'itemId': itemId,
      'parentId': parentId,
      'name': name,
      'subtitle': subtitle,
      'extension': extension,
      'mimeType': mimeType,
      'fileType': fileType,
      'sizeBytes': sizeBytes,
      'thumbnailUrl': thumbnailUrl,
      'cloudRoute': cloudRoute,
    };
  }

  DashboardWidgetInstance toDashboardInstance() {
    final idBase = shortcutId != null && shortcutId!.trim().isNotEmpty
        ? 'cloud_shortcut_$shortcutId'
        : 'cloud_shortcut_${itemType}_${itemId}_$safeName';

    return DashboardWidgetInstance(
      id: idBase,
      type: 'cloud_shortcut',
      titleOverride: name,
      settings: toSettings(),
      zoneKey: 'main',
      catalogSlug: 'cloud-shortcut',
      sourceKey: 'native',
    );
  }

  String get safeName {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized.isEmpty ? 'shortcut' : normalized;
  }
}