// lib/emma/tools/actions/action.dart
import 'package:flutter/foundation.dart';

@immutable
class EmmaFrontendAction {
  /// np. "open_widget_editor", "navigate", "toast"
  final String action;

  /// np. "popup" | "navigate" | "silent"
  final String mode;

  /// np. "dynamic_app" | "calendar" | "email" ...
  final String module;

  /// dowolne payloady
  final Map<String, dynamic> data;

  /// skąd przyszło (opcjonalne)
  final String? toolName;
  final int? messageId;

  const EmmaFrontendAction({
    required this.action,
    required this.mode,
    required this.module,
    required this.data,
    this.toolName,
    this.messageId,
  });

  @override
  String toString() =>
      'EmmaFrontendAction(module=$module, action=$action, mode=$mode, tool=$toolName, messageId=$messageId, data=$data)';
}
