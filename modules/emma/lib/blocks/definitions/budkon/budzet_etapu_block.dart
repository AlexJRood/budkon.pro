import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class BudzetEtapuBlockDefinition extends EmmaBlockDefinition {
  const BudzetEtapuBlockDefinition();

  @override
  String get key => 'budzet_etapu';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.budzetEtapu;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final data = block.raw;
    final nazwaEtapu = data['etap_nazwa']?.toString() ?? 'Etap';
    final budzet = (data['budzet'] as num?)?.toDouble() ?? 0;
    final wydano = (data['wydano'] as num?)?.toDouble() ?? 0;
    final procent = budzet > 0 ? (wydano / budzet).clamp(0.0, 1.0) : 0.0;
    final pozostalo = budzet - wydano;
    final przekroczony = wydano > budzet;

    const baseAccent = Color(0xFF42A5F5);
    final barColor = przekroczony
        ? Colors.redAccent
        : procent > 0.85
            ? Colors.orange
            : baseAccent;

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: barColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const EmmaAccentIcon(icon: Icons.account_balance_wallet_outlined, color: baseAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Budżet etapu',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            EmmaTag(
              label: przekroczony
                  ? '⚠ Przekroczony!'
                  : '${(procent * 100).toStringAsFixed(0)}% wydane',
              color: barColor,
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            nazwaEtapu,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
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
              style: TextStyle(
                  color: barColor, fontWeight: FontWeight.w700, fontSize: 12),
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
                  ? '-${_fmt(pozostalo.abs())} zł'
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
            EmmaActionPill(
              label: 'Kosztorys',
              icon: Icons.calculate_outlined,
              onTap: null,
            ),
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

