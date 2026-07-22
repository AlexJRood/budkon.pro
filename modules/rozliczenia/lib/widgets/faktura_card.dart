import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/rozliczenia_model.dart';
import 'faktura_status_badge.dart';

class FakturaCard extends ConsumerWidget {
  final FakturaModel faktura;
  final VoidCallback? onTap;

  const FakturaCard({super.key, required this.faktura, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final alert = faktura.przeterminowana;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert
                ? const Color(0xFF7B1F1F).withAlpha(120)
                : theme.bordercolor.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(faktura.numer,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: theme.textColor)),
                ),
                FakturaStatusBadge(status: faktura.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(faktura.typ.label, theme.themeColor.withAlpha(40), theme.themeColor),
                const SizedBox(width: 8),
                Text('Termin: ${faktura.dataTerminuFmt}',
                    style: TextStyle(
                        fontSize: 11,
                        color: alert ? const Color(0xFF7B1F1F) : theme.textColor.withAlpha(120),
                        fontWeight: alert ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(faktura.inwestorNazwa,
                    style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(140))),
                Text(
                  '${_money(faktura.sumaBruttoCalkowita)} zł',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: faktura.status == StatusFaktury.oplacona
                          ? const Color(0xFF1E7A3A)
                          : theme.textColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
      );

  String _money(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]} ');
}
