class CloudShortcutOpenTarget {
  final String resourceType;
  final String? parent;
  final bool showAllFiles;
  final String? search;
  final String? fileId;

  const CloudShortcutOpenTarget({
    required this.resourceType,
    required this.parent,
    required this.showAllFiles,
    required this.search,
    required this.fileId,
  });

  factory CloudShortcutOpenTarget.fromJson(Map<String, dynamic> json) {
    return CloudShortcutOpenTarget(
      resourceType: (json['resource_type'] ?? '').toString(),
      parent: _nullableString(json['parent']),
      showAllFiles: json['show_all_files'] == true,
      search: _nullableString(json['search']),
      fileId: _nullableString(json['file_id']),
    );
  }
}

class CloudShortcut {
  final String id;
  final String resourceType;
  final String? itemId;
  final String itemType;
  final String resourceName;
  final String? parentId;
  final String? fileType;
  final String? mimeType;
  final String? extension;
  final int? sizeBytes;
  final String? thumbnailUrl;
  final String? url;
  final String dashboardKey;
  final String zoneKey;
  final String label;
  final String subtitle;
  final String icon;
  final String color;
  final bool isAvailable;
  final CloudShortcutOpenTarget? openTarget;
  final Map<String, dynamic> widgetSettings;
  final Map<String, dynamic> dashboardWidget;

  const CloudShortcut({
    required this.id,
    required this.resourceType,
    required this.itemId,
    required this.itemType,
    required this.resourceName,
    required this.parentId,
    required this.fileType,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.thumbnailUrl,
    required this.url,
    required this.dashboardKey,
    required this.zoneKey,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isAvailable,
    required this.openTarget,
    required this.widgetSettings,
    required this.dashboardWidget,
  });

  factory CloudShortcut.fromJson(Map<String, dynamic> json) {
    final openTargetRaw = json['open_target'];
    final widgetSettingsRaw = json['widget_settings'];
    final dashboardWidgetRaw = json['dashboard_widget'];

    return CloudShortcut(
      id: (json['id'] ?? '').toString(),
      resourceType: (json['resource_type'] ?? '').toString(),
      itemId: _nullableString(json['item_id']),
      itemType: (json['item_type'] ?? json['resource_type'] ?? '').toString(),
      resourceName: (json['resource_name'] ?? '').toString(),
      parentId: _nullableString(json['parent_id']),
      fileType: _nullableString(json['file_type']),
      mimeType: _nullableString(json['mime_type']),
      extension: _nullableString(json['extension']),
      sizeBytes: _nullableInt(json['size_bytes']),
      thumbnailUrl: _nullableString(json['thumbnail_url']),
      url: _nullableString(json['url']),
      dashboardKey: (json['dashboard_key'] ?? 'crm_main').toString(),
      zoneKey: (json['zone_key'] ?? 'main').toString(),
      label: (json['label'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      isAvailable: json['is_available'] == true,
      openTarget: openTargetRaw is Map
          ? CloudShortcutOpenTarget.fromJson(
              Map<String, dynamic>.from(openTargetRaw),
            )
          : null,
      widgetSettings: widgetSettingsRaw is Map
          ? Map<String, dynamic>.from(widgetSettingsRaw)
          : <String, dynamic>{},
      dashboardWidget: dashboardWidgetRaw is Map
          ? Map<String, dynamic>.from(dashboardWidgetRaw)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toDashboardSettingsFallback() {
    return {
      'shortcutId': id,
      'itemType': itemType.isNotEmpty ? itemType : resourceType,
      'itemId': itemId,
      'parentId': parentId,
      'name': resourceName,
      'subtitle': subtitle,
      'extension': extension,
      'mimeType': mimeType,
      'fileType': fileType,
      'sizeBytes': sizeBytes,
      'thumbnailUrl': thumbnailUrl,
      'cloudRoute': '/cloud',
    };
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty || text == 'null' || text == 'None') {
    return null;
  }

  return text;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class PinCloudShortcutRequest {
  final String resourceType;
  final String resourceId;

  /// cloud_quick_access albo dashboard
  final String destination;

  /// cloud_quick_access albo np. crm_main / client_panel_dashboard
  final String? dashboardKey;

  final String zoneKey;
  final String? label;
  final String? subtitle;

  const PinCloudShortcutRequest({
    required this.resourceType,
    required this.resourceId,
    this.destination = 'cloud_quick_access',
    this.dashboardKey,
    this.zoneKey = 'main',
    this.label,
    this.subtitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'resource_type': resourceType,
      'resource_id': resourceId,
      'destination': destination,
      if (dashboardKey != null && dashboardKey!.trim().isNotEmpty)
        'dashboard_key': dashboardKey,
      'zone_key': zoneKey,
      if (label != null && label!.trim().isNotEmpty) 'label': label,
      if (subtitle != null && subtitle!.trim().isNotEmpty)
        'subtitle': subtitle,
    };
  }
}