// emma/provider/context.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ------------------------------------------------------------
/// Route -> module mapping (fallback)
/// ------------------------------------------------------------
/// NOTE:
/// We keep this as a fallback, but in production we prefer
/// route+module resolution done in `emma/routing/emma_route_sync.dart`
/// (based on your app Routes).
String emmaModuleFromPath(String path) {
  final p = path.toLowerCase();

  // Dynamic App / Builder
  if (p.startsWith('/dynamic') || p.contains('/dynamic_app')) return 'dynamic_app';

  // Mail
  if (p.startsWith('/mail') || p.contains('/email')) return 'email';

  // Crm
  if (p.startsWith('/pro') || p.contains('/pro')) return 'crm';

  // Calendar
  if (p.startsWith('/calendar')) return 'calendar';

  // Finance
  if (p.startsWith('/finance') || p.contains('/invoices')) return 'finance';

  // Tasks / TMS
  if (p.startsWith('/tms') || p.contains('/tasks')) return 'tms';

  // Notes
  if (p.startsWith('/notes')) return 'notes';

  // Docs
  if (p.startsWith('/docs')) return 'docs';

  return 'unknown';
}

/// Default order when we DON'T know better.
/// Backend/LLM can treat this as priority hints (not hard allowlist).
List<String> defaultPreferredModules(String current) {
  final all = <String>[
    'crm',
    'email',
    'calendar',
    'finance',
    'tms',
    'notes',
    'docs',
    'dynamic_app',
  ];

  if (all.contains(current)) {
    return [current, ...all.where((m) => m != current)];
  }
  return all;
}

/// ------------------------------------------------------------
/// Dynamic App context (small, per owner)
/// ------------------------------------------------------------

@immutable
class EmmaDynamicAppContext {
  final String ownerKey;
  final int? appId;
  final int? pageId;
  final String? nodeId;
  final List<int>? nodePath;
  final String? nodeKind;

  const EmmaDynamicAppContext({
    required this.ownerKey,
    this.appId,
    this.pageId,
    this.nodeId,
    this.nodePath,
    this.nodeKind,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'module': 'dynamic_app',
      'owner_key': ownerKey,
      'app_id': appId,
      'page_id': pageId,
      'node_id': nodeId,
      'node_path': nodePath,
      'node_kind': nodeKind,
    }..removeWhere((k, v) => v == null);
  }
}

/// ------------------------------------------------------------
/// Global Emma context state
/// ------------------------------------------------------------

@immutable
class EmmaContextState {
  /// Current route (from Beamer)
  final String route;

  /// Current module inferred/resolved from route (NOT a hard tool filter!)
  final String module;

  /// Priority hint for modules (ordering)
  final List<String> preferredModules;

  /// Which owner is currently active (inline chat, pc chat, etc.)
  final String? activeOwnerKey;

  /// Per-owner dynamic app context
  final Map<String, EmmaDynamicAppContext> dynamicAppByOwner;

  /// Extra flat fields merged into frontend_context at send time.
  /// Modules (docs, crm, etc.) can inject arbitrary keys here.
  /// Keys should NOT clash with top-level context keys (route, module, etc.).
  final Map<String, dynamic> extraModuleContext;

  const EmmaContextState({
    required this.route,
    required this.module,
    required this.preferredModules,
    required this.activeOwnerKey,
    required this.dynamicAppByOwner,
    this.extraModuleContext = const <String, dynamic>{},
  });

  factory EmmaContextState.initial() => EmmaContextState(
        route: '/',
        module: 'unknown',
        preferredModules: defaultPreferredModules('unknown'),
        activeOwnerKey: null,
        dynamicAppByOwner: const <String, EmmaDynamicAppContext>{},
      );

  EmmaContextState copyWith({
    String? route,
    String? module,
    List<String>? preferredModules,
    String? activeOwnerKey,
    Map<String, EmmaDynamicAppContext>? dynamicAppByOwner,
    Map<String, dynamic>? extraModuleContext,
  }) {
    return EmmaContextState(
      route: route ?? this.route,
      module: module ?? this.module,
      preferredModules: preferredModules ?? this.preferredModules,
      activeOwnerKey: activeOwnerKey ?? this.activeOwnerKey,
      dynamicAppByOwner: dynamicAppByOwner ?? this.dynamicAppByOwner,
      extraModuleContext: extraModuleContext ?? this.extraModuleContext,
    );
  }

  /// Active dynamic app ctx (if any)
  EmmaDynamicAppContext? get activeDynamicApp {
    final k = activeOwnerKey;
    if (k != null) return dynamicAppByOwner[k];
    if (dynamicAppByOwner.isEmpty) return null;
    // fallback: last inserted
    return dynamicAppByOwner.values.last;
  }

  /// This is what we send to backend.
  /// dynamicAppOverride lets you force a specific dyn ctx for this message.
  Map<String, dynamic> toBackendContext({EmmaDynamicAppContext? dynamicAppOverride}) {
    final dyn = dynamicAppOverride ?? activeDynamicApp;

    return <String, dynamic>{
      ...extraModuleContext,
      'route': route,
      'module': module,
      'preferred_modules': preferredModules,
      if (dyn != null) 'dynamic_app': dyn.toJson(),
    }..removeWhere((k, v) => v == null);
  }
}

/// ------------------------------------------------------------
/// Notifier
/// ------------------------------------------------------------

class EmmaContextNotifier extends StateNotifier<EmmaContextState> {
  EmmaContextNotifier() : super(EmmaContextState.initial());

  /// Fallback: resolve module internally (simple mapping).
  void setRoute(String route) {
    final mod = emmaModuleFromPath(route);
    state = state.copyWith(
      route: route,
      module: mod,
      preferredModules: defaultPreferredModules(mod),
    );
  }

  /// ✅ Preferred: set route + module resolved outside (e.g. using app Routes).
  void setRouteResolved({
    required String route,
    required String module,
  }) {
    state = state.copyWith(
      route: route,
      module: module,
      preferredModules: defaultPreferredModules(module),
    );
  }

  void setActiveOwnerKey(String ownerKey) {
    state = state.copyWith(activeOwnerKey: ownerKey);
  }

  void clearActiveOwnerKey(String ownerKey) {
    if (state.activeOwnerKey == ownerKey) {
      state = state.copyWith(activeOwnerKey: null);
    }
  }

  void setDynamicAppContext({
    required String ownerKey,
    int? appId,
    int? pageId,
    String? nodeId,
    List<int>? nodePath,
    String? nodeKind,
  }) {
    final updated = Map<String, EmmaDynamicAppContext>.from(state.dynamicAppByOwner);
    updated[ownerKey] = EmmaDynamicAppContext(
      ownerKey: ownerKey,
      appId: appId,
      pageId: pageId,
      nodeId: nodeId,
      nodePath: nodePath,
      nodeKind: nodeKind,
    );

    state = state.copyWith(
      dynamicAppByOwner: updated,
      activeOwnerKey: ownerKey,
    );
  }

  void clearDynamicAppContext({required String ownerKey}) {
    final updated = Map<String, EmmaDynamicAppContext>.from(state.dynamicAppByOwner);
    updated.remove(ownerKey);

    state = state.copyWith(
      dynamicAppByOwner: updated,
      activeOwnerKey: (state.activeOwnerKey == ownerKey) ? null : state.activeOwnerKey,
    );
  }

  /// Set arbitrary flat fields that get merged into frontend_context at send time.
  /// Use null values to remove specific keys.
  void setModuleContext(Map<String, dynamic> extra) {
    final merged = Map<String, dynamic>.from(state.extraModuleContext);
    for (final entry in extra.entries) {
      if (entry.value == null) {
        merged.remove(entry.key);
      } else {
        merged[entry.key] = entry.value;
      }
    }
    state = state.copyWith(extraModuleContext: merged);
  }

  void clearModuleContext() {
    state = state.copyWith(extraModuleContext: const <String, dynamic>{});
  }
}

final emmaContextProvider =
    StateNotifierProvider<EmmaContextNotifier, EmmaContextState>(
  (ref) => EmmaContextNotifier(),
);

/// ✅ Compatibility provider: places that expect EmmaDynamicAppContext? should use this.
final emmaDynamicAppContextProvider = Provider<EmmaDynamicAppContext?>((ref) {
  final s = ref.watch(emmaContextProvider);
  return s.activeDynamicApp;
});
