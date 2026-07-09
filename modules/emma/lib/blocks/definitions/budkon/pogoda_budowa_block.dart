import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// 3-dniowa prognoza pogody dla placu budowy.
/// raw: budowa_id, budowa_nazwa, lokalizacja,
///      prognozy: [{data, data_label, emoji, opis, temp_min, temp_max,
///                  opady_mm, wiatr_kmh, czy_mozna_pracowac}]
class PogodaBudowaBlockDefinition extends EmmaBlockDefinition {
  const PogodaBudowaBlockDefinition();

  @override
  String get key => 'pogoda_budowa';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.pogodaBudowa;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _PogodaBudowaCard(block: block, maxWidth: maxWidth);
}

class _PogodaBudowaCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _PogodaBudowaCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFF03A9F4);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  String get _lokalizacja => (r['lokalizacja'] ?? '').toString();
  List<dynamic> get _prognozy => r['prognozy'] as List? ?? [];

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(icon: Icons.wb_sunny_outlined, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pogoda na budowie',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _lokalizacja.isNotEmpty ? _lokalizacja : _budowaNazwa,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Prognoza 3-dniowa
          Row(
            children: _prognozy.take(3).map((p) {
              final m = p as Map;
              final emoji = (m['emoji'] ?? '🌤').toString();
              final label = (m['data_label'] ?? '').toString();
              final tempMax = (m['temp_max'] as num?)?.toInt() ?? 0;
              final tempMin = (m['temp_min'] as num?)?.toInt() ?? 0;
              final opadyMm = (m['opady_mm'] as num?)?.toDouble() ?? 0;
              final wiatr = (m['wiatr_kmh'] as num?)?.toInt() ?? 0;
              final mozna = m['czy_mozna_pracowac'] as bool? ?? true;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: mozna
                        ? Colors.white.withAlpha(10)
                        : Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: mozna
                          ? Colors.white.withAlpha(20)
                          : Colors.red.withAlpha(60),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10),
                      ),
                      const SizedBox(height: 6),
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        '$tempMax°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$tempMin°',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      if (opadyMm > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                size: 10, color: Colors.lightBlue),
                            const SizedBox(width: 2),
                            Text(
                              '${opadyMm.toStringAsFixed(0)}mm',
                              style: const TextStyle(
                                  color: Colors.lightBlue, fontSize: 9),
                            ),
                          ],
                        ),
                      if (wiatr > 20)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.air,
                                size: 10, color: Colors.white38),
                            const SizedBox(width: 2),
                            Text(
                              '$wiatr km/h',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      if (!mozna) ...[
                        const SizedBox(height: 4),
                        const Icon(Icons.warning_amber,
                            size: 12, color: Colors.orange),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline,
                  size: 11, color: Colors.white.withAlpha(80)),
              const SizedBox(width: 4),
              Text(
                'Źródło: Open-Meteo',
                style: TextStyle(
                    color: Colors.white.withAlpha(80), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
