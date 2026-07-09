import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emma/provider/emma_notifier.dart';

import '../core/block_definition.dart';
import '../core/block_descriptor.dart';
import 'shared/block_ui.dart';

/// Blok pytania z opcjami (emma_ask_user). Renderuje pytanie + klikalne chipy.
/// Klik w opcję = wysłanie etykiety jako wiadomość użytkownika (jak wpisana ręcznie).
/// Multi-select: zaznaczasz kilka i wysyłasz jednym przyciskiem.
/// allow_custom: user może po prostu wpisać własną odpowiedź w polu czatu.
class ChoiceQuestionBlockDefinition extends EmmaBlockDefinition {
  const ChoiceQuestionBlockDefinition();

  @override
  String get key => 'choice_question';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.choiceQuestion;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _ChoiceQuestionCard(block: block, maxWidth: maxWidth);
  }
}

class _ChoiceQuestionCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _ChoiceQuestionCard({required this.block, required this.maxWidth});

  @override
  ConsumerState<_ChoiceQuestionCard> createState() =>
      _ChoiceQuestionCardState();
}

class _ChoiceQuestionCardState extends ConsumerState<_ChoiceQuestionCard> {
  static const _accent = Color(0xFFB98BFF); // fiolet — odróżnia pytanie od sugestii

  bool _answered = false;
  final Set<String> _selected = <String>{};

  Map<String, dynamic> get _raw => widget.block.raw;

  String get _question => (_raw['question'] ?? '').toString().trim();

  bool get _allowMultiple => _raw['allow_multiple'] == true;
  bool get _allowCustom => _raw['allow_custom'] != false; // domyślnie true

  String get _customHint {
    final h = (_raw['custom_hint'] ?? '').toString().trim();
    return h.isEmpty ? 'lub wpisz własną odpowiedź w polu poniżej' : h;
  }

  List<String> get _options {
    final raw = _raw['options'];
    if (raw is! List) return const <String>[];
    final out = <String>[];
    for (final o in raw) {
      String label;
      if (o is Map) {
        label = (o['label'] ?? o['id'] ?? '').toString().trim();
      } else {
        label = o.toString().trim();
      }
      if (label.isNotEmpty && !out.contains(label)) out.add(label);
    }
    return out;
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    ref.read(chatAiMessageProvider.notifier).sendMessage(trimmed);
  }

  void _onTapOption(String label) {
    if (_answered) return;

    if (_allowMultiple) {
      setState(() {
        if (!_selected.add(label)) _selected.remove(label);
      });
      return;
    }

    setState(() => _answered = true);
    _send(label);
  }

  void _sendMultiple() {
    if (_answered || _selected.isEmpty) return;
    setState(() => _answered = true);
    _send(_selected.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
              EmmaTag(label: 'Pytanie', color: _accent),
            ],
          ),
          if (_question.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _question,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in options)
                _OptionChip(
                  label: label,
                  selected: _selected.contains(label),
                  disabled: _answered,
                  accent: _accent,
                  multi: _allowMultiple,
                  onTap: () => _onTapOption(label),
                ),
            ],
          ),
          if (_allowMultiple && !_answered) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _sendMultiple,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text('Wyślij (${_selected.length})'),
            ),
          ],
          if (_allowCustom && !_answered) ...[
            const SizedBox(height: 10),
            Text(
              _customHint,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (_answered) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: _accent.withAlpha(200), size: 15),
                const SizedBox(width: 6),
                Text(
                  'Wybrano',
                  style:
                      TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final bool multi;
  final Color accent;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.multi,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected && multi;
    final bg = active ? accent.withAlpha(45) : Colors.white.withAlpha(12);
    final border = active ? accent.withAlpha(160) : Colors.white.withAlpha(30);
    final fg = disabled && !active
        ? Colors.white.withAlpha(90)
        : Colors.white.withAlpha(220);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                Icon(Icons.check_rounded, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
