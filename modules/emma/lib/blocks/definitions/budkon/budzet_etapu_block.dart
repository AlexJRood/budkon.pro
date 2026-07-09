import 'package:flutter/material.dart';
import '../../core/block_descriptor.dart';
import '../../core/block_definition.dart';
import '../../widgets/emma_block_card_shell.dart';

class BudzetEtapuBlockDefinition extends EmmaBlockDefinition {
  const BudzetEtapuBlockDefinition()
      : super(
          type: EmmaBlockDescriptor.budzetEtapu,
          title: 'Budżet etapu',
          description: 'Wydatki vs budżet aktualnego etapu',
          iconCodePoint: 0xe862, // account_balance_wallet
          color: Color(0xFF42A5F5),
        );

  @override
  Widget buildCard(BuildContext context, Map<String, dynamic> data) =>
      _BudzetEtapuCard(data: data);
}

class _BudzetEtapuCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BudzetEtapuCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final nazwaEtapu = data['etap_nazwa'] as String? ?? 'Etap';
    final budzet = (data['budzet'] as num?)?.toDouble() ?? 0;
    final wydano = (data['wydano'] as num?)?.toDouble() ?? 0;
    final procent = budzet > 0 ? (wydano / budzet).clamp(0.0, 1.0) : 0.0;
    final pozostalo = budzet - wydano;
    final przekroczony = wydano > budzet;

    final barColor = przekroczony
        ? Colors.redAccent
        : procent > 0.85
            ? Colors.orange
            : const Color(0xFF42A5F5);

    return EmmaBlockCardShell(
      title: 'Budżet etapu',
      accent: const Color(0xFF42A5F5),
      tag: EmmaTag(
        label: przekroczony
            ? '⚠ Przekroczony!'
            : '${(procent * 100).toStringAsFixed(0)}% wydane',
        color: barColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nazwaEtapu,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Pasek
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: procent,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),

          Row(children: [
            Text(
              '${_fmt(wydano)} zł',
              style:
                  TextStyle(color: barColor, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const Text(' / ',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(
              '${_fmt(budzet)} zł',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Spacer(),
            Text(
              przekroczony
                  ? '−${_fmt(pozostalo.abs())} zł'
                  : '${_fmt(pozostalo)} zł wolne',
              style: TextStyle(
                color: przekroczony ? Colors.redAccent : Colors.white54,
                fontSize: 11,
              ),
            ),
          ]),

          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            EmmaActionPill(label: 'Kosztorys', route: '/kosztorysy'),
          ]),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
