import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class AktywenBudowyBlockDefinition extends EmmaBlockDefinition {
  const AktywenBudowyBlockDefinition();

  @override
  String get key => 'aktywne_budowy';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.aktywenBudowy;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final data = block.raw;
    final budowy = (data['budowy'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final ilosc = budowy.length;

    const accent = Color(0xFF78909C);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const EmmaAccentIcon(icon: Icons.home_work_outlined, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aktywne budowy',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            EmmaTag(label: '$ilosc aktywne', color: accent),
          ]),
          const SizedBox(height: 8),
          ...budowy.take(3).map((b) {
            final nazwa = b['nazwa']?.toString() ?? '';
            final postep = b['postep'] as int? ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        nazwa,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$postep%',
                      style: const TextStyle(
                          color: accent, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: postep / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (ilosc > 3)
            Text(
              '+${ilosc - 3} więcej',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            EmmaActionPill(
              label: 'Wszystkie budowy',
              icon: Icons.arrow_forward_outlined,
              onTap: null,
            ),
          ]),
        ],
      ),
    );
  }
}

