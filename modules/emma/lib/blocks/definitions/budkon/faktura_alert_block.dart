import 'package:flutter/material.dart';
import '../../core/block_descriptor.dart';
import '../../core/block_definition.dart';
import '../../core/block_registry.dart';
import '../../widgets/emma_block_card_shell.dart';

class FakturaAlertBlockDefinition extends EmmaBlockDefinition {
  const FakturaAlertBlockDefinition()
      : super(
          type: EmmaBlockDescriptor.fakturaAlert,
          title: 'Faktura do wystawienia',
          description: 'Alert o oczekujących fakturach VAT',
          iconCodePoint: 0xe237, // receipt_long
          color: Color(0xFF26A69A),
        );

  @override
  Widget buildCard(BuildContext context, Map<String, dynamic> data) =>
      _FakturaAlertCard(data: data);
}

class _FakturaAlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FakturaAlertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ilosc = data['ilosc_oczekujacych'] as int? ?? 0;
    final nastepna = data['nastepna_nazwa'] as String? ?? 'Faktura';
    final kwota = data['nastepna_kwota_brutto'] as double? ?? 0;
    final klient = data['klient'] as String? ?? '';
    final dni = data['dni_do_platnosci'] as int?;

    return EmmaBlockCardShell(
      title: 'Faktury',
      accent: const Color(0xFF26A69A),
      tag: EmmaTag(
        label: '$ilosc do wystawienia',
        color: ilosc > 0 ? const Color(0xFF26A69A) : Colors.grey,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nastepna,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(children: [
            const EmmaAccentIcon(Icons.person_outline, color: Color(0xFF26A69A)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                klient,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${kwota.toStringAsFixed(2)} zł',
              style: const TextStyle(
                  color: Color(0xFF26A69A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ]),
          if (dni != null) ...[
            const SizedBox(height: 3),
            Row(children: [
              const EmmaAccentIcon(Icons.schedule_outlined,
                  color: Color(0xFF26A69A)),
              const SizedBox(width: 5),
              Text(
                'Termin płatności: $dni dni',
                style: TextStyle(
                  color: dni <= 7 ? Colors.redAccent : Colors.white60,
                  fontSize: 11,
                ),
              ),
            ]),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            EmmaActionPill(label: 'Wystaw FV', route: '/faktury/nowa'),
            const SizedBox(width: 8),
            EmmaActionPill(label: 'Lista', route: '/faktury'),
          ]),
        ],
      ),
    );
  }
}
