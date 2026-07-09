import 'package:flutter/foundation.dart';

@immutable
class EmmaThinkingPublic {
  final String suggestedModule; // e.g. "dynamic_app"
  final List<String> preferredModules;
  final String depth; // "light" | "deep"
  final bool askUiContext;
  final String reason;
  final Map<String, dynamic> needs;

  const EmmaThinkingPublic({
    required this.suggestedModule,
    required this.preferredModules,
    required this.depth,
    required this.askUiContext,
    required this.reason,
    required this.needs,
  });

  factory EmmaThinkingPublic.fromJson(Map<String, dynamic> json) {
    final preferredRaw = json['preferred_modules'];
    final preferred = preferredRaw is List
        ? preferredRaw.map((e) => e.toString()).toList()
        : const <String>[];

    final needsRaw = json['needs'];
    final needs = needsRaw is Map
        ? Map<String, dynamic>.from(needsRaw as Map)
        : <String, dynamic>{};

    return EmmaThinkingPublic(
      suggestedModule: (json['suggested_module'] ?? '').toString(),
      preferredModules: preferred,
      depth: (json['depth'] ?? 'light').toString(),
      askUiContext: json['ask_ui_context'] == true,
      reason: (json['reason'] ?? '').toString(),
      needs: needs,
    );
  }
}
