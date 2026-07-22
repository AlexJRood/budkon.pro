import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Wyniki analizy zdjęcia placu budowy przez AI.
/// raw: budowa_id, budowa_nazwa, typ (postep|wada|material|bezpieczenstwo|inne),
///      opis, problemy (list<str>), rekomendacje (list<str>),
///      postep_procent (optional float), zdjecie_url (optional)
class AnalizaZdjeciaBlockDefinition extends EmmaBlockDefinition {
  const AnalizaZdjeciaBlockDefinition();

  @override
  String get key => 'analiza_zdjecia';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.analizaZdjecia;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _AnalizaZdjeciaCard(block: block, maxWidth: maxWidth);
}

class _AnalizaZdjeciaCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _AnalizaZdjeciaCard({required this.block, required this.maxWidth});

  Map<String, dynamic> get r => block.raw;

  String get _typ => (r['typ'] ?? 'inne').toString();
  String get _opis => (r['opis'] ?? '').toString();
  List<String> get _problemy =>
      List<String>.from(r['problemy'] ?? []);
  List<String> get _rekomendacje =>
      List<String>.from(r['rekomendacje'] ?? []);
  double? get _postepProcent =>
      r['postep_procent'] != null
          ? double.tryParse(r['postep_procent'].toString())
          : null;

  (String emoji, String label, Color color) get _typMeta => switch (_typ) {
        'postep' => ('📊', 'Postęp robót', const Color(0xFF4FC3F7)),
        'wada' => ('⚠️', 'Wada / usterka', const Color(0xFFFFB74D)),
        'bezpieczenstwo' => ('🦺', 'BHP', const Color(0xFFEF5350)),
        'material' => ('🧱', 'Materiał', const Color(0xFF81C784)),
        _ => ('📷', 'Analiza zdjęcia', const Color(0xFF90A4AE)),
      };

  @override
  Widget build(BuildContext context) {
    final (emoji, label, accent) = _typMeta;
    final maProblemy = _problemy.isNotEmpty;

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: maProblemy ? const Color(0xFFFFB74D) : accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            EmmaAccentIcon(icon: Icons.photo_camera_outlined, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                  Text('$emoji Analiza AI',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (maProblemy)
              EmmaTag(
                label: '${_problemy.length} prob.',
                color: const Color(0xFFFFB74D),
                icon: Icons.warning_amber,
              ),
          ]),

          if (_postepProcent != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Postęp robót',
                    style: TextStyle(
                        color: Colors.white.withAlpha(140), fontSize: 12)),
                Text('${_postepProcent!.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_postepProcent! / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],

          if (_opis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_opis,
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 13)),
          ],

          if (_problemy.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...(_problemy.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 13, color: Color(0xFFFFB74D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(p,
                            style: const TextStyle(
                                color: Color(0xFFFFB74D), fontSize: 12)),
                      ),
                    ],
                  ),
                ))),
          ],

          if (_rekomendacje.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...(_rekomendacje.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 13, color: Color(0xFF81C784)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(rec,
                            style: const TextStyle(
                                color: Color(0xFF81C784), fontSize: 12)),
                      ),
                    ],
                  ),
                ))),
          ],
        ],
      ),
    );
  }
}
