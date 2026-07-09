import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Przypomnienie o brakującym wpisie dziennika budowy.
/// raw: budowa_id, budowa_nazwa, ostatni_wpis_data, dni_bez_wpisu,
///      dzis_pogoda, etap_nazwa
class WpisDziennikBlockDefinition extends EmmaBlockDefinition {
  const WpisDziennikBlockDefinition();

  @override
  String get key => 'wpis_dziennik';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.wpisDziennik;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _WpisDziennikCard(block: block, maxWidth: maxWidth);
}

class _WpisDziennikCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _WpisDziennikCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFF8BC34A);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  int get _dniBezWpisu =>
      (r['dni_bez_wpisu'] as num?)?.toInt() ?? 0;
  String get _ostatniWpisData =>
      (r['ostatni_wpis_data'] ?? '').toString();
  String get _dzisPogoda => (r['dzis_pogoda'] ?? '').toString();
  String get _etapNazwa => (r['etap_nazwa'] ?? '').toString();

  String get _komunikat {
    if (_dniBezWpisu == 0) return 'Uzupełnij dzisiejszy wpis';
    if (_dniBezWpisu == 1) return 'Wczoraj nie było wpisu';
    return 'Brak wpisu od $_dniBezWpisu dni';
  }

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(icon: Icons.book_outlined, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dziennik budowy',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _komunikat,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (_dniBezWpisu > 0)
              EmmaTag(
                label: '$_dniBezWpisu d',
                color: _dniBezWpisu > 2 ? Colors.red : Colors.orange,
                icon: Icons.schedule,
              ),
          ]),

          const SizedBox(height: 10),

          Row(children: [
            Icon(Icons.domain, size: 13, color: Colors.white.withAlpha(120)),
            const SizedBox(width: 4),
            Text(
              _budowaNazwa,
              style: TextStyle(
                  color: Colors.white.withAlpha(160), fontSize: 11),
            ),
            if (_etapNazwa.isNotEmpty) ...[
              const SizedBox(width: 12),
              Icon(Icons.construction,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                _etapNazwa,
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 11),
              ),
            ],
          ]),

          if (_dzisPogoda.isNotEmpty || _ostatniWpisData.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (_dzisPogoda.isNotEmpty) ...[
                Text(_dzisPogoda,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
              ],
              if (_ostatniWpisData.isNotEmpty)
                Text(
                  'Ostatni: $_ostatniWpisData',
                  style: TextStyle(
                      color: Colors.white.withAlpha(130), fontSize: 11),
                ),
            ]),
          ],

          const SizedBox(height: 14),

          EmmaActionPill(
            label: 'Dodaj wpis',
            icon: Icons.add,
            color: _accent,
            onTap: _budowaId != null
                ? () => Navigator.of(context).pushNamed(
                      '/dziennik/form',
                      arguments: {
                        'budowaId': _budowaId,
                        'budowaNazwa': _budowaNazwa,
                      },
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
