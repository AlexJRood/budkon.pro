import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/oferty_model.dart';
import '../../data/providers/oferty_provider.dart';
import '../../data/services/oferty_api.dart';

class OfertyDetailScreen extends ConsumerStatefulWidget {
  final int ofertaId;
  final bool autoPdf; // auto-generuj PDF po załadowaniu

  const OfertyDetailScreen({
    super.key,
    required this.ofertaId,
    this.autoPdf = false,
  });

  @override
  ConsumerState<OfertyDetailScreen> createState() =>
      _OfertyDetailScreenState();
}

class _OfertyDetailScreenState extends ConsumerState<OfertyDetailScreen> {
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
      setState(() {
        _generujePdf = false;
        _pdfGotowy = true;
      });
      ref.invalidate(ofertaDetailProvider(widget.ofertaId));
    } catch (e) {
      setState(() => _generujePdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd PDF: $e')));
      }
    }
  }

  Future<void> _otworzPdf() async {
    final url =
        Uri.parse(ofertyApi.pdfUrl(widget.ofertaId));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pobierzPdf() async {
    final url = Uri.parse(
        ofertyApi.pdfUrl(widget.ofertaId, download: true));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _zmienStatus(
      BuildContext ctx, OfertyDetail oferta) async {
    final nowy = await showDialog<String>(
      context: ctx,
      builder: (_) => SimpleDialog(
        title: const Text('Zmień status oferty'),
        children: StatusOferty.values
            .where((s) => s != oferta.status)
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s.value),
                  child: Text(s.label),
                ))
            .toList(),
      ),
    );
    if (nowy == null) return;
    try {
      await ofertyApi.zmienStatus(widget.ofertaId, nowy);
      ref.invalidate(ofertaDetailProvider(widget.ofertaId));
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ofertaDetailProvider(widget.ofertaId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (oferta) => _Body(
          oferta: oferta,
          generujePdf: _generujePdf,
          pdfGotowy: _pdfGotowy || oferta.hasPdf,
          onGenerujPdf: _generujPdf,
          onOtworzPdf: _otworzPdf,
          onPobierzPdf: _pobierzPdf,
          onZmienStatus: () => _zmienStatus(context, oferta),
          onDuplikuj: () async {
            try {
              final nowa = await ofertyApi.duplikuj(oferta.id);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OfertyDetailScreen(ofertaId: nowa.id),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd: $e')));
              }
            }
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OfertyDetail oferta;
  final bool generujePdf;
  final bool pdfGotowy;
  final VoidCallback onGenerujPdf;
  final VoidCallback onOtworzPdf;
  final VoidCallback onPobierzPdf;
  final VoidCallback onZmienStatus;
  final VoidCallback onDuplikuj;

  const _Body({
    required this.oferta,
    required this.generujePdf,
    required this.pdfGotowy,
    required this.onGenerujPdf,
    required this.onOtworzPdf,
    required this.onPobierzPdf,
    required this.onZmienStatus,
    required this.onDuplikuj,
  });

  Color _statusColor(BuildContext ctx, StatusOferty s) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (s) {
      StatusOferty.roboczy => cs.outline,
      StatusOferty.wyslana => const Color(0xFF2196F3),
      StatusOferty.zaakceptowana => const Color(0xFF4CAF50),
      StatusOferty.odrzucona => cs.error,
      StatusOferty.wygasla => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context, oferta.status);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(oferta.numer.isNotEmpty ? oferta.numer : 'Szkic'),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    cs.primary.withAlpha(180),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'status') onZmienStatus();
                if (v == 'duplikuj') onDuplikuj();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'status',
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Zmień status'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplikuj',
                  child: ListTile(
                    leading: Icon(Icons.copy_outlined),
                    title: Text('Duplikuj'),
                    dense: true,
                  ),
                ),
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
                // Tytuł + status
                Row(children: [
                  Expanded(
                    child: Text(
                      oferta.tytul,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withAlpha(80)),
                    ),
                    child: Text(
                      oferta.status.label,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // PDF akcje
                _PdfPanel(
                  generujePdf: generujePdf,
                  pdfGotowy: pdfGotowy,
                  onGeneruj: onGenerujPdf,
                  onOtworz: onOtworzPdf,
                  onPobierz: onPobierzPdf,
                ),

                const SizedBox(height: 20),

                // Klient / wystawca
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _InfoBlok(
                      title: 'Wystawca',
                      lines: [
                        oferta.wystawcaNazwa,
                        oferta.wystawcaNip.isNotEmpty
                            ? 'NIP: ${oferta.wystawcaNip}'
                            : '',
                        oferta.wystawcaEmail,
                        oferta.wystawcaTelefon,
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _InfoBlok(
                      title: 'Klient',
                      lines: [
                        oferta.klientNazwa,
                        oferta.klientNip.isNotEmpty
                            ? 'NIP: ${oferta.klientNip}'
                            : '',
                        oferta.klientEmail,
                        oferta.klientTelefon,
                        oferta.klientAdres,
                      ],
                    )),
                  ],
                ),

                const SizedBox(height: 16),

                // Daty
                Row(children: [
                  _DateChip(
                      label: 'Wystawiona',
                      value: oferta.dataWystawienia),
                  if (oferta.waznaDo != null) ...[
                    const SizedBox(width: 12),
                    _DateChip(label: 'Ważna do', value: oferta.waznaDo!),
                  ],
                ]),

                const SizedBox(height: 24),

                // Pozycje
                Text('Pozycje',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                ...oferta.pozycje.map((dzial) => _DzialWidget(dzial: dzial)),

                const SizedBox(height: 16),

                // Podsumowanie
                _PodsumowanieWidget(oferta: oferta),

                // Historia statusów
                if (oferta.historiaStatusu.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Historia',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...oferta.historiaStatusu.reversed.map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Icon(Icons.circle, size: 8, color: cs.primary),
                        const SizedBox(width: 10),
                        Text(h.data.substring(0, 16),
                            style: TextStyle(
                                color: cs.outline, fontSize: 11)),
                        const SizedBox(width: 10),
                        Text(h.status.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        if (h.uwagi.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(h.uwagi,
                                  style: TextStyle(
                                      color: cs.outline, fontSize: 11),
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ]),
                    ),
                  ),
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

// ---- PDF panel -------------------------------------------------------------

class _PdfPanel extends StatelessWidget {
  final bool generujePdf;
  final bool pdfGotowy;
  final VoidCallback onGeneruj;
  final VoidCallback onOtworz;
  final VoidCallback onPobierz;

  const _PdfPanel({
    required this.generujePdf,
    required this.pdfGotowy,
    required this.onGeneruj,
    required this.onOtworz,
    required this.onPobierz,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.picture_as_pdf, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              pdfGotowy ? 'PDF gotowy' : 'PDF oferty',
              style: TextStyle(
                  color: cs.primary, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (generujePdf)
              const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (!pdfGotowy || true)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(pdfGotowy ? 'Regeneruj' : 'Generuj PDF'),
                onPressed: generujePdf ? null : onGeneruj,
              ),
            if (pdfGotowy) ...[
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Otwórz'),
                onPressed: onOtworz,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Pobierz'),
                onPressed: onPobierz,
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ---- Pozycje ---------------------------------------------------------------

class _DzialWidget extends StatelessWidget {
  final DzialOferty dzial;
  const _DzialWidget({required this.dzial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dzial.nazwa.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(
              dzial.nazwa,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ),
        ...dzial.pozycje.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(p.opis, style: const TextStyle(fontSize: 13))),
                  const SizedBox(width: 8),
                  Text(
                    '${p.ilosc % 1 == 0 ? p.ilosc.toInt() : p.ilosc.toStringAsFixed(2)} ${p.jednostka}',
                    style: TextStyle(color: cs.outline, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${p.wartosc.toStringAsFixed(0)} PLN',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            const Spacer(),
            Text(
              'Razem: ${dzial.wartosc.toStringAsFixed(0)} PLN',
              style: TextStyle(
                  color: cs.outline,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ]),
        ),
        Divider(color: cs.outlineVariant),
      ],
    );
  }
}

class _PodsumowanieWidget extends StatelessWidget {
  final OfertyDetail oferta;
  const _PodsumowanieWidget({required this.oferta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          _SumaRow(
              label: 'Wartość netto',
              value: '${oferta.wartoscNetto.toStringAsFixed(2)} PLN'),
          if (oferta.rabatProcent > 0)
            _SumaRow(
              label: 'Rabat (${oferta.rabatProcent.toStringAsFixed(0)}%)',
              value:
                  '-${(oferta.wartoscNetto * oferta.rabatProcent / 100).toStringAsFixed(2)} PLN',
              color: const Color(0xFF4CAF50),
            ),
          _SumaRow(
              label: 'VAT ${oferta.vatProcent}%',
              value: '${oferta.wartoscVat.toStringAsFixed(2)} PLN'),
          const Divider(),
          _SumaRow(
            label: 'RAZEM BRUTTO',
            value: '${oferta.wartoscBrutto.toStringAsFixed(2)} PLN',
            big: true,
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _SumaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  final Color? color;

  const _SumaRow({
    required this.label,
    required this.value,
    this.big = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: big ? 14 : 13,
                  fontWeight: big ? FontWeight.w700 : FontWeight.normal)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: big ? 16 : 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      );
}

class _InfoBlok extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _InfoBlok({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = lines.where((l) => l.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: cs.outline, fontSize: 10,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...visible.map((l) => Text(l,
              style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  const _DateChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: cs.outline),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: cs.outline, fontSize: 10)),
        const SizedBox(width: 6),
        Text(value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
