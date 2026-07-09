import 'package:flutter/foundation.dart';

@immutable
class WidgetPreviewImage {
  const WidgetPreviewImage({
    required this.url,
    this.label,
    this.gridW,
    this.gridH,
  });

  final String url;
  final String? label;
  final int? gridW;
  final int? gridH;

  factory WidgetPreviewImage.fromJson(Map<String, dynamic> json) =>
      WidgetPreviewImage(
        url: json['url']?.toString() ?? '',
        label: json['label']?.toString(),
        gridW: json['grid_w'] is int ? json['grid_w'] as int : null,
        gridH: json['grid_h'] is int ? json['grid_h'] as int : null,
      );
}

enum DashboardWidgetSource {
  native,
  market;

  static DashboardWidgetSource fromKey(String? value) {
    switch (value) {
      case 'market':
        return DashboardWidgetSource.market;
      case 'native':
      default:
        return DashboardWidgetSource.native;
    }
  }

  String get key {
    switch (this) {
      case DashboardWidgetSource.native:
        return 'native';
      case DashboardWidgetSource.market:
        return 'market';
    }
  }
}

@immutable
class DashboardCatalogItem {
  final String slug;
  final String componentKey;
  final String title;
  final String description;
  final String iconKey;
  final String category;
  final DashboardWidgetSource source;

  final Set<String> dashboardKeys;
  final Set<String> allowedZones;
  final Set<String> allowedRoles;
  final Set<String> requiredPermissions;

  final bool allowMultiple;
  final bool requiresInstallation;
  final bool isPublic;
  final bool isPremium;

  final Map<String, dynamic> defaultSettings;
  final Map<String, dynamic> defaultSizes;
  final Map<String, dynamic> constraints;

  final String? previewImageUrl;
  final Map<String, WidgetPreviewImage> previewImages;

  final bool isInstalled;
  final bool canInstall;
  final bool canAdd;
  final String? disabledReason;

  const DashboardCatalogItem({
    required this.slug,
    required this.componentKey,
    required this.title,
    required this.description,
    this.previewImageUrl,
    this.previewImages = const <String, WidgetPreviewImage>{},
    required this.iconKey,
    required this.category,
    required this.source,
    required this.dashboardKeys,
    required this.allowedZones,
    required this.allowedRoles,
    required this.requiredPermissions,
    required this.allowMultiple,
    required this.requiresInstallation,
    required this.isPublic,
    required this.isPremium,
    required this.defaultSettings,
    required this.defaultSizes,
    required this.constraints,
    required this.isInstalled,
    required this.canInstall,
    required this.canAdd,
    required this.disabledReason,
  });

  factory DashboardCatalogItem.fromJson(Map<String, dynamic> json) {
    Set<String> _toSet(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toSet();
      }
      return <String>{};
    }

    Map<String, dynamic> _toMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{};
    }

    return DashboardCatalogItem(
      slug: (json['slug'] ?? '').toString(),
      componentKey: (json['component_key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconKey: (json['icon'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      source: DashboardWidgetSource.fromKey(json['source']?.toString()),
      dashboardKeys: _toSet(json['dashboard_keys']),
      allowedZones: _toSet(json['allowed_zones']),
      allowedRoles: _toSet(json['allowed_roles']),
      requiredPermissions: _toSet(json['required_permissions']),
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      requiresInstallation: json['requires_installation'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
      defaultSettings: _toMap(json['default_settings']),
      defaultSizes: _toMap(json['default_sizes']),
      constraints: _toMap(json['constraints']),
      previewImageUrl: json['preview_image_url']?.toString().isEmpty == false
          ? json['preview_image_url'].toString()
          : null,
      previewImages: () {
        final raw = json['preview_images'];
        if (raw is Map) {
          final result = <String, WidgetPreviewImage>{};
          for (final entry in raw.entries) {
            final key = entry.key.toString();
            final val = entry.value;
            if (val is Map) {
              final url = val['url']?.toString() ?? '';
              if (url.isNotEmpty) {
                result[key] = WidgetPreviewImage.fromJson(
                    Map<String, dynamic>.from(val));
              }
            } else if (val is String && val.isNotEmpty) {
              // Backward compat: old flat {variant: url} format
              result[key] = WidgetPreviewImage(url: val, label: key);
            }
          }
          return result;
        }
        return const <String, WidgetPreviewImage>{};
      }(),
      isInstalled: json['is_installed'] as bool? ?? false,
      canInstall: json['can_install'] as bool? ?? false,
      canAdd: json['can_add'] as bool? ?? false,
      disabledReason: json['disabled_reason']?.toString(),
    );
  }
}

@immutable
class DashboardCatalogQuery {
  final String dashboardKey;
  final String zoneKey;
  final String? source;
  final String? category;
  final String? search;
  final bool installedOnly;

  const DashboardCatalogQuery({
    required this.dashboardKey,
    required this.zoneKey,
    this.source,
    this.category,
    this.search,
    this.installedOnly = false,
  });

  @override
  bool operator ==(Object other) {
    return other is DashboardCatalogQuery &&
        other.dashboardKey == dashboardKey &&
        other.zoneKey == zoneKey &&
        other.source == source &&
        other.category == category &&
        other.search == search &&
        other.installedOnly == installedOnly;
  }

  @override
  int get hashCode => Object.hash(
        dashboardKey,
        zoneKey,
        source,
        category,
        search,
        installedOnly,
      );
}