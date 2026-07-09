import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';
import 'package:emma/tools/actions/action.dart';
import 'package:emma/tools/actions/bus.dart';
import 'package:get/get_utils/get_utils.dart';

class UiAnchorSearchResultsBlockDefinition extends EmmaBlockDefinition {
  const UiAnchorSearchResultsBlockDefinition();

  @override
  String get key => 'ui_anchor_search_results';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.uiAnchorSearchResults;
  }

  void _dispatch(WidgetRef ref, EmmaFrontendAction action) {
    if (kDebugMode) {
      debugPrint(
        'UiAnchorSearchResultsBlock: dispatch action=${action.action} data=${action.data}',
      );
    }

    ref.read(emmaFrontendActionBusProvider.notifier).enqueueAll([action]);
  }

  EmmaFrontendAction _highlightAction({
    required Map<String, dynamic> item,
    required String messageId,
  }) {
    final anchorKey = (item['anchor_key'] ?? '').toString().trim();
    final route = (item['route'] ?? '').toString().trim();
    final label = (item['label'] ?? anchorKey).toString();

    return EmmaFrontendAction(
      action: 'ui_highlight_anchor',
      mode: 'highlight',
      module: (item['module'] ?? '').toString(),
      toolName: 'ui_anchor_search_results_block',
      messageId: int.tryParse(messageId),
      data: {
        'anchor_key': anchorKey,
        'route': route,
        'message': 'Tutaj znajdziesz: $label.',
        'placement': 'auto',
        'close_ai_overlay': true,
        'close_chat_overlay': false,
        'open_mini_emma': true,
      },
    );
  }

  EmmaFrontendAction _navigateAction({
    required Map<String, dynamic> item,
    required String messageId,
    bool highlightAfterNavigation = true,
  }) {
    final anchorKey = (item['anchor_key'] ?? '').toString().trim();
    final route = (item['route'] ?? '').toString().trim();
    final label = (item['label'] ?? anchorKey).toString();

    return EmmaFrontendAction(
      action: route.isNotEmpty ? 'ui_navigate_to_anchor' : 'ui_highlight_anchor',
      mode: route.isNotEmpty ? 'navigate' : 'highlight',
      module: (item['module'] ?? '').toString(),
      toolName: 'ui_anchor_search_results_block',
      messageId: int.tryParse(messageId),
      data: {
        'anchor_key': anchorKey,
        'route': route,
        'module': (item['module'] ?? '').toString(),
        'screen_key': (item['screen_key'] ?? '').toString(),
        'close_ai_overlay': true,
        'close_chat_overlay': false,
        'open_mini_emma': true,
        if (highlightAfterNavigation && anchorKey.isNotEmpty)
          'after_navigation': {
            'action': 'ui_highlight_anchor',
            'anchor_key': anchorKey,
            'message': 'Tutaj znajdziesz: $label.',
            'placement': 'auto',
          },
      },
    );
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
    final title = (block.raw['title'] ?? 'ui_elements'.tr).toString();
    final query = (block.raw['query'] ?? '').toString();
    final emptyMessage =
        (block.raw['empty_message'] ?? 'no_results'.tr).toString();

    final rawItems = block.raw['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: const Color(0xFF37B6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                color: Color(0xFF37B6FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (query.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${'searched_for_with_colon'.tr} "$query"',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
                height: 1.4,
              ),
            )
          else
            Column(
              children: items.map((item) {
                final label =
                    (item['label'] ?? item['anchor_key'] ?? '').toString();
                final anchorKey = (item['anchor_key'] ?? '').toString().trim();
                final route = (item['route'] ?? '').toString().trim();
                final module = (item['module'] ?? '').toString();
                final score = (item['score'] ?? '').toString();

                final canHighlight = anchorKey.isNotEmpty;
                final canNavigate = route.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(16)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.push_pin_outlined,
                        color: Color(0xFF37B6FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (anchorKey.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                anchorKey,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(130),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (route.isNotEmpty || module.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (module.isNotEmpty) module,
                                  if (route.isNotEmpty) route,
                                  if (score.isNotEmpty) 'score: $score',
                                ].join(' · '),
                                style: TextStyle(
                                  color: Colors.white.withAlpha(120),
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
                                            route.isNotEmpty
                                                ? _navigateAction(
                                                    item: item,
                                                    messageId: messageId,
                                                    highlightAfterNavigation:
                                                        true,
                                                  )
                                                : _highlightAction(
                                                    item: item,
                                                    messageId: messageId,
                                                  ),
                                          )
                                      : null,
                                ),
                                _smallActionButton(
                                  label: 'navigate'.tr,
                                  icon: Icons.open_in_new_rounded,
                                  color: Colors.orangeAccent,
                                  filled: true,
                                  onPressed: canNavigate
                                      ? () => _dispatch(
                                            ref,
                                            _navigateAction(
                                              item: item,
                                              messageId: messageId,
                                              highlightAfterNavigation:
                                                  anchorKey.isNotEmpty,
                                            ),
                                          )
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
              }).toList(),
            ),
        ],
      ),
    );
  }
}