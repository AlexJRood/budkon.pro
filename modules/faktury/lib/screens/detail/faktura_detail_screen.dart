import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:intl/intl.dart';
import '../../data/models/faktury_model.dart';
import '../../data/providers/faktury_provider.dart';
import '../../data/services/faktury_api.dart';

class FakturaDetailScreen extends ConsumerWidget {
  final int fakturaId;
  const FakturaDetailScreen({super.key, required this.fakturaId});

  static final _dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(fakturaDetailProvider(fakturaId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: theme.themeColor)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.textColor),
        ),
        body: Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
      ),
      data: (fv) => _FakturaBody(fv: fv, ref: ref, theme: theme),
    );
  }
}

class _FakturaBody extends StatelessWidget {
  final FakturaDetail fv;
  final WidgetRef ref;
  final ThemeColors theme;
  const _FakturaBody({required this.fv, required this.ref, required this.theme});

  static final _dateFmt = DateFormat('dd.MM.yyyy', 'pl_PL');
  static final _numFmt = NumberFormat('#,##0.00', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Text(fv.numerDisplay, style: TextStyle(color: theme.textColor)),
        actions: [
          if (fv.status == StatusFaktury.szkic || fv.status == StatusFaktury.wystawiona)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.textColor),
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => [
                if (fv.status == StatusFaktury.szkic ||
                    fv.status == StatusFaktury.wystawiona)
                  const PopupMenuItem(
                      value: 'wyslij', child: Text('Oznacz jako wysłana')),
                if (fv.status != StatusFaktury.oplacona &&
                    fv.status != StatusFaktury.anulowana)
                  const PopupMenuItem(
                      value: 'oplacona', child: Text('Oznacz jako opłacona')),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: fv.status.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: fv.status.color.withAlpha(100)),
                      ),
                      child: Text(
                        fv.status.label,
                        style: TextStyle(
                            color: fv.status.color, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_numFmt.format(fv.wartoscBrutto)} zł',
                      style: TextStyle(
                        color: theme.themeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StronaCard(
                        title: 'Wystawca',
                        nazwa: fv.wystawcaNazwa,
                        nip: fv.wystawcaNip,
                        adres: fv.wystawcaAdres,
                        extra: fv.wystawcaKonto.isNotEmpty
                            ? 'Konto: ${fv.wystawcaKonto}'
                            : null,
                        theme: theme,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StronaCard(
                        title: 'Nabywca',
                        nazwa: fv.nabywcaNazwa,
                        nip: fv.nabywcaNip,
                        adres: fv.nabywcaAdres,
                        theme: theme,
                      )),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _InfoRow('Wystawiono', _dateFmt.format(fv.dataWystawienia), theme: theme),
                  _InfoRow('Termin płatności', _dateFmt.format(fv.terminPlatnosci),
                      theme: theme,
                      valueColor: fv.jestPrzeterminowana ? const Color(0xFFEF5350) : null),
                  _InfoRow('Metoda płatności', fv.metodaPlatnosci.replaceAll('_', ' '),
                      theme: theme),

                  const SizedBox(height: 20),
                  Divider(color: theme.bordercolor.withAlpha(60)),
                  const SizedBox(height: 8),

                  Text('Pozycje',
                      style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),

                  ...fv.pozycje.asMap().entries.map((e) {
                    final p = e.value;
                    final ilosc =
                        double.tryParse(p['ilosc']?.toString() ?? '1') ?? 1;
                    final cena =
                        double.tryParse(p['cena_netto']?.toString() ?? '0') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['nazwa'] as String? ?? '',
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                              Text(
                                '${_numFmt.format(ilosc)} ${p['jednostka'] ?? 'szt.'} × ${_numFmt.format(cena)} zł',
                                style: TextStyle(
                                    color: theme.textColor.withAlpha(150), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_numFmt.format(ilosc * cena)} zł',
                          style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ]),
                    );
                  }),

                  Divider(color: theme.bordercolor.withAlpha(60)),
                  const SizedBox(height: 8),

                  _SumaRow('Netto', fv.wartoscNetto, theme.textColor.withAlpha(150), theme: theme),
                  _SumaRow('VAT ${fv.stawkaVat}%', fv.wartoscVat, theme.textColor.withAlpha(150), theme: theme),
                  _SumaRow('BRUTTO', fv.wartoscBrutto, theme.themeColor,
                      bold: true, large: true, theme: theme),

                  if (fv.uwagi.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.secondaryWidgetColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.bordercolor.withAlpha(40)),
                      ),
                      child: Text(fv.uwagi, style: TextStyle(color: theme.textColor)),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    try {
      if (action == 'wyslij') {
        await fakturyApi.wyslij(fv.id);
      } else if (action == 'oplacona') {
        await fakturyApi.oznaczOplacona(fv.id);
      }
      ref.invalidate(fakturaDetailProvider(fv.id));
      ref.read(fakturyProvider.notifier).load();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}

class _StronaCard extends StatelessWidget {
  final String title;
  final String nazwa;
  final String nip;
  final String adres;
  final String? extra;
  final ThemeColors theme;

  const _StronaCard({
    required this.title,
    required this.nazwa,
    required this.nip,
    required this.adres,
    required this.theme,
    this.extra,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.bordercolor.withAlpha(40)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: theme.themeColor, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(nazwa,
              style: TextStyle(
                  color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 12)),
          if (nip.isNotEmpty)
            Text('NIP: $nip',
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          if (adres.isNotEmpty)
            Text(adres,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          if (extra != null)
            Text(extra!,
                style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 10)),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {required this.theme, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label,
              style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: valueColor ?? theme.textColor)),
        ]),
      );
}

class _SumaRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ThemeColors theme;
  final bool bold;
  final bool large;
  static final _fmt = NumberFormat('#,##0.00', 'pl_PL');

  const _SumaRow(this.label, this.value, this.color,
      {required this.theme, this.bold = false, this.large = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  color: color)),
          const Spacer(),
          Text('${_fmt.format(value)} zł',
              style: TextStyle(
                  fontSize: large ? 16 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color)),
        ]),
      );
}
