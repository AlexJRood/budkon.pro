import 'dart:async';
import 'dart:math';

import 'package:crm/dynamic_dashboard/defaults/dashboard_default_config.dart';
import 'package:crm/dynamic_dashboard/models/catalog_models.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_registry.dart';
import 'package:crm/dynamic_dashboard/services/dashboard_layout_api.dart';
import 'package:crm/dynamic_dashboard/services/dashboard_layout_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardLayoutState {
  final bool isLoading;
  final bool isSaving;
  final bool isEditMode;
  final bool isDirty;
  final DashboardConfig? config;
  final DashboardConfig? lastSyncedConfig;
  final String? error;

  const DashboardLayoutState({
    required this.isLoading,
    required this.isSaving,
    required this.isEditMode,
    required this.isDirty,
    required this.config,
    required this.lastSyncedConfig,
    required this.error,
  });

  factory DashboardLayoutState.initial() {
    return const DashboardLayoutState(
      isLoading: false,
      isSaving: false,
      isEditMode: false,
      isDirty: false,
      config: null,
      lastSyncedConfig: null,
      error: null,
    );
  }

  DashboardLayoutState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isEditMode,
    bool? isDirty,
    DashboardConfig? config,
    DashboardConfig? lastSyncedConfig,
    String? error,
  }) {
    return DashboardLayoutState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditMode: isEditMode ?? this.isEditMode,
      isDirty: isDirty ?? this.isDirty,
      config: config ?? this.config,
      lastSyncedConfig: lastSyncedConfig ?? this.lastSyncedConfig,
      error: error,
    );
  }
}

final dashboardLayoutProvider = StateNotifierProvider.family<
    DashboardLayoutNotifier, DashboardLayoutState, String>((ref, dashboardKey) {
  return DashboardLayoutNotifier(
    ref: ref,
    dashboardKey: dashboardKey,
  );
});

class DashboardLayoutNotifier extends StateNotifier<DashboardLayoutState> {
  DashboardLayoutNotifier({
    required this.ref,
    required this.dashboardKey,
  }) : super(DashboardLayoutState.initial());

  final Ref ref;
  final String dashboardKey;

  Timer? _saveTimer;
  bool _disposed = false;

  DashboardWidgetRegistry get _registry =>
      ref.read(dashboardWidgetRegistryProvider);

  DashboardLayoutApi get _api => ref.read(dashboardLayoutApiProvider);

  DashboardLayoutLocalStorage get _local =>
      ref.read(dashboardLayoutLocalStorageProvider);

  void _safeSetState(DashboardLayoutState next) {
    if (_disposed) return;
    state = next;
  }

  int _clampInt(int value, int minValue, int maxValue) {
    if (maxValue < minValue) return minValue;
    return value.clamp(minValue, maxValue).toInt();
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (_disposed) return;

    final initialState = state;
    if (initialState.isLoading) return;
    if (initialState.config != null && !forceRefresh) return;

    _safeSetState(initialState.copyWith(isLoading: true, error: null));

    try {
      if (!forceRefresh) {
        final localConfig = await _local.readConfig(dashboardKey);
        if (_disposed) return;

        if (localConfig != null) {
          // Show cached layout immediately — no network wait.
          final (:config, :healed) = _normalizeAllTracked(localConfig);
          _safeSetState(state.copyWith(
            isLoading: false,
            config: config,
            lastSyncedConfig: config,
            isDirty: healed,
            error: null,
          ));
          if (healed) {
            // Recovered instances gained layout positions — persist immediately.
            scheduleSave();
          }
          // Check for remote updates silently in the background.
          unawaited(_syncWithRemote(localRevision: localConfig.revision));
          return;
        }
      }

      // No local cache (or forceRefresh): wait for remote.
      final remote = await _api.fetchLayout(dashboardKey);
      if (_disposed) return;

      final (:config, :healed) = remote != null
          ? _normalizeAllTracked(remote)
          : (config: null, healed: false);

      final effectiveConfig = (config != null && config.hasRenderableContent)
          ? config
          : _normalizeAll(buildDefaultDashboardConfig(
              dashboardKey: dashboardKey,
              registry: _registry,
            ));

      _safeSetState(state.copyWith(
        isLoading: false,
        config: effectiveConfig,
        lastSyncedConfig: effectiveConfig,
        isDirty: healed,
        error: null,
      ));

      unawaited(_local.writeConfig(dashboardKey, effectiveConfig));
      unawaited(_local.writeLastCheck(dashboardKey, DateTime.now().toUtc()));
      if (healed) scheduleSave();
    } catch (e) {
      if (_disposed) return;

      final currentState = state;

      if (currentState.config == null) {
        final fallback = _normalizeAll(buildDefaultDashboardConfig(
          dashboardKey: dashboardKey,
          registry: _registry,
        ));
        _safeSetState(currentState.copyWith(
          isLoading: false,
          config: fallback,
          lastSyncedConfig: fallback,
          isDirty: false,
          error: e.toString(),
        ));
        unawaited(_local.writeConfig(dashboardKey, fallback));
      } else {
        _safeSetState(currentState.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  /// Checks the remote for changes and silently updates the config if needed.
  /// Never blocks the UI — called only after local cache has already been shown.
  Future<void> _syncWithRemote({required int? localRevision}) async {
    if (_disposed) return;
    try {
      final lastCheck = await _local.readLastCheck(dashboardKey);
      if (_disposed) return;

      final check = await _api.checkRemoteChanges(
        dashboardKey: dashboardKey,
        lastCheckIso: lastCheck?.toUtc().toIso8601String(),
        localRevision: localRevision,
      );
      if (_disposed) return;

      await _local.writeLastCheck(dashboardKey, DateTime.now().toUtc());
      if (_disposed) return;

      if (!check.hasChanges) return;

      final remote = await _api.fetchLayout(dashboardKey);
      if (_disposed) return;

      if (remote == null) return;

      final normalized = _normalizeAll(remote);
      if (!normalized.hasRenderableContent) return;

      _safeSetState(state.copyWith(
        config: normalized,
        lastSyncedConfig: normalized,
        isDirty: false,
        error: null,
      ));
      unawaited(_local.writeConfig(dashboardKey, normalized));
    } catch (_) {
      // Silent — current config stays displayed.
    }
  }


  void updateWidgetSettings({
    required String instanceId,
    required Map<String, dynamic> settings,
    bool merge = true,
  }) {
    final currentConfig = state.config;
    if (currentConfig == null) return;

    final nextInstances = currentConfig.instances.map((instance) {
      if (instance.id != instanceId) return instance;

      final nextSettings = merge
          ? <String, dynamic>{
              ...instance.settings,
              ...settings,
            }
          : settings;

      return instance.copyWith(
        settings: nextSettings,
      );
    }).toList(growable: false);

    final nextConfig = currentConfig.copyWith(
      instances: nextInstances,
    );

    state = state.copyWith(
      config: nextConfig,
      isDirty: true,
    );

    scheduleSave();
  }



  String addCatalogWidget(
    DashboardCatalogItem catalogItem, {
    String zoneKey = 'main',
  }) {
    if (_disposed) return '';

    final config = state.config;
    if (config == null) return '';

    final spec = _registry.byType(catalogItem.componentKey);
    if (spec == null) return '';

    final existingTypes = config.instances.map((e) => e.type).toSet();

    if (!catalogItem.allowMultiple &&
        existingTypes.contains(catalogItem.componentKey)) {
      return '';
    }

    if (!catalogItem.canAdd) return '';

    final instanceId = _nextId(catalogItem.componentKey);

    final instance = DashboardWidgetInstance(
      id: instanceId,
      type: catalogItem.componentKey,
      settings: Map<String, dynamic>.from(catalogItem.defaultSettings),
      isVisible: true,
      zoneKey: zoneKey,
      catalogSlug: catalogItem.slug,
      sourceKey: catalogItem.source.key,
    );

    var nextConfig = config.copyWith(
      instances: [
        ...config.instances,
        instance,
      ],
    );

    for (final breakpoint in DashboardBreakpoint.values) {
      final layout = nextConfig.layoutOf(breakpoint);
      final size = spec.defaultSize(breakpoint);
      final position = _findFirstAvailablePosition(
        layout: layout,
        width: size.w,
        height: size.h,
      );

      final nextLayout = _resolveLayout(
        config: nextConfig,
        layout: layout.copyWith(
          items: [
            ...layout.items,
            DashboardLayoutItem(
              instanceId: instanceId,
              x: position.$1,
              y: position.$2,
              w: size.w,
              h: size.h,
            ),
          ],
        ),
        priorityInstanceId: instanceId,
      );

      nextConfig = nextConfig.upsertLayout(nextLayout);
    }

    _setDirty(nextConfig);
    scheduleSave();
    return instanceId;
  }

  void updateGridSettings({
    required DashboardBreakpoint breakpoint,
    int? columns,
    double? rowHeight,
    double? gap,
    double? canvasPadding,
    double? horizontalPadding,
  }) {
    if (_disposed) return;

    final config = state.config;
    if (config == null) return;

    final current = config.layoutOf(breakpoint);

    final nextColumns = columns == null ? current.columns : max(1, columns);
    final nextRowHeight =
        rowHeight == null ? current.rowHeight : max(20, rowHeight);
    final nextGap = gap == null ? current.gap : max(0, gap);
    final nextCanvasPadding =
        canvasPadding == null ? current.canvasPadding : max(0, canvasPadding);
    final nextHorizontalPadding =
        horizontalPadding == null ? current.horizontalPadding : max(0, horizontalPadding);

    final updated = current.copyWith(
      columns: nextColumns,
      rowHeight: nextRowHeight.toDouble(),
      gap: nextGap.toDouble(),
      canvasPadding: nextCanvasPadding.toDouble(),
      horizontalPadding: nextHorizontalPadding.toDouble(),
    );

    final normalized = _resolveLayout(
      config: config,
      layout: updated,
    );

    _setDirty(config.upsertLayout(normalized));
    scheduleSave();
  }

  void toggleEditMode() {
    if (_disposed) return;

    final next = !state.isEditMode;
    _safeSetState(state.copyWith(isEditMode: next, error: null));

    if (!next) {
      scheduleSave();
    }
  }

  void setEditMode(bool value) {
    if (_disposed) return;

    _safeSetState(state.copyWith(isEditMode: value, error: null));

    if (!value) {
      scheduleSave();
    }
  }

  void moveItem({
    required DashboardBreakpoint breakpoint,
    required String instanceId,
    required int x,
    required int y,
  }) {
    if (_disposed) return;

    final config = state.config;
    if (config == null) return;

    final layout = config.layoutOf(breakpoint);
    final nextItems = layout.items
        .map(
          (item) => item.instanceId == instanceId
              ? item.copyWith(x: x, y: y)
              : item,
        )
        .toList(growable: false);

    final nextLayout = _resolveLayout(
      config: config,
      layout: layout.copyWith(items: nextItems),
      priorityInstanceId: instanceId,
    );

    _setDirty(config.upsertLayout(nextLayout));
  }

  void resizeItem({
    required DashboardBreakpoint breakpoint,
    required String instanceId,
    required int x,
    required int y,
    required int w,
    required int h,
  }) {
    if (_disposed) return;

    final config = state.config;
    if (config == null) return;

    final layout = config.layoutOf(breakpoint);

    final nextItems = layout.items
        .map(
          (item) => item.instanceId == instanceId
              ? item.copyWith(x: x, y: y, w: w, h: h)
              : item,
        )
        .toList(growable: false);

    final nextLayout = _resolveLayout(
      config: config,
      layout: layout.copyWith(items: nextItems),
      priorityInstanceId: instanceId,
    );

    _setDirty(config.upsertLayout(nextLayout));
  }

  void addWidget(String type) {
    if (_disposed) return;

    final config = state.config;
    final spec = _registry.byType(type);
    if (config == null || spec == null) return;

    if (!spec.allowMultiple && config.instances.any((e) => e.type == type)) {
      return;
    }

    final instanceId = _nextId(type);
    final instance = DashboardWidgetInstance(
      id: instanceId,
      type: type,
      settings: const {},
      isVisible: true,
    );

    var nextConfig = config.copyWith(
      instances: [
        ...config.instances,
        instance,
      ],
    );

    for (final breakpoint in DashboardBreakpoint.values) {
      final layout = nextConfig.layoutOf(breakpoint);
      final size = spec.defaultSize(breakpoint);
      final position = _findFirstAvailablePosition(
        layout: layout,
        width: size.w,
        height: size.h,
      );

      final nextLayout = _resolveLayout(
        config: nextConfig,
        layout: layout.copyWith(
          items: [
            ...layout.items,
            DashboardLayoutItem(
              instanceId: instanceId,
              x: position.$1,
              y: position.$2,
              w: size.w,
              h: size.h,
            ),
          ],
        ),
        priorityInstanceId: instanceId,
      );

      nextConfig = nextConfig.upsertLayout(nextLayout);
    }

    _setDirty(nextConfig);
    scheduleSave();
  }

  void removeWidget(String instanceId) {
    if (_disposed) return;

    final config = state.config;
    if (config == null) return;

    final nextConfig = config.removeInstance(instanceId);
    _setDirty(_normalizeAll(nextConfig));
    scheduleSave();
  }

  void duplicateWidget({
    required DashboardBreakpoint breakpoint,
    required String instanceId,
  }) {
    if (_disposed) return;

    final config = state.config;
    if (config == null) return;

    final sourceInstance = config.findInstance(instanceId);
    if (sourceInstance == null) return;

    final spec = _registry.byType(sourceInstance.type);
    if (spec == null) return;

    final nextId = _nextId(sourceInstance.type);

    var nextConfig = config.copyWith(
      instances: [
        ...config.instances,
        sourceInstance.copyWith(
          id: nextId,
          settings: Map<String, dynamic>.from(sourceInstance.settings),
        ),
      ],
    );

    for (final bp in DashboardBreakpoint.values) {
      final layout = nextConfig.layoutOf(bp);
      final sourceItem =
          layout.items.firstWhereOrNull((e) => e.instanceId == instanceId);

      final size = sourceItem != null
          ? DashboardGridSize(w: sourceItem.w, h: sourceItem.h)
          : spec.defaultSize(bp);

      final position = _findFirstAvailablePosition(
        layout: layout,
        width: size.w,
        height: size.h,
      );

      final nextLayout = _resolveLayout(
        config: nextConfig,
        layout: layout.copyWith(
          items: [
            ...layout.items,
            DashboardLayoutItem(
              instanceId: nextId,
              x: position.$1,
              y: position.$2,
              w: size.w,
              h: size.h,
            ),
          ],
        ),
        priorityInstanceId: nextId,
      );

      nextConfig = nextConfig.upsertLayout(nextLayout);
    }

    _setDirty(nextConfig);
    scheduleSave();
  }

  Future<void> resetToDefault() async {
    if (_disposed) return;

    final defaultConfig = _normalizeAll(
      buildDefaultDashboardConfig(
        dashboardKey: dashboardKey,
        registry: _registry,
      ),
    );

    _safeSetState(
      state.copyWith(
        config: defaultConfig,
        isDirty: true,
        error: null,
      ),
    );

    await _local.clear(dashboardKey);
    if (_disposed) return;

    await saveNow();
  }

  void scheduleSave() {
    if (_disposed) return;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 650), () async {
      if (_disposed) return;
      await saveNow();
    });
  }

  Future<void> saveNow() async {
    if (_disposed) return;

    final currentState = state;
    final currentConfig = currentState.config;

    if (currentConfig == null || currentState.isSaving) return;

    _saveTimer?.cancel();

    _safeSetState(
      currentState.copyWith(
        isSaving: true,
        error: null,
      ),
    );

    try {
      unawaited(_local.writeConfig(dashboardKey, currentConfig));

      final saved = await _api.saveLayout(
        dashboardKey: dashboardKey,
        config: currentConfig,
      );
      if (_disposed) return;

      final normalizedSaved = _normalizeAll(saved);

      final effectiveConfig = normalizedSaved.hasRenderableContent ||
              !currentConfig.hasRenderableContent
          ? normalizedSaved
          : currentConfig;

      _safeSetState(
        state.copyWith(
          isSaving: false,
          config: effectiveConfig,
          lastSyncedConfig: effectiveConfig,
          isDirty: false,
          error: null,
        ),
      );

      await _local.writeConfig(dashboardKey, effectiveConfig);
      if (_disposed) return;

      await _local.writeLastCheck(dashboardKey, DateTime.now().toUtc());
    } catch (e) {
      if (_disposed) return;

      _safeSetState(
        state.copyWith(
          isSaving: false,
          error: e.toString(),
        ),
      );
    }
  }

  void _setDirty(DashboardConfig nextConfig) {
    if (_disposed) return;

    _safeSetState(
      state.copyWith(
        config: nextConfig,
        isDirty: true,
        error: null,
      ),
    );

    unawaited(_local.writeConfig(dashboardKey, nextConfig));
  }

  DashboardConfig _normalizeAll(DashboardConfig config) {
    var next = config;
    for (final bp in DashboardBreakpoint.values) {
      final resolved = _resolveLayout(
        config: next,
        layout: next.layoutOf(bp),
      );
      next = next.upsertLayout(resolved);
    }
    return next;
  }

  /// Like [_normalizeAll] but also returns true if any instances were
  /// recovered (had a valid spec but no layout position).
  ({DashboardConfig config, bool healed}) _normalizeAllTracked(
    DashboardConfig config,
  ) {
    int before = 0;
    int after = 0;
    for (final bp in DashboardBreakpoint.values) {
      before += config.layoutOf(bp).items.length;
    }
    final normalized = _normalizeAll(config);
    for (final bp in DashboardBreakpoint.values) {
      after += normalized.layoutOf(bp).items.length;
    }
    return (config: normalized, healed: after > before);
  }

  DashboardBreakpointLayout _resolveLayout({
    required DashboardConfig config,
    required DashboardBreakpointLayout layout,
    String? priorityInstanceId,
  }) {
    final allItems = [...layout.items];

    DashboardLayoutItem sanitize(DashboardLayoutItem item) {
      final instance = config.findInstance(item.instanceId);
      final spec = instance == null ? null : _registry.byType(instance.type);

      if (instance == null || spec == null || !instance.isVisible) {
        return item;
      }

      final c = spec.constraints;
      final maxW = min(c.maxW, layout.columns);

      int x = item.x;
      int y = item.y;
      int w = _clampInt(item.w, c.minW, maxW);
      int h = _clampInt(item.h, c.minH, c.maxH);

      if (x < 0) x = 0;
      if (y < 0) y = 0;
      if (x + w > layout.columns) {
        x = max(0, layout.columns - w);
      }

      return item.copyWith(
        x: x,
        y: y,
        w: w,
        h: h,
      );
    }

    final sanitized = allItems
        .map(sanitize)
        .where((item) {
          final instance = config.findInstance(item.instanceId);
          final spec = instance == null ? null : _registry.byType(instance.type);
          return instance != null && spec != null && instance.isVisible;
        })
        .toList();

    // Recover instances that have a valid spec but lost their layout position
    // (e.g. spec was unregistered on a previous run and the item was filtered out).
    final sanitizedIds = sanitized.map((e) => e.instanceId).toSet();
    for (final instance in config.instances) {
      if (sanitizedIds.contains(instance.id)) continue;
      if (!instance.isVisible) continue;
      final spec = _registry.byType(instance.type);
      if (spec == null) continue;

      final size = spec.defaultSize(layout.breakpoint);
      final c = spec.constraints;
      final w = _clampInt(size.w, c.minW, min(c.maxW, layout.columns));
      final h = _clampInt(size.h, c.minH, c.maxH);
      sanitized.add(DashboardLayoutItem(
        instanceId: instance.id,
        x: 0,
        y: 9999,
        w: w,
        h: h,
      ));
    }

    final priority = priorityInstanceId == null
        ? null
        : sanitized.firstWhereOrNull((e) => e.instanceId == priorityInstanceId);

    final others = sanitized
        .where((e) => e.instanceId != priorityInstanceId)
        .toList(growable: false)
      ..sort((a, b) {
        final byY = a.y.compareTo(b.y);
        if (byY != 0) return byY;
        return a.x.compareTo(b.x);
      });

    final ordered = priority == null
        ? ([...sanitized]..sort((a, b) {
            final byY = a.y.compareTo(b.y);
            if (byY != 0) return byY;
            return a.x.compareTo(b.x);
          }))
        : others;

    final placed = <DashboardLayoutItem>[];

    if (priority != null) {
      placed.add(priority);
    }

    for (final item in ordered) {
      final fitted = _fitItemAgainstPlaced(
        config: config,
        layout: layout,
        item: item,
        placed: placed,
      );
      placed.add(fitted);
    }

    placed.sort((a, b) {
      final byY = a.y.compareTo(b.y);
      if (byY != 0) return byY;
      return a.x.compareTo(b.x);
    });

    return layout.copyWith(items: placed);
  }

  DashboardLayoutItem _fitItemAgainstPlaced({
    required DashboardConfig config,
    required DashboardBreakpointLayout layout,
    required DashboardLayoutItem item,
    required List<DashboardLayoutItem> placed,
  }) {
    var current = item;
    final instance = config.findInstance(item.instanceId)!;
    final spec = _registry.byType(instance.type)!;
    final c = spec.constraints;

    int loops = 0;
    while (loops < 200) {
      loops += 1;

      DashboardLayoutItem? blocker;
      for (final p in placed) {
        if (_intersects(current, p)) {
          blocker = p;
          break;
        }
      }

      if (blocker == null) {
        return _sanitizeToBounds(current, layout, c);
      }

      final shrinkResult = _tryShrinkAgainst(
        current: current,
        blocker: blocker,
        layout: layout,
        constraints: c,
      );

      if (shrinkResult != null) {
        current = shrinkResult;
        continue;
      }

      current = current.copyWith(
        y: blocker.y + blocker.h,
      );
      current = _sanitizeToBounds(current, layout, c);
    }

    return _sanitizeToBounds(current, layout, c);
  }

  DashboardLayoutItem? _tryShrinkAgainst({
    required DashboardLayoutItem current,
    required DashboardLayoutItem blocker,
    required DashboardBreakpointLayout layout,
    required DashboardWidgetConstraints constraints,
  }) {
    final results = <DashboardLayoutItem>[];

    final blockerLeft = blocker.x;
    final blockerRight = blocker.x + blocker.w;
    final blockerTop = blocker.y;
    final blockerBottom = blocker.y + blocker.h;

    final currentRight = current.x + current.w;
    final currentBottom = current.y + current.h;

    if (current.x < blockerLeft && currentRight > blockerLeft) {
      final newW = blockerLeft - current.x;
      if (newW >= constraints.minW) {
        results.add(current.copyWith(w: newW));
      }
    }

    if (current.x < blockerRight && currentRight > blockerRight) {
      final newX = blockerRight;
      final newW = currentRight - newX;
      if (newW >= constraints.minW && newX + newW <= layout.columns) {
        results.add(current.copyWith(x: newX, w: newW));
      }
    }

    if (current.y < blockerTop && currentBottom > blockerTop) {
      final newH = blockerTop - current.y;
      if (newH >= constraints.minH) {
        results.add(current.copyWith(h: newH));
      }
    }

    if (current.y < blockerBottom && currentBottom > blockerBottom) {
      final newY = blockerBottom;
      final newH = currentBottom - newY;
      if (newH >= constraints.minH) {
        results.add(current.copyWith(y: newY, h: newH));
      }
    }

    if (results.isEmpty) return null;

    results.sort((a, b) {
      final areaA = a.w * a.h;
      final areaB = b.w * b.h;
      return areaB.compareTo(areaA);
    });

    return results.first;
  }

  DashboardLayoutItem _sanitizeToBounds(
    DashboardLayoutItem item,
    DashboardBreakpointLayout layout,
    DashboardWidgetConstraints constraints,
  ) {
    int x = item.x;
    int y = item.y;
    int w = _clampInt(
      item.w,
      constraints.minW,
      min(constraints.maxW, layout.columns),
    );
    int h = _clampInt(item.h, constraints.minH, constraints.maxH);

    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x + w > layout.columns) {
      x = max(0, layout.columns - w);
    }

    return item.copyWith(
      x: x,
      y: y,
      w: w,
      h: h,
    );
  }

  bool _intersects(DashboardLayoutItem a, DashboardLayoutItem b) {
    return a.x < b.x + b.w &&
        a.x + a.w > b.x &&
        a.y < b.y + b.h &&
        a.y + a.h > b.y;
  }

  (int, int) _findFirstAvailablePosition({
    required DashboardBreakpointLayout layout,
    required int width,
    required int height,
  }) {
    final maxX = max(0, layout.columns - width);

    for (int y = 0; y < 999; y++) {
      for (int x = 0; x <= maxX; x++) {
        final probe = DashboardLayoutItem(
          instanceId: '__probe__',
          x: x,
          y: y,
          w: width,
          h: height,
        );

        bool collides = false;
        for (final other in layout.items) {
          if (_intersects(probe, other)) {
            collides = true;
            break;
          }
        }

        if (!collides) return (x, y);
      }
    }

    final bottom = layout.items.isEmpty
        ? 0
        : layout.items.map((e) => e.y + e.h).reduce(max);

    return (0, bottom);
  }

  String _nextId(String type) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(99999);
    return '${type}_$stamp$rand';
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    super.dispose();
  }
}

extension _FirstWhereOrNullX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}