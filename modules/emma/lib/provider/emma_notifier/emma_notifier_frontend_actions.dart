part of '../emma_notifier.dart';

/// Frontend action extraction and dispatch.
///
/// Assistant messages may include frontend actions in metadata. These actions
/// are deduplicated so reconnects and refreshes do not execute the same UI
/// command multiple times.
extension EmmaNotifierFrontendActions on ChatAiMessagesNotifier {
  String _frontendActionDedupeKey(
    ChatMessageDto msg,
    EmmaFrontendAction action,
  ) {
    final data = action.data;

    return [
      msg.id,
      action.action,
      action.mode,
      action.module,
      action.toolName ?? '',
      data['anchor_key'] ?? '',
      data['route'] ?? '',
      data['target'] ?? '',
      data['message'] ?? '',
      data['placement'] ?? '',
    ].join('|');
  }

  void _handleFrontendToolsForMessage(ChatMessageDto msg) {
    if (msg.isUser) return;
    if (msg.id <= 0) return;

    try {
      final actions = parseFrontendActionsFromMeta(msg.meta, messageId: msg.id);
      if (actions.isEmpty) return;

      final freshActions = <EmmaFrontendAction>[];

      for (final action in actions) {
        final key = _frontendActionDedupeKey(msg, action);
        if (_handledFrontendActionKeys.add(key)) {
          freshActions.add(action);
        }
      }

      if (freshActions.isEmpty) return;

      ref.read(emmaFrontendActionBusProvider.notifier).enqueueAll(freshActions);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Emma: frontend tools dispatch error: $e');
      }
    }
  }

  Map<String, dynamic> _buildBackendUiContext({
    EmmaDynamicAppContext? dynamicAppOverride,
  }) {
    final baseCtx = ref.read(emmaContextProvider);
    final backendCtx = baseCtx.toBackendContext(
      dynamicAppOverride: dynamicAppOverride,
    );

    final visibleAnchors =
        ref.read(emmaUiAnchorRegistryProvider.notifier).getVisibleAnchors();

    if (visibleAnchors.isNotEmpty) {
      backendCtx['visible_anchors'] = visibleAnchors;
    }

    return backendCtx;
  }

  Future<void> sendUiContextResponse({
    required String requestId,
    required Map<String, dynamic> context,
  }) async {
    if (requestId.trim().isEmpty) return;

    final backendCtx = _buildBackendUiContext();
    final mergedContext = {
      ...context,
      'frontend_context': backendCtx,
    };

    final payload = {
      'action': 'ui_context_response',
      'request_id': requestId,
      'context': mergedContext,
    };

    try {
      if (_channel != null && _isConnected) {
        _channel!.sink.add(jsonEncode(payload));
        return;
      }
    } catch (_) {}

    if (kDebugMode) {
      debugPrint('Emma: ui_context_response skipped, WS not connected');
    }
  }
}
