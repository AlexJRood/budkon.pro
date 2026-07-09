import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';
import 'package:emma/provider/urls.dart';

class SuggestionInviteResponseBlockDefinition extends EmmaBlockDefinition {
  const SuggestionInviteResponseBlockDefinition();

  @override
  String get key => 'suggestion_invite_response';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.suggestionInviteResponse;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _SuggestionInviteResponseCard(block: block, maxWidth: maxWidth);
  }
}

class _SuggestionInviteResponseCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _SuggestionInviteResponseCard(
      {required this.block, required this.maxWidth});

  @override
  ConsumerState<_SuggestionInviteResponseCard> createState() =>
      _SuggestionInviteResponseCardState();
}

class _SuggestionInviteResponseCardState
    extends ConsumerState<_SuggestionInviteResponseCard> {
  bool _loading = false;
  bool _done = false;
  String? _chosenResponse;

  static const _accent = Color(0xFFAB47BC);

  String get _summary =>
      (widget.block.raw['summary'] ?? '').toString().trim();
  String get _recommendation =>
      (widget.block.raw['recommendation'] ?? '').toString().trim().toLowerCase();
  String get _reasoning =>
      (widget.block.raw['reasoning'] ?? '').toString().trim();

  void _showMsg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _accept(String response) async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _chosenResponse = response;
    });
    try {
      await ApiServices.post(
        URLsEmma.emmaProactiveAccept,
        data: {
          'type': 'suggestion_invite_response',
          'data': {
            ...widget.block.raw,
            'recommendation': response,
          },
        },
        hasToken: true,
      );
      if (!mounted) return;
      setState(() => _done = true);
      final label = switch (response) {
        'accept' => 'Zaproszenie przyjęte',
        'decline' => 'Zaproszenie odrzucone',
        _ => 'Odpowiedź wysłana',
      };
      _showMsg(label);
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
        data: {'type': 'suggestion_invite_response'},
        hasToken: true,
      );
    } catch (_) {}
    if (mounted) setState(() => _done = true);
  }

  Color _recommendationColor(String rec) {
    switch (rec) {
      case 'accept':
        return const Color(0xFF4CAF50);
      case 'decline':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFFB74D);
    }
  }

  String _recommendationLabel(String rec) {
    switch (rec) {
      case 'accept':
        return 'Rekomendacja: Przyjmij';
      case 'decline':
        return 'Rekomendacja: Odrzuć';
      default:
        return 'Rekomendacja: Może';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recColor = _recommendationColor(_recommendation);

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analiza zaproszenia',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EmmaTag(label: 'Zaproszenie', color: _accent),
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
          if (_recommendation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: recColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: recColor.withAlpha(60)),
              ),
              child: Text(
                _recommendationLabel(_recommendation),
                style: TextStyle(
                  color: recColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _reasoning,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_done)
            Text(
              _chosenResponse != null
                  ? _recommendationLabel(_chosenResponse!)
                  : 'Gotowe',
              style:
                  TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _loading ? null : () => _accept('accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: _loading && _chosenResponse == 'accept'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Przyjmij'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _accept('tentative'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB74D),
                    side: const BorderSide(color: Color(0xFFFFB74D)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Może'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _accept('decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF5350),
                    side: BorderSide(
                        color: const Color(0xFFEF5350).withAlpha(150)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Odrzuć'),
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
}
