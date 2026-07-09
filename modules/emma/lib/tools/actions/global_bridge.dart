import 'dart:async';
import 'dart:convert';

import 'package:emma/provider/context.dart';
import 'package:emma/provider/emma_notifier.dart';
import 'package:emma/tools/actions/action.dart';
import 'package:emma/tools/actions/bus.dart';
import 'package:emma/tools/open_emma.dart';
import 'package:core/ui/anchors/anchor_registry.dart';
import 'package:core/ui/highlight/highlight_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';

class EmmaFrontendBridge extends ConsumerStatefulWidget {
  const EmmaFrontendBridge({super.key});

  @override
  ConsumerState<EmmaFrontendBridge> createState() => _EmmaFrontendBridgeState();
}

class _EmmaFrontendBridgeState extends ConsumerState<EmmaFrontendBridge> {
  static const String _ownerKey = 'emma_frontend_bridge';

  late final ProviderSubscription<EmmaFrontendActionBusState> _busSub;

  bool _isProcessing = false;
  bool _miniEmmaOpen = false;
  bool _miniEmmaOpening = false;

  @override
  void initState() {
    super.initState();

    _busSub = ref.listenManual<EmmaFrontendActionBusState>(
      emmaFrontendActionBusProvider,
      (prev, next) {
        if (!mounted) return;
        if (_isProcessing) return;
        if (!next.hasActions) return;

        final resolvedContext = _resolveContext();
        if (resolvedContext == null) return;

        unawaited(_processQueue(resolvedContext));
      },
      fireImmediately: true,
    );
  }

  BuildContext? _resolveContext() {
    try {
      final nav = ref.read(navigationService);
      final navContext = nav.navigatorKey.currentContext;
      if (navContext != null) return navContext;
    } catch (_) {}

    if (!mounted) return null;
    return context;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Future<void> _processQueue(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (mounted) {
        final bus = ref.read(emmaFrontendActionBusProvider.notifier);
        final current = ref.read(emmaFrontendActionBusProvider).first;
        if (current == null) break;

        final action = bus.pop();
        if (action == null) break;

        final resolvedContext = _resolveContext();
        if (resolvedContext == null) break;

        await _handleAction(resolvedContext, action);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Map<String, dynamic> _buildCurrentUiContext() {
    final base = ref.read(emmaContextProvider).toBackendContext();
    final registry = ref.read(emmaUiAnchorRegistryProvider.notifier);
    final visibleAnchors = registry.getVisibleAnchors();
    final semanticAnchors = registry.exportSemanticJson();

    return {
      ...base,
      if (visibleAnchors.isNotEmpty) 'visible_anchors': visibleAnchors,
      if (semanticAnchors.isNotEmpty) 'semantic_anchors': semanticAnchors,
    };
  }

  Future<void> _handleOpenEmma(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    if (_miniEmmaOpen || _miniEmmaOpening) {
      if (kDebugMode) {
        debugPrint('EmmaFrontendBridge: Emma already open/opening');
      }
      return;
    }

    _miniEmmaOpening = true;

    try {
      _miniEmmaOpen = true;

      if (kDebugMode) {
        debugPrint(
          'EmmaFrontendBridge: opening Emma overlay, '
          'action=${action.action}, data=${action.data}',
        );
      }

      await openEmmaOverlay(
        context: context,
        ref: ref,
        data: action.data,
        title: 'Emma',
      );

      if (kDebugMode) {
        debugPrint('EmmaFrontendBridge: Emma overlay closed');
      }
    } finally {
      _miniEmmaOpen = false;
      _miniEmmaOpening = false;
    }
  }

  Future<void> _ensureMiniEmmaOpened(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    if (_miniEmmaOpen || _miniEmmaOpening) return;

    _miniEmmaOpening = true;
    _miniEmmaOpen = true;

    unawaited(() async {
      try {
        await openEmmaOverlay(
          context: context,
          ref: ref,
          data: action.data,
          title: 'Emma',
        );
      } finally {
        if (mounted) {
          _miniEmmaOpen = false;
          _miniEmmaOpening = false;
        }
      }
    }());

    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _handleAction(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    switch (action.action) {
      case 'ui_highlight_anchor':
        await _handleUiHighlightAnchor(context, action);
        return;

      case 'ui_start_flow':
        await _handleUiStartFlow(context, action);
        return;

      case 'ui_show_chat_form':
        await _handleUiShowChatForm(context, action);
        return;

      case 'ui_request_context':
        await _handleUiRequestContext(action);
        return;
      
      case 'ui_navigate_to_anchor':
        await _handleUiNavigateToAnchor(context, action);
        return;

      case 'open_widget_editor':
        await _handleOpenWidgetEditor(context, action);
        return;

      case 'open_emma':
      case 'emma.open':
      case 'dynamic_app.open_emma':
        await _handleOpenEmma(context, action);
        return;

      case 'navigate':
        await _handleNavigate(context, action);
        return;

      case 'toast':
        _handleToast(action);
        return;

      default:
        if (kDebugMode) {
          debugPrint('EmmaFrontendBridge: unhandled action: $action');
        }
        return;
    }
  }

  Future<void> _prepareSurfaceForHighlight(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    final nav = ref.read(navigationService);

    final closeLargeEmma = (action.data['close_large_emma'] as bool?) ?? true;
    final closeAiOverlay =
        (action.data['close_ai_overlay'] as bool?) ?? closeLargeEmma;
    final closeChatOverlay =
        (action.data['close_chat_overlay'] as bool?) ?? false;
    final openMiniEmma = (action.data['open_mini_emma'] as bool?) ?? false;

    final route = (action.data['route'] ?? '').toString().trim();
    final replaceRoute = (action.data['replace_route'] as bool?) ?? false;
    final args = action.data['args'];

    ref.read(emmaUiHighlightProvider.notifier).hide();

    if (closeAiOverlay) {
      await nav.closeAiOverlayIfOpen();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (closeChatOverlay) {
      await nav.closeChatOverlayIfOpen();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (route.isNotEmpty) {
      await nav.goToIfNeeded(
        route,
        data: args,
        replace: replaceRoute,
      );

      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    if (openMiniEmma) {
      final resolvedContext = _resolveContext();
      if (resolvedContext != null) {
        await _ensureMiniEmmaOpened(resolvedContext, action);
      }
    }

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

    
  Future<Rect?> _waitForAnchorRect(
    String anchorKey, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final registry = ref.read(emmaUiAnchorRegistryProvider.notifier);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final rect = registry.getRect(anchorKey);
      if (rect != null) return rect;

      if (kDebugMode) {
        final visible = registry.getVisibleAnchors();
        debugPrint(
          'EmmaFrontendBridge: waiting for anchor=$anchorKey visible=$visible',
        );
      }
    }

    return null;
  }

Future<void> _prepareRuntimeAnchor(String anchorKey) async {
  final registry = ref.read(emmaUiAnchorRegistryProvider.notifier);
  registry.requestRuntime(anchorKey);

  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 16));
}

void _releaseRuntimeAnchor(String anchorKey) {
  ref
      .read(emmaUiAnchorRegistryProvider.notifier)
      .releaseRuntimeRequest(anchorKey);
}


Future<void> _handleUiHighlightAnchor(
  BuildContext context,
  EmmaFrontendAction a,
) async {
  final anchorKey =
      (a.data['anchor_key'] ?? a.data['target'] ?? '').toString().trim();
  final message = (a.data['message'] ?? '').toString();
  final placement = (a.data['placement'] ?? 'auto').toString();

  if (anchorKey.isEmpty) return;

  await _prepareSurfaceForHighlight(context, a);
  await _prepareRuntimeAnchor(anchorKey);

  Rect? rect;
  try {
    rect = await _waitForAnchorRect(anchorKey);
  } finally {
    // Po pokazaniu highlightu anchor zostanie utrzymany przez sam highlight.
    // Jeśli highlight się nie pokaże, runtime request też nie zostanie na stałe.
    _releaseRuntimeAnchor(anchorKey);
  }

  if (kDebugMode) {
    final visible =
        ref.read(emmaUiAnchorRegistryProvider.notifier).getVisibleAnchors();
    debugPrint(
      'EmmaFrontendBridge: highlight anchor=$anchorKey rect=$rect visible=$visible route=${a.data['route']}',
    );
  }

  if (rect == null) {
    final requestId = (a.data['request_id'] ?? '').toString().trim();

    if (kDebugMode) {
      debugPrint('EmmaFrontendBridge: anchor not found after runtime prepare: $anchorKey');
    }

    if (requestId.isNotEmpty) {
      await ref.read(chatAiMessageProvider.notifier).sendUiContextResponse(
            requestId: requestId,
            context: _buildCurrentUiContext(),
          );
    }
    return;
  }

  final closeOnOutsideTap = (a.data['close_on_outside_tap'] as bool?) ?? false;

  ref.read(emmaUiHighlightProvider.notifier).show(
        anchorKey: anchorKey,
        rect: rect,
        message: message,
        placement: placement,
        closeOnOutsideTap: closeOnOutsideTap,
        closeOnAnchorTap: true,
      );
}




  Future<void> _handleUiStartFlow(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    final stepRaw = action.data['step'];
    final step = stepRaw is Map
        ? Map<String, dynamic>.from(stepRaw)
        : <String, dynamic>{};

    final anchorKey = (step['anchor_key'] ?? '').toString().trim();
    final message = (step['message'] ?? step['cta_label'] ?? '').toString();
    final placement = (step['placement'] ?? 'auto').toString();

    if (anchorKey.isNotEmpty) {
      await _handleUiHighlightAnchor(
        context,
        EmmaFrontendAction(
          action: 'ui_highlight_anchor',
          mode: action.mode,
          module: action.module,
          data: {
            ...Map<String, dynamic>.from(action.data),
            'anchor_key': anchorKey,
            'message': message,
            'placement': placement,
            if (action.data['request_id'] != null)
              'request_id': action.data['request_id'],
          },
          toolName: action.toolName,
          messageId: action.messageId,
        ),
      );
      return;
    }

    if (message.trim().isNotEmpty) {
      _showGlobalSnackBar(message);
    }
  }

  Future<void> _handleUiShowChatForm(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    final formKey = (action.data['form_key'] ?? '').toString();
    final title = (action.data['title'] ?? 'Formularz').toString();
    final initialRaw = action.data['initial'];
    final initial = initialRaw is Map
        ? Map<String, dynamic>.from(initialRaw)
        : <String, dynamic>{};

    final resolvedContext = _resolveContext();
    if (resolvedContext == null) return;

    await showDialog<void>(
      context: resolvedContext,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          title.isEmpty ? formKey : title,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert({
              'form_key': formKey,
              'initial': initial,
            }),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
            child:  Text('close'.tr),
          ),
        ],
      ),
    );
  }
Future<void> _handleUiNavigateToAnchor(
  BuildContext context,
  EmmaFrontendAction action,
) async {
  final nav = ref.read(navigationService);

  final anchorKey =
      (action.data['anchor_key'] ?? action.data['target'] ?? '')
          .toString()
          .trim();

  final route = (action.data['route'] ?? '').toString().trim();
  final args = action.data['args'];

  final replaceRoute = (action.data['replace_route'] as bool?) ?? false;
  final closeAiOverlay = (action.data['close_ai_overlay'] as bool?) ?? true;
  final closeChatOverlay = (action.data['close_chat_overlay'] as bool?) ?? false;
  final openMiniEmma = (action.data['open_mini_emma'] as bool?) ?? true;

  final afterRaw = action.data['after_navigation'];
  final afterNavigation = afterRaw is Map
      ? Map<String, dynamic>.from(afterRaw)
      : <String, dynamic>{};

  final afterAnchorKey =
      (afterNavigation['anchor_key'] ?? anchorKey).toString().trim();

  final message = (afterNavigation['message'] ??
          action.data['message'] ??
          '')
      .toString();

  final placement = (afterNavigation['placement'] ??
          action.data['placement'] ??
          'auto')
      .toString();

  if (kDebugMode) {
    debugPrint(
      'EmmaFrontendBridge: ui_navigate_to_anchor route=$route '
      'anchor=$anchorKey data=${action.data}',
    );
  }

  if (route.isEmpty) {
    if (afterAnchorKey.isNotEmpty) {
      await _handleUiHighlightAnchor(
        context,
        EmmaFrontendAction(
          action: 'ui_highlight_anchor',
          mode: 'highlight',
          module: action.module,
          data: {
            ...action.data,
            'anchor_key': afterAnchorKey,
            'message': message,
            'placement': placement,
          },
          toolName: action.toolName,
          messageId: action.messageId,
        ),
      );
    }
    return;
  }

  try {
    ref.read(emmaUiHighlightProvider.notifier).hide();

    if (closeAiOverlay) {
      await nav.closeAiOverlayIfOpen();
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }

    if (closeChatOverlay) {
      await nav.closeChatOverlayIfOpen();
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }

      await nav.goToIfNeeded(
        route,
        data: args,
        replace: replaceRoute,
      );

      debugPrint(
        'EmmaFrontendBridge: after navigation currentPath=${nav.currentPath} target=$route',
      );

      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (openMiniEmma) {
      final resolvedContext = _resolveContext();
      if (resolvedContext != null) {
        await _ensureMiniEmmaOpened(resolvedContext, action);
      }
    }

    if (afterAnchorKey.isNotEmpty) {
      await _handleUiHighlightAnchor(
        context,
        EmmaFrontendAction(
          action: 'ui_highlight_anchor',
          mode: 'highlight',
          module: action.module,
          data: {
            ...action.data,
            'anchor_key': afterAnchorKey,
            'message': message,
            'placement': placement,
            'route': '',
            'close_ai_overlay': false,
            'close_chat_overlay': false,
            'open_mini_emma': false,
          },
          toolName: action.toolName,
          messageId: action.messageId,
        ),
      );
    }
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('EmmaFrontendBridge: ui_navigate_to_anchor failed: $e\n$stack');
    }
  }
}

  Future<void> _handleUiRequestContext(EmmaFrontendAction action) async {
    final requestId = (action.data['request_id'] ?? '').toString().trim();
    if (requestId.isEmpty) return;

    await ref.read(chatAiMessageProvider.notifier).sendUiContextResponse(
          requestId: requestId,
          context: _buildCurrentUiContext(),
        );
  }

  Future<void> _handleOpenWidgetEditor(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final appId = toInt(action.data['app_id']);
    final pageId = toInt(action.data['page_id']);
    final widgetId = toInt(action.data['widget_id']);
    final nodeId = widgetId?.toString();

    try {
      ref.read(emmaContextProvider.notifier).setDynamicAppContext(
            ownerKey: _ownerKey,
            appId: appId,
            pageId: pageId,
            nodeId: nodeId,
            nodePath: null,
            nodeKind: (action.data['node_kind'] ?? '').toString().trim().isEmpty
                ? null
                : (action.data['node_kind'] as String),
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Bridge: setDynamicAppContext error: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('Bridge: open_widget_editor (default stub) $action');
    }
  }

  Future<void> _handleNavigate(
    BuildContext context,
    EmmaFrontendAction action,
  ) async {
    final nav = ref.read(navigationService);
    final route = (action.data['route'] ?? '').toString().trim();
    if (route.isEmpty) return;

    final replace = (action.data['replace_route'] as bool?) ?? false;
    final closeAiOverlay = (action.data['close_ai_overlay'] as bool?) ?? false;
    final closeChatOverlay =
        (action.data['close_chat_overlay'] as bool?) ?? false;
    final args = action.data['args'];

    try {
      if (closeAiOverlay) {
        await nav.closeAiOverlayIfOpen();
      }
      if (closeChatOverlay) {
        await nav.closeChatOverlayIfOpen();
      }

      await nav.goToIfNeeded(
        route,
        data: args,
        replace: replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Bridge: navigate failed: $e');
      }
    }
  }

  void _handleToast(EmmaFrontendAction action) {
    final text = (action.data['text'] ?? '').toString();
    if (text.trim().isEmpty) return;
    _showGlobalSnackBar(text);
  }

  void _showGlobalSnackBar(String text) {
    try {
      ref.read(navigationService).showSnackbar(
            SnackBar(content: Text(text)),
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _busSub.close();
    super.dispose();
  }
}