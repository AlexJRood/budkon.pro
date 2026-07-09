import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Lista materiałów do zamówienia z kosztorysu.
/// raw: budowa_id, budowa_nazwa, kosztorys_id, etap_nazwa,
///      materialy: [{nazwa, ilosc, jednostka, cena_netto, zamowiony}],
///      total_netto, pilnosc (normalny/pilny/krytyczny)
class MaterialyListaBlockDefinition extends EmmaBlockDefinition {
  const MaterialyListaBlockDefinition();

  @override
  String get key => 'materialy_lista';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.materialyLista;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _MaterialyListaCard(block: block, maxWidth: maxWidth);
}

class _MaterialyListaCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _MaterialyListaCard({required this.block, required this.maxWidth});

  static const _accent = Color(0xFF607D8B);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  int? get _kosztorysId => r['kosztorys_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  String get _etapNazwa => (r['etap_nazwa'] ?? '').toString();
  String get _pilnosc => (r['pilnosc'] ?? 'normalny').toString();
  List<dynamic> get _materialy => r['materialy'] as List? ?? [];
  double get _totalNetto =>
      (r['total_netto'] as num?)?.toDouble() ?? 0;

  Color get _pilnoscColor => switch (_pilnosc) {
        'krytyczny' => Colors.red,
        'pilny' => Colors.orange,
        _ => _accent,
      };

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} tys. PLN';
    return '${v.toStringAsFixed(0)} PLN';
  }

  @override
  Widget build(BuildContext context) {
    final niezamowione =
        _materialy.where((m) => !(m as Map)['zamowiony']).toList();

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _pilnoscColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(
                icon: Icons.inventory_2_outlined, color: _pilnoscColor),
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
                    'Materiały do zamówienia${_etapNazwa.isNotEmpty ? ' – $_etapNazwa' : ''}',
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
              label: '${niezamowione.length} poz.',
              color: _pilnoscColor,
              icon: _pilnosc != 'normalny'
                  ? Icons.priority_high
                  : null,
            ),
          ]),

          if (_totalNetto > 0) ...[
            const SizedBox(height: 8),
            Text(
              _fmt(_totalNetto),
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Lista materiałów (max 5)
          ...niezamowione.take(5).map((m) {
            final mat = m as Map;
            final nazwa = (mat['nazwa'] ?? '').toString();
            final ilosc = (mat['ilosc'] as num?)?.toDouble() ?? 0;
            final jednostka = (mat['jednostka'] ?? 'szt').toString();
            final cenaNetto =
                (mat['cena_netto'] as num?)?.toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: _pilnoscColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    nazwa,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${ilosc % 1 == 0 ? ilosc.toInt() : ilosc} $jednostka',
                  style: TextStyle(
                      color: Colors.white.withAlpha(160), fontSize: 11),
                ),
                if (cenaNetto != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _fmt(cenaNetto * ilosc),
                    style: TextStyle(
                        color: Colors.white.withAlpha(120), fontSize: 10),
                  ),
                ],
              ]),
            );
          }),

          if (niezamowione.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${niezamowione.length - 5} więcej...',
                style: TextStyle(
                    color: Colors.white.withAlpha(100), fontSize: 11),
              ),
            ),

          const SizedBox(height: 14),

          Wrap(spacing: 8, children: [
            EmmaActionPill(
              label: 'Zamów',
              icon: Icons.shopping_cart_outlined,
              color: _pilnoscColor,
              onTap: _kosztorysId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/materialy',
                        arguments: {
                          'kosztorysId': _kosztorysId,
                          'budowaId': _budowaId,
                        },
                      )
                  : null,
            ),
            EmmaActionPill(
              label: 'Kosztorys',
              icon: Icons.receipt_long_outlined,
              color: _pilnoscColor,
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
