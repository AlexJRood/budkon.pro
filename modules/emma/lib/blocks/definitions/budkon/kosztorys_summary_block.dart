import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Podsumowanie kosztorysu z rozbiciem na etapy.
/// raw: budowa_id, budowa_nazwa, kosztorys_id, kosztorys_nazwa,
///      total_netto, total_brutto, waluta, etapy: [{nazwa, wartosc, procent}],
///      status (roboczy/wyslany/zaakceptowany)
class KosztorysSummaryBlockDefinition extends EmmaBlockDefinition {
  const KosztorysSummaryBlockDefinition();

  @override
  String get key => 'kosztorys_summary';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.kosztorysSummary;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _KosztorysSummaryCard(block: block, maxWidth: maxWidth);
}

class _KosztorysSummaryCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _KosztorysSummaryCard(
      {required this.block, required this.maxWidth});

  static const _accent = Color(0xFF9C27B0);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  int? get _kosztorysId => r['kosztorys_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  String get _kosztorysNazwa =>
      (r['kosztorys_nazwa'] ?? 'Kosztorys').toString();
  double get _totalNetto =>
      (r['total_netto'] as num?)?.toDouble() ?? 0;
  double get _totalBrutto =>
      (r['total_brutto'] as num?)?.toDouble() ?? 0;
  String get _waluta => (r['waluta'] ?? 'PLN').toString();
  String get _status => (r['status'] ?? 'roboczy').toString();
  List<dynamic> get _etapy => r['etapy'] as List? ?? [];

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} mln $_waluta';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} tys. $_waluta';
    return '${v.toStringAsFixed(0)} $_waluta';
  }

  Color get _statusColor => switch (_status) {
        'zaakceptowany' => const Color(0xFF4CAF50),
        'wyslany' => const Color(0xFF2196F3),
        _ => Colors.white38,
      };

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(
                icon: Icons.receipt_long_outlined, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _budowaNazwa,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _kosztorysNazwa,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            EmmaTag(
              label: _status,
              color: _statusColor,
            ),
          ]),

          const SizedBox(height: 14),

          // Kwota główna
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _fmt(_totalBrutto),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'brutto',
                style:
                    TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
              ),
              const SizedBox(width: 16),
              Text(
                _fmt(_totalNetto),
                style:
                    TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
              ),
              const SizedBox(width: 4),
              Text(
                'netto',
                style:
                    TextStyle(color: Colors.white.withAlpha(100), fontSize: 11),
              ),
            ],
          ),

          if (_etapy.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._etapy.take(4).map((e) {
              final m = e as Map;
              final procent = (m['procent'] as num?)?.toDouble() ?? 0;
              final wartosc = (m['wartosc'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      (m['nazwa'] ?? '').toString(),
                      style: TextStyle(
                          color: Colors.white.withAlpha(160),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: procent / 100,
                        minHeight: 4,
                        backgroundColor: Colors.white.withAlpha(15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                                _accent.withAlpha(180)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(wartosc),
                    style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 11),
                  ),
                ]),
              );
            }),
          ],

          const SizedBox(height: 14),

          Wrap(spacing: 8, children: [
            EmmaActionPill(
              label: 'Wyślij ofertę',
              icon: Icons.send_outlined,
              color: _accent,
              onTap: (_kosztorysId != null)
                  ? () => Navigator.of(context).pushNamed(
                        '/kosztorysy/wyslij',
                        arguments: {
                          'kosztorysId': _kosztorysId,
                          'budowaId': _budowaId,
                        },
                      )
                  : null,
            ),
            EmmaActionPill(
              label: 'Otwórz',
              icon: Icons.open_in_new,
              color: _accent,
              onTap: _kosztorysId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/kosztorysy/detail',
                        arguments: {'kosztorysId': _kosztorysId},
                      )
                  : null,
            ),
          ]),
        ],
      ),
    );
  }
}
