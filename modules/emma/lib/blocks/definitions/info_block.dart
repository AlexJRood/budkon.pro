import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';

class InfoBlockDefinition extends EmmaBlockDefinition {
  const InfoBlockDefinition();

  @override
  String get key => 'info';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.info;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final variant = (block.raw['variant'] ?? 'info').toString();
    final title = (block.raw['title'] ?? 'Informacja').toString();
    final text = (block.raw['text'] ?? '').toString();

    final color = switch (variant) {
      'success' => Colors.greenAccent,
      'warning' => Colors.orangeAccent,
      'error' => Colors.redAccent,
      _ => const Color(0xFF37B6FF),
    };

    final icon = switch (variant) {
      'success' => Icons.check_circle_outline_rounded,
      'warning' => Icons.warning_amber_rounded,
      'error' => Icons.error_outline_rounded,
      _ => Icons.info_outline_rounded,
    };

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmmaAccentIcon(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (text.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}