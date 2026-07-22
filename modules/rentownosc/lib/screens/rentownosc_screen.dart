import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/rentownosc_model.dart';
import '../data/providers/rentownosc_provider.dart';

class RentownoscScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const RentownoscScreen({super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<RentownoscScreen> createState() => _RentownoscScreenState();
}

class _RentownoscScreenState extends ConsumerState<RentownoscScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kosztyProvider.notifier).init(widget.budowaId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddKoszt(ThemeColors theme) {
    KategoriaCosztu kat = KategoriaCosztu.robocizna;
    final opisCtrl = TextEditingController();
    final kwotaCtrl = TextEditingController();
    DateTime data = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dodaj koszt',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: KategoriaCosztu.values.map((k) {
                  final sel = kat == k;
                  return GestureDetector(
                    onTap: () => setInner(() => kat = k),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: sel ? theme.themeColor.withAlpha(40) : theme.userTile,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                      ),
                      child: Text('${k.emoji} ${k.label}',
                          style: TextStyle(
                              fontSize: 11,
                              color: sel ? theme.themeColor : theme.textColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: opisCtrl,
                style: TextStyle(color: theme.textColor),
                decoration: _dec('Opis kosztu', theme),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kwotaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: theme.textColor),
                decoration: _dec('Kwota (zł)', theme),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    final kwota = double.tryParse(kwotaCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (opisCtrl.text.trim().isEmpty || kwota <= 0) return;
                    Navigator.pop(context);
                    await ref.read(kosztyProvider.notifier).addKoszt(KosztModel(
                          id: 0,
                          budowaId: widget.budowaId,
                          kategoria: kat,
                          opis: opisCtrl.text.trim(),
                          kwota: kwota,
                          data: data,
                        ));
                    ref.invalidate(analizaProvider(widget.budowaId));
                  },
                  child: const Text('Dodaj'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, ThemeColors theme) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final analizaAsync = ref.watch(analizaProvider(widget.budowaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rentowność',
                style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.budowaNazwa,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [Tab(text: 'Analiza'), Tab(text: 'Koszty')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Analiza
          analizaAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
            error: (e, _) =>
                Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
            data: (analiza) => _AnalizaTab(analiza: analiza, theme: theme),
          ),
          // Tab 2: Lista kosztów
          _KosztyTab(budowaId: widget.budowaId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj koszt'),
        onPressed: () => _showAddKoszt(theme),
      ),
    );
  }
}

class _AnalizaTab extends StatelessWidget {
  final RentownoscBudowyModel analiza;
  final ThemeColors theme;
  const _AnalizaTab({required this.analiza, required this.theme});

  @override
  Widget build(BuildContext context) {
    final zysk = analiza.zyskBrutto;
    final marzaColor = analiza.naMinusie ? const Color(0xFF7B1F1F) : const Color(0xFF1E7A3A);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Główny wynik
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: analiza.naMinusie
                ? const Color(0xFF7B1F1F).withAlpha(20)
                : const Color(0xFF1E7A3A).withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: marzaColor.withAlpha(60)),
          ),
          child: Column(
            children: [
              Text(analiza.naMinusie ? '⚠️ Budowa na minusie' : '✅ Budowa na plusie',
                  style: TextStyle(fontSize: 13, color: marzaColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '${zysk >= 0 ? '+' : ''}${_money(zysk)} zł',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: marzaColor),
              ),
              Text(
                'Marża: ${(analiza.marza * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 14, color: marzaColor.withAlpha(180)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Przychody vs koszty
        _Box(theme: theme, children: [
          _StatRow('Wartość kontraktu', analiza.wartoscKontraktu, theme),
          _StatRow('Przychody (faktury)', analiza.przychodBrutto, theme),
          Divider(color: theme.bordercolor.withAlpha(40)),
          _StatRow('Koszty łącznie', analiza.kosztyLacznie, theme, red: true),
        ]),
        const SizedBox(height: 12),

        // Podział kosztów
        Text('Struktura kosztów',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: theme.textColor.withAlpha(180))),
        const SizedBox(height: 8),
        _Box(
          theme: theme,
          children: KategoriaCosztu.values
              .where((k) => (analiza.kosztyPerKategoria[k] ?? 0) > 0)
              .map((k) => _KatBar(
                    kategoria: k,
                    kwota: analiza.kosztyPerKategoria[k] ?? 0,
                    max: analiza.kosztyLacznie,
                    theme: theme,
                  ))
              .toList(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  String _money(double v) => v.abs().toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]} ');
}

class _Box extends StatelessWidget {
  final ThemeColors theme;
  final List<Widget> children;
  const _Box({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Column(children: children),
      );
}

class _StatRow extends StatelessWidget {
  final String label;
  final double value;
  final ThemeColors theme;
  final bool red;
  const _StatRow(this.label, this.value, this.theme, {this.red = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: theme.textColor)),
            Text(
              '${value.toStringAsFixed(2)} zł',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: red ? const Color(0xFF7B1F1F) : theme.textColor),
            ),
          ],
        ),
      );
}

class _KatBar extends StatelessWidget {
  final KategoriaCosztu kategoria;
  final double kwota;
  final double max;
  final ThemeColors theme;
  const _KatBar({required this.kategoria, required this.kwota, required this.max, required this.theme});

  @override
  Widget build(BuildContext context) {
    final frac = max > 0 ? (kwota / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${kategoria.emoji} ${kategoria.label}',
                  style: TextStyle(fontSize: 12, color: theme.textColor)),
              Text('${kwota.toStringAsFixed(0)} zł  ${(frac * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: theme.bordercolor.withAlpha(30),
              color: theme.themeColor,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _KosztyTab extends ConsumerWidget {
  final int budowaId;
  const _KosztyTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(kosztyProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (koszty) => koszty.isEmpty
          ? Center(
              child: Text('Brak wpisów kosztów',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: koszty.length,
              itemBuilder: (_, i) {
                final k = koszty[i];
                return Dismissible(
                  key: ValueKey(k.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: const Color(0xFF7B1F1F),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) =>
                      ref.read(kosztyProvider.notifier).deleteKoszt(k.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.userTile,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.bordercolor.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Text(k.kategoria.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k.opis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textColor)),
                                Text(k.kategoria.label,
                                    style: TextStyle(
                                        fontSize: 11, color: theme.textColor.withAlpha(120))),
                              ],
                            ),
                          ),
                          Text('${k.kwota.toStringAsFixed(2)} zł',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.themeColor)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
