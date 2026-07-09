import 'package:flutter/material.dart';
import '../../core/block_descriptor.dart';
import '../../core/block_definition.dart';
import '../../widgets/emma_block_card_shell.dart';

class AktywenBudowyBlockDefinition extends EmmaBlockDefinition {
  const AktywenBudowyBlockDefinition()
      : super(
          type: EmmaBlockDescriptor.aktywenBudowy,
          title: 'Aktywne budowy',
          description: 'Przegląd wszystkich aktywnych budów z postępem',
          iconCodePoint: 0xea3b, // home_work
          color: Color(0xFF78909C),
        );

  @override
  Widget buildCard(BuildContext context, Map<String, dynamic> data) =>
      _AktywenBudowyCard(data: data);
}

class _AktywenBudowyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AktywenBudowyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final budowy = (data['budowy'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final ilosc = budowy.length;

    return EmmaBlockCardShell(
      title: 'Aktywne budowy',
      accent: const Color(0xFF78909C),
      tag: EmmaTag(label: '$ilosc aktywne', color: const Color(0xFF78909C)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...budowy.take(3).map((b) {
            final nazwa = b['nazwa'] as String? ?? '';
            final postep = b['postep'] as int? ?? 0;
            final status = b['status'] as String? ?? '';
            final budowaId = b['id'] as int? ?? 0;

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
                          color: Color(0xFF78909C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: postep / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF78909C)),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (ilosc > 3)
            Text(
              '+${ilosc - 3} więcej',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            EmmaActionPill(label: 'Wszystkie budowy', route: '/budowa'),
          ]),
        ],
      ),
    );
  }
}
