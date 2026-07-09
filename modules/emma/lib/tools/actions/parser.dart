import 'package:emma/tools/actions/action.dart';

List<EmmaFrontendAction> parseFrontendActionsFromMeta(
  Map<String, dynamic>? meta, {
  int? messageId,
}) {
  if (meta == null) return const [];

  final out = <EmmaFrontendAction>[];

  void addAction(
    Map<String, dynamic> raw, {
    String module = '',
    String? toolName,
  }) {
    final normalized = _normalizeAction(
      raw,
      module: module,
      toolName: toolName,
      messageId: messageId,
    );

    if (normalized.action.trim().isEmpty) return;
    out.add(normalized);
  }

  final rawActions = meta['frontend_actions'];
  if (rawActions is List) {
    for (final raw in rawActions.whereType<Map>()) {
      addAction(Map<String, dynamic>.from(raw));
    }
  }

  final toolsRaw = meta['tools'];
  if (toolsRaw is List) {
    for (final t in toolsRaw.whereType<Map>()) {
      final tool = Map<String, dynamic>.from(t);

      final module = (tool['module'] ?? '').toString();
      final toolName = (tool['name'] ?? '').toString();

      Map<String, dynamic>? frontend;

      final result = tool['result'];
      if (result is Map) {
        final r = Map<String, dynamic>.from(result);
        final f = r['frontend'];
        if (f is Map) frontend = Map<String, dynamic>.from(f);
      }

      frontend ??= tool['frontend'] is Map
          ? Map<String, dynamic>.from(tool['frontend'] as Map)
          : null;

      if (frontend == null || frontend.isEmpty) continue;

      if (frontend.containsKey('action')) {
        addAction(frontend, module: module, toolName: toolName);
        continue;
      }

      final nestedActions = frontend['actions'];
      if (nestedActions is List) {
        for (final rawNested in nestedActions.whereType<Map>()) {
          addAction(
            Map<String, dynamic>.from(rawNested),
            module: module,
            toolName: toolName,
          );
        }
      }
    }
  }

  return out;
}

EmmaFrontendAction _normalizeAction(
  Map<String, dynamic> raw, {
  String module = '',
  String? toolName,
  int? messageId,
}) {
  final action = (raw['action'] ?? '').toString().trim();
  String mode = (raw['mode'] ?? '').toString().trim();

  final payload = raw['payload'] is Map
      ? Map<String, dynamic>.from(raw['payload'] as Map)
      : <String, dynamic>{};

  final data = raw['data'] is Map
      ? <String, dynamic>{
          ...Map<String, dynamic>.from(raw['data'] as Map),
          ...payload,
        }
      : <String, dynamic>{...payload};

  final target = (raw['target'] ?? '').toString().trim();
  if (target.isNotEmpty) {
    data['target'] = target;

    if (!data.containsKey('anchor_key') &&
        (action == 'ui_highlight_anchor' ||
            action == 'ui_navigate_to_anchor' ||
            action == 'ui_request_context')) {
      data['anchor_key'] = target;
    }
  }

  final frontendModule = (raw['module'] ?? '').toString().trim();
  if (frontendModule.isNotEmpty && !data.containsKey('module')) {
    data['module'] = frontendModule;
  }

  if (mode.isEmpty) {
    if (action == 'ui_highlight_anchor') {
      mode = 'highlight';
    } else if (action == 'ui_navigate_to_anchor' || action == 'navigate') {
      mode = 'navigate';
    } else {
      final preferPopup =
          raw['prefer_popup'] == true || payload['prefer_popup'] == true;
      mode = preferPopup ? 'popup' : 'navigate';
    }
  }

  return EmmaFrontendAction(
    action: action,
    mode: mode,
    module: module.isNotEmpty ? module : frontendModule,
    data: data,
    toolName: toolName ?? raw['tool_name']?.toString(),
    messageId: messageId,
  );
}