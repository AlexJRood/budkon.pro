// emma/lib/blocks/definitions/docs/docs_text_edit_block.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../../../provider/docs_emma_state.dart';

class DocsTextEditBlockDefinition extends EmmaBlockDefinition {
  const DocsTextEditBlockDefinition();

  @override
  String get key => 'docs_text_edit';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.docsTextEdit;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _DocsTextEditCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _DocsTextEditCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _DocsTextEditCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_DocsTextEditCard> createState() => _DocsTextEditCardState();
}

class _DocsTextEditCardState extends ConsumerState<_DocsTextEditCard> {
  bool _applied = false;
  bool _discarded = false;
  bool _showFull = false;

  String get _original =>
      (widget.block.raw['original'] ?? '').toString().trim();
  String get _rewritten =>
      (widget.block.raw['rewritten'] ?? '').toString().trim();
  String get _instruction =>
      (widget.block.raw['instruction'] ?? '').toString().trim();

  List<String> get _actions {
    final raw = widget.block.raw['actions'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const ['apply', 'discard'];
  }

  void _apply() {
    if (_applied || _discarded) return;
    if (_rewritten.isEmpty) return;

    ref.read(docsEmmaProvider.notifier).requestTextEdit(
          DocsTextEditRequest(
            original: _original,
            rewritten: _rewritten,
            instruction: _instruction,
          ),
        );

    setState(() => _applied = true);
  }

  void _discard() {
    if (_applied || _discarded) return;
    setState(() => _discarded = true);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6C63FF);

    final isDone = _applied || _discarded;

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withAlpha(isDone ? 60 : 110),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _instruction.isNotEmpty
                      ? _instruction
                      : 'ai_text_edit'.tr,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_applied)
                _statusChip('applied'.tr, Colors.greenAccent)
              else if (_discarded)
                _statusChip('discarded'.tr, Colors.white38),
            ],
          ),
          const SizedBox(height: 12),
          if (_rewritten.isNotEmpty) ...[
            _textSection(
              label: 'rewritten_text'.tr,
              text: _rewritten,
              color: Colors.greenAccent.shade100,
              showFull: _showFull,
              onToggle: () => setState(() => _showFull = !_showFull),
            ),
            if (_original.isNotEmpty) ...[
              const SizedBox(height: 10),
              _textSection(
                label: 'original_text'.tr,
                text: _original,
                color: Colors.white54,
                showFull: _showFull,
                onToggle: null,
              ),
            ],
          ],
          if (!isDone) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_actions.contains('apply'))
                  FilledButton.icon(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: Text('apply'.tr),
                  ),
                if (_actions.contains('discard'))
                  OutlinedButton.icon(
                    onPressed: _discard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withAlpha(35)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: Text('discard'.tr),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textSection({
    required String label,
    required String text,
    required Color color,
    required bool showFull,
    required VoidCallback? onToggle,
  }) {
    const maxLines = 6;
    final isLong = text.length > 300 || '\n'.allMatches(text).length >= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(120),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Text(
            text,
            maxLines: (showFull || !isLong) ? null : maxLines,
            overflow: (showFull || !isLong)
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        if (isLong && onToggle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                showFull ? 'show_less'.tr : 'show_more'.tr,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
