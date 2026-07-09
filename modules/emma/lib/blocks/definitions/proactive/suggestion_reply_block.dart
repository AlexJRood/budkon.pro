import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';
import 'package:emma/provider/urls.dart';

class SuggestionReplyBlockDefinition extends EmmaBlockDefinition {
  const SuggestionReplyBlockDefinition();

  @override
  String get key => 'suggestion_reply';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.suggestionReply;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _SuggestionReplyCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _SuggestionReplyCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _SuggestionReplyCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_SuggestionReplyCard> createState() =>
      _SuggestionReplyCardState();
}

class _SuggestionReplyCardState extends ConsumerState<_SuggestionReplyCard> {
  bool _loading = false;
  bool _done = false;

  static const _accent = Color(0xFF37B6FF);

  String get _summary =>
      (widget.block.raw['summary'] ?? '').toString().trim();

  Map<String, dynamic> get _draft {
    final d = widget.block.raw['draft'];
    return d is Map ? Map<String, dynamic>.from(d) : {};
  }

  String get _to {
    final t = _draft['to'];
    if (t is List) return t.join(', ');
    return t?.toString() ?? '';
  }

  String get _subject => (_draft['subject'] ?? '').toString();
  String get _body => (_draft['body'] ?? '').toString();

  void _showMsg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _accept(String mode) async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_reply',
          'data': widget.block.raw,
          'mode': mode,
        },
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      _showMsg(mode == 'send'
          ? 'Odpowiedź wysłana'
          : 'Wersja robocza zapisana');
    } catch (e) {
      if (!mounted) return;
      _showMsg('Błąd: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dismiss() async {
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveDismiss,
        data: {'type': 'suggestion_reply'},
        hasToken: true,
      );
    } catch (_) {}
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugerowana odpowiedź',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EmmaTag(label: 'Odpowiedź', color: _accent),
            ],
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _summary,
              style: TextStyle(
                color: Colors.white.withAlpha(190),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (_to.isNotEmpty || _subject.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_to.isNotEmpty)
                    _infoRow('Do: ', _to),
                  if (_subject.isNotEmpty)
                    _infoRow('Temat: ', _subject),
                  if (_body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _body,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(170),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_done)
            Text(
              'Gotowe',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _loading ? null : () => _accept('send'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Wyślij'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _accept('draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(40)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edytuj'),
                ),
                TextButton(
                  onPressed: _loading ? null : _dismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withAlpha(140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  child: const Text('Nie teraz'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 11, height: 1.35),
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Colors.white.withAlpha(200)),
            ),
          ],
        ),
      ),
    );
  }
}
