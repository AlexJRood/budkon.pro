import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Karta aktywnej budowy na dashboardzie.
/// raw: budowa_id, budowa_nazwa, etap_nazwa, etap_typ, postep_procent,
///      data_planowana, budzet, status
class BudowaStatusBlockDefinition extends EmmaBlockDefinition {
  const BudowaStatusBlockDefinition();

  @override
  String get key => 'budowa_status';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.budowaStatus;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _BudowaStatusCard(block: block, maxWidth: maxWidth);
}

class _BudowaStatusCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _BudowaStatusCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFF2196F3);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  String get _nazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  String get _etap => (r['etap_nazwa'] ?? '').toString();
  int get _postep => (r['postep_procent'] as num?)?.toInt() ?? 0;
  String get _status => (r['status'] ?? '').toString();
  String get _dataKoniec => (r['data_planowana'] ?? '').toString();
  double? get _budzet => (r['budzet'] as num?)?.toDouble();

  String get _budzetStr {
    final b = _budzet;
    if (b == null) return '';
    if (b >= 1000000) return '${(b / 1000000).toStringAsFixed(1)} mln PLN';
    if (b >= 1000) return '${(b / 1000).toStringAsFixed(0)} tys. PLN';
    return '${b.toStringAsFixed(0)} PLN';
  }

  Color get _statusColor => switch (_status) {
        'w_toku' => const Color(0xFF4CAF50),
        'oferta' => const Color(0xFFFF9800),
        'zakonczona' => Colors.grey,
        _ => _accent,
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
            EmmaAccentIcon(icon: Icons.domain, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _nazwa,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            EmmaTag(
              label: _status.replaceAll('_', ' '),
              color: _statusColor,
            ),
          ]),

          if (_etap.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.construction,
                  size: 13, color: Colors.white.withAlpha(130)),
              const SizedBox(width: 5),
              Text(
                _etap,
                style: TextStyle(
                    color: Colors.white.withAlpha(170), fontSize: 12),
              ),
            ]),
          ],

          const SizedBox(height: 12),

          // Pasek postępu
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _postep / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withAlpha(20),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$_postep%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),

          const SizedBox(height: 10),

          Row(children: [
            if (_dataKoniec.isNotEmpty) ...[
              Icon(Icons.flag_outlined,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                _dataKoniec,
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 11),
              ),
              const SizedBox(width: 16),
            ],
            if (_budzetStr.isNotEmpty) ...[
              Icon(Icons.account_balance_wallet_outlined,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                _budzetStr,
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 11),
              ),
            ],
          ]),

          const SizedBox(height: 14),

          Wrap(spacing: 8, children: [
            EmmaActionPill(
              label: 'Dziennik',
              icon: Icons.book_outlined,
              color: _accent,
              onTap: _budowaId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/dziennik',
                        arguments: {
                          'budowaId': _budowaId,
                          'budowaNazwa': _nazwa,
                        },
                      )
                  : null,
            ),
            EmmaActionPill(
              label: 'Harmonogram',
              icon: Icons.calendar_month_outlined,
              color: _accent,
              onTap: _budowaId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/harmonogram',
                        arguments: {
                          'budowaId': _budowaId,
                          'budowaNazwa': _nazwa,
                        },
                      )
                  : null,
            ),
          ]),
        ],
      ),
    );
  }
}
