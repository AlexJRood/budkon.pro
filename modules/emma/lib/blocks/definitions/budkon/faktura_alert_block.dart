import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class FakturaAlertBlockDefinition extends EmmaBlockDefinition {
  const FakturaAlertBlockDefinition();

  @override
  String get key => 'faktura_alert';

  @override
  bool supports(EmmaBlockDescriptor block) =>
      block.type == EmmaBlockType.fakturaAlert;

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    final data = block.raw;
    final ilosc = data['ilosc_oczekujacych'] as int? ?? 0;
    final nastepna = data['nastepna_nazwa']?.toString() ?? 'Faktura';
    final kwota = (data['nastepna_kwota_brutto'] as num?)?.toDouble() ?? 0;
    final klient = data['klient']?.toString() ?? '';
    final dni = data['dni_do_platnosci'] as int?;

    const accent = Color(0xFF26A69A);

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const EmmaAccentIcon(icon: Icons.receipt_long_outlined, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Faktury',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            EmmaTag(
              label: '$ilosc do wystawienia',
              color: ilosc > 0 ? accent : Colors.grey,
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            nastepna,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(children: [
            const EmmaAccentIcon(icon: Icons.person_outline, color: accent),
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
                  color: accent, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ]),
          if (dni != null) ...[
            const SizedBox(height: 3),
            Row(children: [
              const EmmaAccentIcon(icon: Icons.schedule_outlined, color: accent),
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
            EmmaActionPill(
              label: 'Wystaw FV',
              icon: Icons.add_outlined,
              onTap: null,
            ),
            const SizedBox(width: 8),
            EmmaActionPill(
              label: 'Lista',
              icon: Icons.list_outlined,
              onTap: null,
            ),
          ]),
        ],
      ),
    );
  }
}

