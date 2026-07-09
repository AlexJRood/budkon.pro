import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Przetarg kończący się wkrótce.
/// raw: przetarg_id, nazwa, numer, inwestor, lokalizacja,
///      data_otwarcia, dni_do_konca, wartosc_szacowana,
///      status (aktywny/wygasajacy/archiwum), url
class PrzetargDeadlineBlockDefinition extends EmmaBlockDefinition {
  const PrzetargDeadlineBlockDefinition();

  @override
  String get key => 'przetarg_deadline';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.przetargDeadline;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _PrzetargDeadlineCard(block: block, maxWidth: maxWidth);
}

class _PrzetargDeadlineCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _PrzetargDeadlineCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFFFF9800);

  Map<String, dynamic> get r => block.raw;
  int? get _przetargId => r['przetarg_id'] as int?;
  String get _nazwa => (r['nazwa'] ?? 'Przetarg').toString();
  String get _numer => (r['numer'] ?? '').toString();
  String get _inwestor => (r['inwestor'] ?? '').toString();
  String get _lokalizacja => (r['lokalizacja'] ?? '').toString();
  String get _dataOtwarcia => (r['data_otwarcia'] ?? '').toString();
  int get _dniDoKonca => (r['dni_do_konca'] as num?)?.toInt() ?? 0;
  double? get _wartoscSzacowana =>
      (r['wartosc_szacowana'] as num?)?.toDouble();

  bool get _pilny => _dniDoKonca <= 3;

  String get _dniLabel {
    if (_dniDoKonca == 0) return 'Dziś!';
    if (_dniDoKonca == 1) return 'Jutro';
    return '$_dniDoKonca dni';
  }

  String? get _wartoscStr {
    final w = _wartoscSzacowana;
    if (w == null) return null;
    if (w >= 1000000) return '~${(w / 1000000).toStringAsFixed(1)} mln PLN';
    if (w >= 1000) return '~${(w / 1000).toStringAsFixed(0)} tys. PLN';
    return '~${w.toStringAsFixed(0)} PLN';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _pilny ? Colors.red : _accent;

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(
                icon: Icons.gavel_outlined, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_numer.isNotEmpty)
                    Text(
                      _numer,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  Text(
                    _nazwa,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            EmmaTag(
              label: _dniLabel,
              color: accentColor,
              icon: _pilny ? Icons.alarm : Icons.timer_outlined,
            ),
          ]),

          const SizedBox(height: 10),

          if (_inwestor.isNotEmpty)
            Row(children: [
              Icon(Icons.business_outlined,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _inwestor,
                  style: TextStyle(
                      color: Colors.white.withAlpha(160), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),

          if (_lokalizacja.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.place_outlined,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                _lokalizacja,
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 11),
              ),
            ]),
          ],

          if (_dataOtwarcia.isNotEmpty || _wartoscStr != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (_dataOtwarcia.isNotEmpty) ...[
                Icon(Icons.event,
                    size: 13, color: Colors.white.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  _dataOtwarcia,
                  style: TextStyle(
                      color: Colors.white.withAlpha(160), fontSize: 11),
                ),
                const SizedBox(width: 16),
              ],
              if (_wartoscStr != null) ...[
                Icon(Icons.account_balance_wallet_outlined,
                    size: 13, color: Colors.white.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  _wartoscStr!,
                  style: TextStyle(
                      color: Colors.white.withAlpha(160), fontSize: 11),
                ),
              ],
            ]),
          ],

          const SizedBox(height: 14),

          Wrap(spacing: 8, children: [
            EmmaActionPill(
              label: 'Przygotuj ofertę',
              icon: Icons.description_outlined,
              color: accentColor,
              onTap: _przetargId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/przetargi/detail',
                        arguments: {'przetargId': _przetargId},
                      )
                  : null,
            ),
            EmmaActionPill(
              label: 'Kosztorys',
              icon: Icons.receipt_long_outlined,
              color: accentColor,
              onTap: _przetargId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/kosztorysy/new',
                        arguments: {'przetargId': _przetargId},
                      )
                  : null,
            ),
          ]),
        ],
      ),
    );
  }
}
