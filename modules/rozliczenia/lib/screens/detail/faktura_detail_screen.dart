import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/rozliczenia_model.dart';
import '../../data/providers/rozliczenia_provider.dart';
import '../../widgets/faktura_status_badge.dart';

class FakturaDetailScreen extends ConsumerStatefulWidget {
  final int fakturaId;
  const FakturaDetailScreen({super.key, required this.fakturaId});

  @override
  ConsumerState<FakturaDetailScreen> createState() => _FakturaDetailScreenState();
}

class _FakturaDetailScreenState extends ConsumerState<FakturaDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(fakturaProvider(widget.fakturaId).notifier).init(widget.fakturaId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(fakturaProvider(widget.fakturaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
        data: (faktura) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.userTile,
              pinned: true,
              title: Text(faktura.numer,
                  style: TextStyle(
                      color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
              actions: [
                if (faktura.status == StatusFaktury.wystawiona ||
                    faktura.status == StatusFaktury.przeterminowana)
                  TextButton(
                    onPressed: () => ref
                        .read(fakturaProvider(widget.fakturaId).notifier)
                        .oznaczOplacona(),
                    child: Text('Opłacona',
                        style: TextStyle(
                            color: const Color(0xFF1E7A3A), fontWeight: FontWeight.bold)),
                  ),
                if (faktura.status == StatusFaktury.szkic)
                  TextButton(
                    onPressed: () => ref
                        .read(fakturaProvider(widget.fakturaId).notifier)
                        .setStatus(StatusFaktury.wystawiona),
                    child: Text('Wystaw',
                        style: TextStyle(
                            color: theme.themeColor, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),

            // Header info
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.userTile,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.bordercolor.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(faktura.typ.label,
                            style: TextStyle(
                                fontSize: 12, color: theme.textColor.withAlpha(140))),
                        FakturaStatusBadge(status: faktura.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Row('Inwestor', faktura.inwestorNazwa, theme),
                    _Row('Wykonawca', faktura.wykonawcaNazwa, theme),
                    _Row('Data wystawienia', faktura.dataWystawieniaFmt, theme),
                    _Row('Termin płatności', faktura.dataTerminuFmt, theme,
                        color: faktura.przeterminowana ? const Color(0xFF7B1F1F) : null),
                    if (faktura.dataOplatyFmt != null)
                      _Row('Data opłaty', faktura.dataOplatyFmt!, theme,
                          color: const Color(0xFF1E7A3A)),
                    if (faktura.postepProcent > 0)
                      _Row('Postęp robót', '${faktura.postepProcent.toStringAsFixed(1)}%', theme),
                  ],
                ),
              ),
            ),

            // Pozycje
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Pozycje faktury',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor.withAlpha(180))),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PozycjaRow(pozycja: faktura.pozycje[i], theme: theme),
                childCount: faktura.pozycje.length,
              ),
            ),

            // Suma
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.themeColor.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    _SumaRow('Netto', faktura.sumaNettoCalkowita, theme, small: true),
                    _SumaRow('VAT', faktura.sumaVatCalkowita, theme, small: true),
                    Divider(color: theme.bordercolor.withAlpha(60)),
                    _SumaRow('BRUTTO', faktura.sumaBruttoCalkowita, theme),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? color;
  const _Row(this.label, this.value, this.theme, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(120)))),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      color: color ?? theme.textColor,
                      fontWeight: color != null ? FontWeight.w600 : FontWeight.normal)),
            ),
          ],
        ),
      );
}

class _PozycjaRow extends StatelessWidget {
  final PozycjaFakturyModel pozycja;
  final ThemeColors theme;
  const _PozycjaRow({required this.pozycja, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.bordercolor.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pozycja.opis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
            if (pozycja.etapNazwa != null)
              Text(pozycja.etapNazwa!,
                  style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${pozycja.ilosc.toStringAsFixed(2)} ${pozycja.jednostka} × ${pozycja.cenaNetto.toStringAsFixed(2)} zł',
                  style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(130)),
                ),
                Text(
                  '${pozycja.wartoscBrutto.toStringAsFixed(2)} zł',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
              ],
            ),
          ],
        ),
      );
}

class _SumaRow extends StatelessWidget {
  final String label;
  final double value;
  final ThemeColors theme;
  final bool small;
  const _SumaRow(this.label, this.value, this.theme, {this.small = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: small ? 12 : 14,
                    color: small ? theme.textColor.withAlpha(120) : theme.textColor,
                    fontWeight: small ? FontWeight.normal : FontWeight.bold)),
            Text(
              '${value.toStringAsFixed(2)} zł',
              style: TextStyle(
                  fontSize: small ? 12 : 16,
                  color: small ? theme.textColor.withAlpha(150) : theme.themeColor,
                  fontWeight: small ? FontWeight.normal : FontWeight.bold),
            ),
          ],
        ),
      );
}
