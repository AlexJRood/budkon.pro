import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';

class GenericBlockDefinition extends EmmaBlockDefinition {
  const GenericBlockDefinition();

  @override
  String get key => 'generic_block';

  @override
  bool supports(EmmaBlockDescriptor block) => true;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    // Fallback tekstowy: nowe/nieznane bloki z backendu często niosą pole `text`
    // (lub content/message) — pokaż je zamiast surowego "Nieobsługiwany blok".
    final fallback = _fallbackText(block.raw);

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 0.8,
        ),
      ),
      child: Text(
        fallback.isNotEmpty
            ? fallback
            : '${'unsupported_block'.tr}: ${block.raw['type']}',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  String _fallbackText(Map<String, dynamic> raw) {
    for (final key in const ['text', 'content', 'message', 'summary']) {
      final v = raw[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}