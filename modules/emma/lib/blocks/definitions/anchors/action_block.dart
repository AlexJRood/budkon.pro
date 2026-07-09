import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:emma/tools/actions/action.dart';
import 'package:emma/tools/actions/bus.dart';
import 'package:get/get_utils/get_utils.dart';

class UiAnchorActionBlockDefinition extends EmmaBlockDefinition {
  const UiAnchorActionBlockDefinition();

  @override
  String get key => 'ui_anchor_action';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.uiAnchorAction;
  }

  void _dispatch(
    WidgetRef ref,
    EmmaFrontendAction action,
  ) {
    ref.read(emmaFrontendActionBusProvider.notifier).enqueueAll([action]);
  }

  Widget _smallActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool filled = false,
  }) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withAlpha(220),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: color.withAlpha(120)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final variant = (block.raw['variant'] ?? 'highlight').toString();
    final title = (block.raw['title'] ?? 'Akcja interfejsu').toString();
    final label = (block.raw['label'] ?? '').toString();
    final anchorKey = (block.raw['anchor_key'] ?? '').toString();
    final route = (block.raw['route'] ?? '').toString();
    final message = (block.raw['message'] ?? '').toString();
    final module = (block.raw['module'] ?? '').toString();
    final screenKey = (block.raw['screen_key'] ?? '').toString();

    final isNavigate = variant == 'navigate';
    final canHighlight = anchorKey.trim().isNotEmpty;
    final canNavigate = anchorKey.trim().isNotEmpty && route.trim().isNotEmpty;

    EmmaFrontendAction highlightAction() {
      return EmmaFrontendAction(
        action: 'ui_highlight_anchor',
        mode: 'highlight',
        module: module,
        toolName: 'ui_anchor_action_block',
        messageId: int.tryParse(messageId),
        data: {
          'anchor_key': anchorKey,
          'route': route,
          'message': message.isNotEmpty
              ? message
              : label.isNotEmpty
                  ? '${'here_you_will_find'.tr} $label.'
                  : '',
          'placement': 'auto',
          'close_ai_overlay': true,
          'open_mini_emma': true,
        },
      );
    }

    EmmaFrontendAction navigateAction() {
      return EmmaFrontendAction(
        action: 'ui_navigate_to_anchor',
        mode: 'navigate',
        module: module,
        toolName: 'ui_anchor_action_block',
        messageId: int.tryParse(messageId),
        data: {
          'anchor_key': anchorKey,
          'route': route,
          'module': module,
          'screen_key': screenKey,
          'close_ai_overlay': true,
          'open_mini_emma': true,
          'after_navigation': {
            'action': 'ui_highlight_anchor',
            'anchor_key': anchorKey,
            'message': message.isNotEmpty
                ? message
                : label.isNotEmpty
                    ? '${'here_you_will_find'.tr} $label.'
                    : '',
            'placement': 'auto',
          },
        },
      );
    }

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: isNavigate ? Colors.orangeAccent : const Color(0xFF37B6FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNavigate
                ? Icons.open_in_new_rounded
                : Icons.highlight_alt_rounded,
            color: isNavigate ? Colors.orangeAccent : const Color(0xFF37B6FF),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withAlpha(185),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    if (anchorKey.isNotEmpty) anchorKey,
                    if (route.isNotEmpty) route,
                  ].join(' · '),
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallActionButton(
                      label: 'highlight'.tr,
                      icon: Icons.highlight_alt_rounded,
                      color: const Color(0xFF37B6FF),

                      onPressed: canHighlight
                          ? () => _dispatch(
                                ref,
                                route.trim().isNotEmpty ? navigateAction() : highlightAction(),
                              )
                          : null,
                    ),
                    _smallActionButton(
                        label: 'navigate'.tr,
                      icon: Icons.open_in_new_rounded,
                      color: Colors.orangeAccent,
                      filled: true,
                      onPressed: canNavigate
                          ? () => _dispatch(ref, navigateAction())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}