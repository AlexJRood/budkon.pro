import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/oferty_model.dart';
import '../../data/providers/oferty_provider.dart';
import '../../data/services/oferty_api.dart';

class OfertyDetailScreen extends ConsumerStatefulWidget {
  final int ofertaId;
  final bool autoPdf;

  const OfertyDetailScreen({super.key, required this.ofertaId, this.autoPdf = false});

  @override
  ConsumerState<OfertyDetailScreen> createState() => _OfertyDetailScreenState();
}

class _OfertyDetailScreenState extends ConsumerState<OfertyDetailScreen> {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  bool _generujePdf = false;
  bool _pdfGotowy = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPdf) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _generujPdf());
    }
  }

  Future<void> _generujPdf() async {
    setState(() => _generujePdf = true);
    try {
      await ofertyApi.generujPdf(widget.ofertaId);
      setState(() { _generujePdf = false; _pdfGotowy = true; });
      ref.invalidate(ofertaDetailProvider(widget.ofertaId));
    } catch (e) {
      setState(() => _generujePdf = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd PDF: $e')));
    }
  }

  Future<void> _otworzPdf() async {
    final url = Uri.parse(ofertyApi.pdfUrl(widget.ofertaId));
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _pobierzPdf() async {
    final url = Uri.parse(ofertyApi.pdfUrl(widget.ofertaId, download: true));
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _zmienStatus(BuildContext ctx, OfertyDetail oferta) async {
    final nowy = await showDialog<String>(
      context: ctx,
      builder: (_) => SimpleDialog(
        title: const Text('Zmień status oferty'),
        children: StatusOferty.values.where((s) => s != oferta.status).map((s) =>
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s.value), child: Text(s.label)),
        ).toList(),
      ),
    );
    if (nowy == null) return;
    try {
      await ofertyApi.zmienStatus(widget.ofertaId, nowy);
      ref.invalidate(ofertaDetailProvider(widget.ofertaId));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(ofertaDetailProvider(widget.ofertaId));

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (oferta) => _Body(
          oferta: oferta,
          theme: theme,
          generujePdf: _generujePdf,
          pdfGotowy: _pdfGotowy || oferta.hasPdf,
          onGenerujPdf: _generujPdf,
          onOtworzPdf: _otworzPdf,
          onPobierzPdf: _pobierzPdf,
          onZmienStatus: () => _zmienStatus(context, oferta),
          onDuplikuj: () async {
            try {
              final nowa = await ofertyApi.duplikuj(oferta.id);
              if (mounted) {
                ref.read(navigationService).pushNamedScreen(
                  '/oferty/detail',
                  data: {'ofertaId': nowa.id},
                );
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
            }
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OfertyDetail oferta;
  final ThemeColors theme;
  final bool generujePdf;
  final bool pdfGotowy;
  final VoidCallback onGenerujPdf;
  final VoidCallback onOtworzPdf;
  final VoidCallback onPobierzPdf;
  final VoidCallback onZmienStatus;
  final VoidCallback onDuplikuj;

  const _Body({
    required this.oferta,
    required this.theme,
    required this.generujePdf,
    required this.pdfGotowy,
    required this.onGenerujPdf,
    required this.onOtworzPdf,
    required this.onPobierzPdf,
    required this.onZmienStatus,
    required this.onDuplikuj,
  });

  Color _statusColor(StatusOferty s) => switch (s) {
    StatusOferty.roboczy => theme.textColor.withAlpha(100),
    StatusOferty.wyslana => const Color(0xFF2196F3),
    StatusOferty.zaakceptowana => const Color(0xFF4CAF50),
    StatusOferty.odrzucona => Colors.red,
    StatusOferty.wygasla => theme.textColor.withAlpha(100),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(oferta.status);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.textColor),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(oferta.numer.isNotEmpty ? oferta.numer : 'Szkic',
                style: TextStyle(color: theme.textColor, fontSize: 15)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.sidebar, theme.themeColor.withAlpha(120)],
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              iconColor: theme.textColor,
              onSelected: (v) {
                if (v == 'status') onZmienStatus();
                if (v == 'duplikuj') onDuplikuj();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'status',
                  child: ListTile(leading: Icon(Icons.swap_horiz), title: Text('Zmień status'), dense: true)),
                const PopupMenuItem(value: 'duplikuj',
                  child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Duplikuj'), dense: true)),
              ],
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(oferta.tytul,
                      style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withAlpha(80)),
                    ),
                    child: Text(oferta.status.label,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                ]),

                const SizedBox(height: 20),

                _PdfPanel(
                  theme: theme,
                  generujePdf: generujePdf,
                  pdfGotowy: pdfGotowy,
                  onGeneruj: onGenerujPdf,
                  onOtworz: onOtworzPdf,
                  onPobierz: onPobierzPdf,
                ),

                const SizedBox(height: 20),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _InfoBlok(theme: theme, title: 'Wystawca', lines: [
                    oferta.wystawcaNazwa,
                    oferta.wystawcaNip.isNotEmpty ? 'NIP: ${oferta.wystawcaNip}' : '',
                    oferta.wystawcaEmail,
                    oferta.wystawcaTelefon,
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: _InfoBlok(theme: theme, title: 'Klient', lines: [
                    oferta.klientNazwa,
                    oferta.klientNip.isNotEmpty ? 'NIP: ${oferta.klientNip}' : '',
                    oferta.klientEmail,
                    oferta.klientTelefon,
                    oferta.klientAdres,
                  ])),
                ]),

                const SizedBox(height: 16),

                Row(children: [
                  _DateChip(theme: theme, label: 'Wystawiona', value: oferta.dataWystawienia),
                  if (oferta.waznaDo != null) ...[
                    const SizedBox(width: 12),
                    _DateChip(theme: theme, label: 'Ważna do', value: oferta.waznaDo!),
                  ],
                ]),

                const SizedBox(height: 24),

                Text('Pozycje', style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                ...oferta.pozycje.map((dzial) => _DzialWidget(dzial: dzial, theme: theme)),

                const SizedBox(height: 16),

                _PodsumowanieWidget(oferta: oferta, theme: theme),

                if (oferta.historiaStatusu.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Historia', style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...oferta.historiaStatusu.reversed.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(Icons.circle, size: 8, color: theme.themeColor),
                      const SizedBox(width: 10),
                      Text(h.data.substring(0, 16),
                          style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
                      const SizedBox(width: 10),
                      Text(h.status.label,
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                      if (h.uwagi.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text(h.uwagi,
                            style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11),
                            overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                  )),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PdfPanel extends StatelessWidget {
  final ThemeColors theme;
  final bool generujePdf;
  final bool pdfGotowy;
  final VoidCallback onGeneruj;
  final VoidCallback onOtworz;
  final VoidCallback onPobierz;

  const _PdfPanel({
    required this.theme,
    required this.generujePdf,
    required this.pdfGotowy,
    required this.onGeneruj,
    required this.onOtworz,
    required this.onPobierz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.themeColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.picture_as_pdf, color: theme.themeColor),
            const SizedBox(width: 8),
            Text(pdfGotowy ? 'PDF gotowy' : 'PDF oferty',
                style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (generujePdf)
              SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(pdfGotowy ? 'Regeneruj' : 'Generuj PDF'),
              onPressed: generujePdf ? null : onGeneruj,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.themeColor,
                side: BorderSide(color: theme.themeColor.withAlpha(80)),
              ),
            ),
            if (pdfGotowy) ...[
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Otwórz'),
                onPressed: onOtworz,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.buttonTextColor,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Pobierz'),
                onPressed: onPobierz,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.bordercolor.withAlpha(80)),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _DzialWidget extends StatelessWidget {
  final DzialOferty dzial;
  final ThemeColors theme;
  const _DzialWidget({required this.dzial, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dzial.nazwa.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(dzial.nazwa,
                style: TextStyle(fontWeight: FontWeight.w700, color: theme.themeColor)),
          ),
        ...dzial.pozycje.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(p.opis,
                style: TextStyle(color: theme.textColor, fontSize: 13))),
            const SizedBox(width: 8),
            Text(
              '${p.ilosc % 1 == 0 ? p.ilosc.toInt() : p.ilosc.toStringAsFixed(2)} ${p.jednostka}',
              style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text('${p.wartosc.toStringAsFixed(0)} PLN',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            const Spacer(),
            Text('Razem: ${dzial.wartosc.toStringAsFixed(0)} PLN',
                style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12, fontStyle: FontStyle.italic)),
          ]),
        ),
        Divider(color: theme.bordercolor.withAlpha(80)),
      ],
    );
  }
}

class _PodsumowanieWidget extends StatelessWidget {
  final OfertyDetail oferta;
  final ThemeColors theme;
  const _PodsumowanieWidget({required this.oferta, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(80)),
      ),
      child: Column(
        children: [
          _SumaRow(label: 'Wartość netto', value: '${oferta.wartoscNetto.toStringAsFixed(2)} PLN', theme: theme),
          if (oferta.rabatProcent > 0)
            _SumaRow(
              label: 'Rabat (${oferta.rabatProcent.toStringAsFixed(0)}%)',
              value: '-${(oferta.wartoscNetto * oferta.rabatProcent / 100).toStringAsFixed(2)} PLN',
              theme: theme,
              color: const Color(0xFF4CAF50),
            ),
          _SumaRow(label: 'VAT ${oferta.vatProcent}%', value: '${oferta.wartoscVat.toStringAsFixed(2)} PLN', theme: theme),
          Divider(color: theme.bordercolor.withAlpha(80)),
          _SumaRow(
            label: 'RAZEM BRUTTO',
            value: '${oferta.wartoscBrutto.toStringAsFixed(2)} PLN',
            theme: theme,
            big: true,
            color: theme.themeColor,
          ),
        ],
      ),
    );
  }
}

class _SumaRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final bool big;
  final Color? color;

  const _SumaRow({required this.label, required this.value, required this.theme, this.big = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: TextStyle(color: theme.textColor, fontSize: big ? 14 : 13,
          fontWeight: big ? FontWeight.w700 : FontWeight.normal)),
      const Spacer(),
      Text(value, style: TextStyle(color: color ?? theme.textColor, fontSize: big ? 16 : 13,
          fontWeight: FontWeight.w700)),
    ]),
  );
}

class _InfoBlok extends StatelessWidget {
  final String title;
  final List<String> lines;
  final ThemeColors theme;
  const _InfoBlok({required this.title, required this.lines, required this.theme});

  @override
  Widget build(BuildContext context) {
    final visible = lines.where((l) => l.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...visible.map((l) => Text(l, style: TextStyle(color: theme.textColor, fontSize: 12))),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  const _DateChip({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: theme.textColor.withAlpha(120)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 10)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: theme.textColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
