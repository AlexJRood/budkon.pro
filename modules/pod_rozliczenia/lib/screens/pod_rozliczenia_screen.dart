import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/pod_rozliczenia_model.dart';
import '../data/providers/pod_rozliczenia_provider.dart';

class PodRozliczeniaScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const PodRozliczeniaScreen(
      {super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<PodRozliczeniaScreen> createState() =>
      _PodRozliczeniaScreenState();
}

class _PodRozliczeniaScreenState extends ConsumerState<PodRozliczeniaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(podFakturaNotifierProvider.notifier).init(widget.budowaId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddFaktura(ThemeColors theme) {
    final numerCtrl = TextEditingController();
    final podwykonawcaCtrl = TextEditingController();
    final kwotaCtrl = TextEditingController();
    final kaucjaCtrl = TextEditingController(text: '5');
    final opisCtrl = TextEditingController();
    DateTime dataWystawienia = DateTime.now();
    DateTime dataTerminu = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nowa faktura podwykonawcy',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor)),
              const SizedBox(height: 12),
              _tf(numerCtrl, 'Numer faktury', theme),
              const SizedBox(height: 8),
              _tf(podwykonawcaCtrl, 'Podwykonawca', theme),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _tf(kwotaCtrl, 'Kwota brutto (zł)', theme, num: true)),
                const SizedBox(width: 8),
                Expanded(child: _tf(kaucjaCtrl, 'Kaucja %', theme, num: true)),
              ]),
              const SizedBox(height: 8),
              _tf(opisCtrl, 'Zakres prac (opcjonalnie)', theme),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    final kwota = double.tryParse(kwotaCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (kwota <= 0 || numerCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await ref
                        .read(podFakturaNotifierProvider.notifier)
                        .addFaktura(FakturaPodwykonawcyModel(
                          id: 0,
                          budowaId: widget.budowaId,
                          podwykonawcaId: 0,
                          podwykonawcaNazwa: podwykonawcaCtrl.text.trim(),
                          numer: numerCtrl.text.trim(),
                          kwotaBrutto: kwota,
                          kaucjaProcentowa:
                              double.tryParse(kaucjaCtrl.text) ?? 5,
                          dataWystawienia: dataWystawienia,
                          dataTerminu: dataTerminu,
                          opis: opisCtrl.text.trim(),
                        ));
                  },
                  child: const Text('Dodaj fakturę'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, ThemeColors theme,
          {bool num = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : null,
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rozliczenia podwykonawców',
                style: TextStyle(
                    color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(widget.budowaNazwa,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [
            Tab(text: 'Faktury'),
            Tab(text: 'Kaucje'),
            Tab(text: 'Podwykonawcy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _FakturyTab(budowaId: widget.budowaId),
          _KaucjeTab(budowaId: widget.budowaId),
          _StatsTab(budowaId: widget.budowaId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Nowa faktura'),
        onPressed: () => _showAddFaktura(theme),
      ),
    );
  }
}

class _FakturyTab extends ConsumerWidget {
  final int budowaId;
  const _FakturyTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(podFakturaNotifierProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (faktury) => faktury.isEmpty
          ? Center(
              child: Text('Brak faktur',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: faktury.length,
              itemBuilder: (_, i) => _FakturaCard(faktura: faktury[i], theme: theme),
            ),
    );
  }
}

class _FakturaCard extends ConsumerWidget {
  final FakturaPodwykonawcyModel faktura;
  final ThemeColors theme;
  const _FakturaCard({required this.faktura, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (badgeLabel, badgeColor) = switch (faktura.status) {
      StatusRozliczeniaPod.oczekuje => ('OCZEKUJE', const Color(0xFF7B5E00)),
      StatusRozliczeniaPod.zatwierdzone => ('ZATW.', const Color(0xFF1A5E8A)),
      StatusRozliczeniaPod.oplacone => ('OPŁACONE', const Color(0xFF1E7A3A)),
      StatusRozliczeniaPod.sporne => ('SPORNE', const Color(0xFF7B1F1F)),
      StatusRozliczeniaPod.anulowane => ('ANULOW.', const Color(0xFF4A4A4A)),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: faktura.przeterminowane
              ? const Color(0xFF7B1F1F).withAlpha(100)
              : theme.bordercolor.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faktura.numer,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor)),
                    Text(faktura.podwykonawcaNazwa,
                        style: TextStyle(
                            fontSize: 12, color: theme.textColor.withAlpha(140))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(badgeLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip('Brutto: ${faktura.kwotaBrutto.toStringAsFixed(0)} zł',
                  theme.textColor.withAlpha(20), theme.textColor),
              const SizedBox(width: 8),
              _chip(
                  'Kaucja ${faktura.kaucjaProcentowa.toStringAsFixed(0)}%: ${faktura.kaucjaKwota.toStringAsFixed(0)} zł',
                  const Color(0xFF7B5E00).withAlpha(25),
                  const Color(0xFF7B5E00)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Do zapłaty: ${faktura.doZaplaty.toStringAsFixed(2)} zł',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.themeColor)),
              Text('Termin: ${faktura.dataTerminuFmt}',
                  style: TextStyle(
                      fontSize: 11,
                      color: faktura.przeterminowane
                          ? const Color(0xFF7B1F1F)
                          : theme.textColor.withAlpha(120),
                      fontWeight: faktura.przeterminowane
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ],
          ),
          if (faktura.status == StatusRozliczeniaPod.oczekuje ||
              faktura.status == StatusRozliczeniaPod.zatwierdzone) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (faktura.status == StatusRozliczeniaPod.oczekuje)
                  _ActionBtn(
                    label: 'Zatwierdź',
                    color: const Color(0xFF1A5E8A),
                    onTap: () => ref
                        .read(podFakturaNotifierProvider.notifier)
                        .setStatus(faktura.id, StatusRozliczeniaPod.zatwierdzone),
                  ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Opłać',
                  color: const Color(0xFF1E7A3A),
                  onTap: () => ref
                      .read(podFakturaNotifierProvider.notifier)
                      .setStatus(faktura.id, StatusRozliczeniaPod.oplacone),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

class _KaucjeTab extends ConsumerWidget {
  final int budowaId;
  const _KaucjeTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(podFakturaNotifierProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (_, __) => const SizedBox(),
      data: (faktury) {
        final zKaucja = faktury
            .where((f) =>
                f.status == StatusRozliczeniaPod.oplacone && f.kaucjaKwota > 0)
            .toList();
        if (zKaucja.isEmpty) {
          return Center(
            child: Text('Brak pobranych kaucji',
                style: TextStyle(color: theme.textColor.withAlpha(100))),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Suma kaucji do zwrotu: ${zKaucja.fold(0.0, (s, f) => s + f.kaucjaKwota).toStringAsFixed(2)} zł',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: theme.themeColor),
              ),
            ),
            ...zKaucja.map((f) => _KaucjaTile(faktura: f, theme: theme)),
          ],
        );
      },
    );
  }
}

class _KaucjaTile extends ConsumerWidget {
  final FakturaPodwykonawcyModel faktura;
  final ThemeColors theme;
  const _KaucjaTile({required this.faktura, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7B5E00).withAlpha(60)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faktura.podwykonawcaNazwa,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                  Text('Faktura ${faktura.numer}',
                      style: TextStyle(
                          fontSize: 11, color: theme.textColor.withAlpha(120))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${faktura.kaucjaKwota.toStringAsFixed(2)} zł',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B5E00))),
                GestureDetector(
                  onTap: () => ref
                      .read(podFakturaNotifierProvider.notifier)
                      .zwrocKaucje(faktura.id, faktura.kaucjaKwota),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E7A3A),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Zwróć',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _StatsTab extends ConsumerWidget {
  final int budowaId;
  const _StatsTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(podStatsProvider(budowaId));

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (stats) => stats.isEmpty
          ? Center(
              child: Text('Brak danych',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stats.length,
              itemBuilder: (_, i) {
                final s = stats[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.userTile,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.bordercolor.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nazwa,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatPill('Faktury: ${s.fakturyLacznie.toStringAsFixed(0)} zł',
                              theme.textColor.withAlpha(20), theme.textColor),
                          const SizedBox(width: 8),
                          _StatPill('Opłacono: ${s.oplacenoLacznie.toStringAsFixed(0)} zł',
                              const Color(0xFF1E7A3A).withAlpha(20),
                              const Color(0xFF1E7A3A)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatPill(
                              'Kaucje pobrane: ${s.kaucjePobrane.toStringAsFixed(0)} zł',
                              const Color(0xFF7B5E00).withAlpha(20),
                              const Color(0xFF7B5E00)),
                          if (s.fakturyOczekujace > 0) ...[
                            const SizedBox(width: 8),
                            _StatPill('${s.fakturyOczekujace} oczekuje',
                                theme.themeColor.withAlpha(20), theme.themeColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatPill(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
      );
}
