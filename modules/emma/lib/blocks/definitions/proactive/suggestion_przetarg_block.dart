import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Block Emmy renderowany gdy Superbee zwróci typ 'suggestion_przetarg'.
/// Dane w block.raw:
///   przetarg_id, przetarg_tytul, przetarg_wartosc, przetarg_ai_score,
///   przetarg_lokalizacja, przetarg_termin_skladania, tekst, kosztorys_id,
///   emma_wiadomosc_id (do accept/dismiss na budkon API)
class SuggestionPrzetargBlockDefinition extends EmmaBlockDefinition {
  const SuggestionPrzetargBlockDefinition();

  @override
  String get key => 'suggestion_przetarg';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.suggestionPrzetarg;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _SuggestionPrzetargCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _SuggestionPrzetargCard extends ConsumerStatefulWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _SuggestionPrzetargCard({
    required this.block,
    required this.maxWidth,
  });

  @override
  ConsumerState<_SuggestionPrzetargCard> createState() =>
      _SuggestionPrzetargCardState();
}

class _SuggestionPrzetargCardState
    extends ConsumerState<_SuggestionPrzetargCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _done = false;
  bool _loading = false;

  static const _accent = Color(0xFFFF9800); // pomarańczowy — budowlanka

  Map<String, dynamic> get _raw => widget.block.raw;

  int? get _przetargId => _raw['przetarg_id'] as int?;
  int? get _kosztorysId => _raw['kosztorys_id'] as int?;
  int? get _emmaWiadomoscId => _raw['emma_wiadomosc_id'] as int?;
  String get _tytul => (_raw['przetarg_tytul'] ?? '').toString();
  String get _tekst => (_raw['tekst'] ?? '').toString();
  String get _lokalizacja => (_raw['przetarg_lokalizacja'] ?? '').toString();
  int? get _score => _raw['przetarg_ai_score'] as int?;

  String get _wartosc {
    final w = _raw['przetarg_wartosc'];
    if (w == null) return '';
    final d = double.tryParse(w.toString());
    if (d == null) return '';
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)} mln PLN';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)} tys. PLN';
    return '${d.toStringAsFixed(0)} PLN';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return EmmaBlockCardShell(
      maxWidth: widget.maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek
          Row(
            children: [
              Icon(Icons.find_in_page_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nowy przetarg',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_score != null)
                EmmaTag(
                  label: '$_score / 100',
                  color: _score! >= 70
                      ? const Color(0xFF4CAF50)
                      : _score! >= 45
                          ? _accent
                          : Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Tekst Emmy
          if (_tekst.isNotEmpty)
            Text(
              _tekst,
              style: TextStyle(
                color: Colors.white.withAlpha(190),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 10),

          // Tytuł przetargu
          Text(
            _tytul,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),

          // Meta
          const SizedBox(height: 6),
          if (_wartosc.isNotEmpty)
            _MetaRow(
              icon: Icons.payments_outlined,
              text: _wartosc,
            ),
          if (_lokalizacja.isNotEmpty)
            _MetaRow(
              icon: Icons.location_on_outlined,
              text: _lokalizacja,
            ),

          const SizedBox(height: 16),

          // Akcje
          if (_done)
            Text(
              'Dziękuję za odpowiedź.',
              style: TextStyle(
                  color: Colors.white.withAlpha(150), fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_kosztorysId != null)
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _navigate('/kosztorysy/$_kosztorysId'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.calculate_outlined, size: 16),
                    label: const Text('Otwórz kosztorys'),
                  ),
                if (_przetargId != null)
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => _navigate('/przetargi/$_przetargId'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withAlpha(200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                    child: const Text('Szczegóły przetargu'),
                  ),
                TextButton(
                  onPressed: _loading ? null : _dismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withAlpha(100),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  child: const Text('Odrzuć'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _navigate(String route) {
    Navigator.of(context).pushNamed(route);
    _accept();
  }

  Future<void> _accept() async {
    if (_emmaWiadomoscId == null) return;
    try {
      await _budkonDio().post('/emma-inbox/$_emmaWiadomoscId/akceptuj/');
    } catch (_) {}
    if (mounted) setState(() => _done = true);
  }

  Future<void> _dismiss() async {
    setState(() => _loading = true);
    try {
      if (_emmaWiadomoscId != null) {
        await _budkonDio().post('/emma-inbox/$_emmaWiadomoscId/odrzuc/');
      }
    } catch (_) {}
    if (mounted) setState(() {
      _done = true;
      _loading = false;
    });
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white.withAlpha(130)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white.withAlpha(170), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Lokalny Dio do budkon backend (port 8001)
Dio _budkonDio() => Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:8001/api/v1',
      headers: {'X-Company-Id': '1'},
    ));
