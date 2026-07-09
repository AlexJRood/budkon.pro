import 'package:flutter/foundation.dart';

enum DashboardBreakpoint {
  desktop,
  tablet,
  mobile,
}

extension DashboardBreakpointX on DashboardBreakpoint {
  String get key {
    switch (this) {
      case DashboardBreakpoint.desktop:
        return 'desktop';
      case DashboardBreakpoint.tablet:
        return 'tablet';
      case DashboardBreakpoint.mobile:
        return 'mobile';
    }
  }

  static DashboardBreakpoint fromKey(String? value) {
    switch (value) {
      case 'desktop':
        return DashboardBreakpoint.desktop;
      case 'tablet':
        return DashboardBreakpoint.tablet;
      case 'mobile':
        return DashboardBreakpoint.mobile;
      default:
        return DashboardBreakpoint.desktop;
    }
  }

  int get defaultColumns {
    switch (this) {
      case DashboardBreakpoint.desktop:
        return 12;
      case DashboardBreakpoint.tablet:
        return 8;
      case DashboardBreakpoint.mobile:
        return 4;
    }
  }

  double get defaultRowHeight {
    switch (this) {
      case DashboardBreakpoint.desktop:
        return 110;
      case DashboardBreakpoint.tablet:
        return 100;
      case DashboardBreakpoint.mobile:
        return 92;
    }
  }

  double get defaultGap {
    switch (this) {
      case DashboardBreakpoint.desktop:
        return 20;
      case DashboardBreakpoint.tablet:
        return 16;
      case DashboardBreakpoint.mobile:
        return 12;
    }
  }
}

@immutable
class DashboardGridSize {
  final int w;
  final int h;

  const DashboardGridSize({
    required this.w,
    required this.h,
  });

  Map<String, dynamic> toJson() => {
        'w': w,
        'h': h,
      };

  factory DashboardGridSize.fromJson(Map<String, dynamic> json) {
    return DashboardGridSize(
      w: (json['w'] as num?)?.toInt() ?? 1,
      h: (json['h'] as num?)?.toInt() ?? 1,
    );
  }
}

@immutable
class DashboardWidgetConstraints {
  final int minW;
  final int maxW;
  final int minH;
  final int maxH;

  const DashboardWidgetConstraints({
    required this.minW,
    required this.maxW,
    required this.minH,
    required this.maxH,
  });
}

@immutable
class DashboardWidgetInstance {
  final String id;
  final String type;
  final String? titleOverride;
  final bool isVisible;
  final Map<String, dynamic> settings;

  final String zoneKey;
  final String? catalogSlug;
  final String sourceKey;

  const DashboardWidgetInstance({
    required this.id,
    required this.type,
    this.titleOverride,
    this.isVisible = true,
    this.settings = const {},
    this.zoneKey = 'main',
    this.catalogSlug,
    this.sourceKey = 'native',
  });

  DashboardWidgetInstance copyWith({
    String? id,
    String? type,
    String? titleOverride,
    bool? isVisible,
    Map<String, dynamic>? settings,
    String? zoneKey,
    String? catalogSlug,
    String? sourceKey,
  }) {
    return DashboardWidgetInstance(
      id: id ?? this.id,
      type: type ?? this.type,
      titleOverride: titleOverride ?? this.titleOverride,
      isVisible: isVisible ?? this.isVisible,
      settings: settings ?? this.settings,
      zoneKey: zoneKey ?? this.zoneKey,
      catalogSlug: catalogSlug ?? this.catalogSlug,
      sourceKey: sourceKey ?? this.sourceKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'titleOverride': titleOverride,
        'isVisible': isVisible,
        'settings': settings,
        'zoneKey': zoneKey,
        'catalogSlug': catalogSlug,
        'sourceKey': sourceKey,
      };

  factory DashboardWidgetInstance.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetInstance(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      titleOverride: json['titleOverride']?.toString(),
      isVisible: json['isVisible'] as bool? ?? true,
      settings: json['settings'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['settings'] as Map<String, dynamic>)
          : <String, dynamic>{},
      zoneKey: (json['zoneKey'] ?? 'main').toString(),
      catalogSlug: json['catalogSlug']?.toString(),
      sourceKey: (json['sourceKey'] ?? 'native').toString(),
    );
  }
}

@immutable
class DashboardLayoutItem {
  final String instanceId;
  final int x;
  final int y;
  final int w;
  final int h;
  final int z;

  const DashboardLayoutItem({
    required this.instanceId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.z = 0,
  });

  DashboardLayoutItem copyWith({
    String? instanceId,
    int? x,
    int? y,
    int? w,
    int? h,
    int? z,
  }) {
    return DashboardLayoutItem(
      instanceId: instanceId ?? this.instanceId,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      z: z ?? this.z,
    );
  }

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'z': z,
      };

  factory DashboardLayoutItem.fromJson(Map<String, dynamic> json) {
    return DashboardLayoutItem(
      instanceId: (json['instanceId'] ?? '').toString(),
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      w: (json['w'] as num?)?.toInt() ?? 1,
      h: (json['h'] as num?)?.toInt() ?? 1,
      z: (json['z'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class DashboardBreakpointLayout {
  final DashboardBreakpoint breakpoint;
  final int columns;
  final double rowHeight;
  final double gap;
  final double canvasPadding;
  final double horizontalPadding;
  final List<DashboardLayoutItem> items;

  const DashboardBreakpointLayout({
    required this.breakpoint,
    required this.columns,
    required this.rowHeight,
    required this.gap,
    required this.canvasPadding,
    required this.horizontalPadding,
    required this.items,
  });

  factory DashboardBreakpointLayout.empty(DashboardBreakpoint breakpoint) {
    return DashboardBreakpointLayout(
      breakpoint: breakpoint,
      columns: breakpoint.defaultColumns,
      rowHeight: breakpoint.defaultRowHeight,
      gap: breakpoint.defaultGap,
      canvasPadding: 10,
      horizontalPadding: 16,
      items: const [],
    );
  }

  DashboardBreakpointLayout copyWith({
    DashboardBreakpoint? breakpoint,
    int? columns,
    double? rowHeight,
    double? gap,
    double? canvasPadding,
    double? horizontalPadding,
    List<DashboardLayoutItem>? items,
  }) {
    return DashboardBreakpointLayout(
      breakpoint: breakpoint ?? this.breakpoint,
      columns: columns ?? this.columns,
      rowHeight: rowHeight ?? this.rowHeight,
      gap: gap ?? this.gap,
      canvasPadding: canvasPadding ?? this.canvasPadding,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columns': columns,
      'rowHeight': rowHeight,
      'gap': gap,
      'canvasPadding': canvasPadding,
      'horizontalPadding': horizontalPadding,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory DashboardBreakpointLayout.fromJson({
    required DashboardBreakpoint breakpoint,
    required Map<String, dynamic> json,
  }) {
    final rawItems = (json['items'] as List?) ?? const [];

    return DashboardBreakpointLayout(
      breakpoint: breakpoint,
      columns: (json['columns'] as num?)?.toInt() ?? breakpoint.defaultColumns,
      rowHeight:
          (json['rowHeight'] as num?)?.toDouble() ?? breakpoint.defaultRowHeight,
      gap: (json['gap'] as num?)?.toDouble() ?? breakpoint.defaultGap,
      canvasPadding: (json['canvasPadding'] as num?)?.toDouble() ?? 10,
      horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 16,
      items: rawItems
          .whereType<Map>()
          .map((e) => DashboardLayoutItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(growable: false),
    );
  }
}

@immutable
class DashboardConfig {
  final String dashboardKey;
  final int revision;
  final String? updatedAt;
  final Map<DashboardBreakpoint, DashboardBreakpointLayout> layouts;
  final List<DashboardWidgetInstance> instances;

  const DashboardConfig({
    required this.dashboardKey,
    required this.revision,
    required this.updatedAt,
    required this.layouts,
    required this.instances,
  });

  DashboardConfig copyWith({
    String? dashboardKey,
    int? revision,
    String? updatedAt,
    Map<DashboardBreakpoint, DashboardBreakpointLayout>? layouts,
    List<DashboardWidgetInstance>? instances,
  }) {
    return DashboardConfig(
      dashboardKey: dashboardKey ?? this.dashboardKey,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      layouts: layouts ?? this.layouts,
      instances: instances ?? this.instances,
    );
  }

  DashboardBreakpointLayout layoutOf(DashboardBreakpoint breakpoint) {
    return layouts[breakpoint] ?? DashboardBreakpointLayout.empty(breakpoint);
  }

  DashboardConfig upsertLayout(DashboardBreakpointLayout layout) {
    return copyWith(
      layouts: {
        ...layouts,
        layout.breakpoint: layout,
      },
    );
  }

  DashboardWidgetInstance? findInstance(String instanceId) {
    for (final item in instances) {
      if (item.id == instanceId) return item;
    }
    return null;
  }

  DashboardConfig removeInstance(String instanceId) {
    final nextInstances =
        instances.where((e) => e.id != instanceId).toList(growable: false);

    final nextLayouts = <DashboardBreakpoint, DashboardBreakpointLayout>{};
    for (final entry in layouts.entries) {
      nextLayouts[entry.key] = entry.value.copyWith(
        items: entry.value.items
            .where((item) => item.instanceId != instanceId)
            .toList(growable: false),
      );
    }

    return copyWith(
      instances: nextInstances,
      layouts: nextLayouts,
    );
  }

  bool get hasRenderableContent {
    if (instances.isEmpty) return false;
    if (layouts.isEmpty) return false;

    final instanceIds = instances.map((e) => e.id).toSet();

    for (final layout in layouts.values) {
      for (final item in layout.items) {
        if (instanceIds.contains(item.instanceId)) {
          return true;
        }
      }
    }

    return false;
  }

  bool get hasContent => hasRenderableContent;

  Map<String, dynamic> toJson() => {
        'dashboard_key': dashboardKey,
        'revision': revision,
        'updated_at': updatedAt,
        'layouts': {
          for (final entry in layouts.entries) entry.key.key: entry.value.toJson(),
        },
        'instances': instances.map((e) => e.toJson()).toList(),
      };

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final layoutsRaw = json['layouts'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['layouts'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final instancesRaw = (json['instances'] as List?) ?? const [];

    return DashboardConfig(
      dashboardKey: (json['dashboard_key'] ?? 'crm_main').toString(),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      updatedAt: json['updated_at']?.toString(),
      layouts: {
        for (final entry in layoutsRaw.entries)
          DashboardBreakpointX.fromKey(entry.key): DashboardBreakpointLayout.fromJson(
            breakpoint: DashboardBreakpointX.fromKey(entry.key),
            json: entry.value is Map<String, dynamic>
                ? Map<String, dynamic>.from(entry.value as Map<String, dynamic>)
                : <String, dynamic>{},
          ),
      },
      instances: instancesRaw
          .whereType<Map>()
          .map((e) =>
              DashboardWidgetInstance.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}