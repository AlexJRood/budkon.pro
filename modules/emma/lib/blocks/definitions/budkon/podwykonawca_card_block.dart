import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/block_definition.dart';
import '../../core/block_descriptor.dart';
import '../shared/block_ui.dart';

/// Karta szybkiego kontaktu z podwykonawcą.
/// raw: budowa_id, budowa_nazwa, kontrahent_id, powiazanie_id,
///      imie_nazwisko, firma, branza_emoji, branza_label,
///      telefon, email, status, rola, etap_nazwa
class PodwykonawcaCardBlockDefinition extends EmmaBlockDefinition {
  const PodwykonawcaCardBlockDefinition();

  @override
  String get key => 'podwykonawca_card';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.podwykonawcaCard;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) =>
      _PodwykonawcaCardWidget(block: block, maxWidth: maxWidth);
}

class _PodwykonawcaCardWidget extends StatelessWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;
  const _PodwykonawcaCardWidget(
      {required this.block, required this.maxWidth});

  static const _accent = Color(0xFF00BCD4);

  Map<String, dynamic> get r => block.raw;
  int? get _budowaId => r['budowa_id'] as int?;
  String get _budowaNazwa => (r['budowa_nazwa'] ?? 'Budowa').toString();
  String get _imieNazwisko =>
      (r['imie_nazwisko'] ?? 'Podwykonawca').toString();
  String get _firma => (r['firma'] ?? '').toString();
  String get _branzaEmoji => (r['branza_emoji'] ?? '🔨').toString();
  String get _branzaLabel => (r['branza_label'] ?? '').toString();
  String get _telefon => (r['telefon'] ?? '').toString();
  String get _status => (r['status'] ?? '').toString();
  String get _rola => (r['rola'] ?? '').toString();
  String get _etapNazwa => (r['etap_nazwa'] ?? '').toString();

  String get _initials {
    final parts = _imieNazwisko.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (_imieNazwisko.isNotEmpty) return _imieNazwisko[0].toUpperCase();
    return '?';
  }

  Color get _statusColor => switch (_status) {
        'aktywny' => const Color(0xFF4CAF50),
        'zaproszony' => const Color(0xFFFF9800),
        'zakonczony' => Colors.grey,
        'odrzucony' => Colors.red,
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
            // Avatar initials
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withAlpha(100)),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  color: _accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _imieNazwisko,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_firma.isNotEmpty && _firma != _imieNazwisko)
                    Text(
                      _firma,
                      style: TextStyle(
                          color: Colors.white.withAlpha(130), fontSize: 11),
                    ),
                  Text(
                    '$_branzaEmoji  $_branzaLabel',
                    style: TextStyle(
                        color: Colors.white.withAlpha(160), fontSize: 11),
                  ),
                ],
              ),
            ),

            EmmaTag(label: _status, color: _statusColor),
          ]),

          const SizedBox(height: 10),

          if (_rola.isNotEmpty || _etapNazwa.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                if (_rola.isNotEmpty) ...[
                  Icon(Icons.work_outline,
                      size: 13, color: Colors.white.withAlpha(120)),
                  const SizedBox(width: 4),
                  Text(
                    _rola,
                    style: TextStyle(
                        color: Colors.white.withAlpha(160), fontSize: 11),
                  ),
                ],
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
            ),

          Row(children: [
            Icon(Icons.domain,
                size: 13, color: Colors.white.withAlpha(100)),
            const SizedBox(width: 4),
            Text(
              _budowaNazwa,
              style:
                  TextStyle(color: Colors.white.withAlpha(130), fontSize: 11),
            ),
          ]),

          const SizedBox(height: 14),

          Wrap(spacing: 8, children: [
            if (_telefon.isNotEmpty)
              EmmaActionPill(
                label: _telefon,
                icon: Icons.phone_outlined,
                color: _accent,
                onTap: () {},
              ),
            EmmaActionPill(
              label: 'Szczegóły',
              icon: Icons.open_in_new,
              color: _accent,
              onTap: _budowaId != null
                  ? () => Navigator.of(context).pushNamed(
                        '/podwykonawcy',
                        arguments: {
                          'budowaId': _budowaId,
                          'budowaNazwa': _budowaNazwa,
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
