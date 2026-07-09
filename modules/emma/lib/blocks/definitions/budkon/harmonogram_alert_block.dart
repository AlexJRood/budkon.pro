import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Alert o opóźnionym zadaniu w harmonogramie.
/// raw: budowa_id, budowa_nazwa, zadanie_id, zadanie_nazwa,
///      opoznienie_dni, data_koniec, postep_procent, status
class HarmonogramAlertBlockDefinition extends EmmaBlockDefinition {
  const HarmonogramAlertBlockDefinition();

  @override
  String get key => 'harmonogram_alert';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.harmonogramAlert;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _HarmonogramAlertCard(block: block, maxWidth: maxWidth);
}

class _HarmonogramAlertCard extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _HarmonogramAlertCard(
      {required this.block, required this.maxWidth});

  static const _accent = Color(0xFFFF5722);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  int? get _zadanieId => r['zadanie_id'] as int?;
  String get _zadanieNazwa =>
      (r['zadanie_nazwa'] ?? 'Zadanie').toString();
  int get _opoznienieDni => (r['opoznienie_dni'] as num?)?.toInt() ?? 0;
  String get _dataKoniec => (r['data_koniec'] ?? '').toString();
  int get _postep => (r['postep_procent'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            EmmaAccentIcon(icon: Icons.warning_amber_rounded, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Opóźnienie w harmonogramie',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _zadanieNazwa,
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
              label: '+$_opoznienieDni dni',
              color: _accent,
              icon: Icons.timer_off_outlined,
            ),
          ]),

          const SizedBox(height: 10),

          Row(children: [
            Icon(Icons.domain,
                size: 13, color: Colors.white.withAlpha(120)),
            const SizedBox(width: 4),
            Text(
              _budowaNazwa,
              style:
                  TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
            ),
            const SizedBox(width: 16),
            if (_dataKoniec.isNotEmpty) ...[
              Icon(Icons.event_outlined,
                  size: 13, color: Colors.white.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                'Do: $_dataKoniec',
                style: TextStyle(
                    color: Colors.white.withAlpha(160), fontSize: 11),
              ),
            ],
          ]),

          const SizedBox(height: 10),

          // Progress
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _postep / 100,
                  minHeight: 5,
                  backgroundColor: Colors.white.withAlpha(20),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_postep%',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11),
            ),
          ]),

          const SizedBox(height: 14),

          EmmaActionPill(
            label: 'Zaktualizuj postęp',
            icon: Icons.update,
            color: _accent,
            onTap: (_budowaId != null && _zadanieId != null)
                ? () => Navigator.of(context).pushNamed(
                      '/harmonogram',
                      arguments: {
                        'budowaId': _budowaId,
                        'budowaNazwa': _budowaNazwa,
                        'highlightZadanieId': _zadanieId,
                      },
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
