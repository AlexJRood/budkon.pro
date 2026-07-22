import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/gwarancje_model.dart';
import '../data/providers/gwarancje_provider.dart';

class GwarancjeScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const GwarancjeScreen(
      {super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<GwarancjeScreen> createState() => _GwarancjeScreenState();
}

class _GwarancjeScreenState extends ConsumerState<GwarancjeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gwarancjeProvider.notifier).init(widget.budowaId);
      ref.read(zgloszeniaProvider.notifier).init(widget.budowaId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddGwarancja(ThemeColors theme) {
    final tytulCtrl = TextEditingController();
    final wykonawcaCtrl = TextEditingController();
    final zakresCtrl = TextEditingController();
    final kontaktCtrl = TextEditingController();
    DateTime dataOdbioru = DateTime.now();
    DateTime dataKonca = DateTime.now().add(const Duration(days: 365 * 3));

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nowa gwarancja',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor)),
                const SizedBox(height: 12),
                _tf(tytulCtrl, 'Tytuł / zakres robót *', theme),
                const SizedBox(height: 8),
                _tf(wykonawcaCtrl, 'Wykonawca *', theme),
                const SizedBox(height: 8),
                _tf(zakresCtrl, 'Szczegółowy zakres (opcjonalnie)', theme, maxLines: 2),
                const SizedBox(height: 8),
                _tf(kontaktCtrl, 'Kontakt serwisowy', theme),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _datePick('Data odbioru', dataOdbioru,
                            (d) => set(() => dataOdbioru = d), theme)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _datePick('Koniec gwarancji', dataKonca,
                            (d) => set(() => dataKonca = d), theme)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                        foregroundColor: Colors.white),
                    onPressed: () async {
                      if (tytulCtrl.text.trim().isEmpty ||
                          wykonawcaCtrl.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      await ref.read(gwarancjeProvider.notifier).addGwarancja(
                            GwarancjaModel(
                              id: 0,
                              budowaId: widget.budowaId,
                              tytul: tytulCtrl.text.trim(),
                              wykonawca: wykonawcaCtrl.text.trim(),
                              zakres: zakresCtrl.text.trim().isEmpty
                                  ? null
                                  : zakresCtrl.text.trim(),
                              dataOdbioru: dataOdbioru,
                              dataKoncaGwarancji: dataKonca,
                              kontaktSerwisowy: kontaktCtrl.text.trim(),
                            ),
                          );
                    },
                    child: const Text('Dodaj gwarancję'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddZgloszenie(ThemeColors theme, List<GwarancjaModel> gwarancje) {
    if (gwarancje.isEmpty) return;
    GwarancjaModel selected = gwarancje.first;
    final opisCtrl = TextEditingController();
    final zglaszajacyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nowe zgłoszenie serwisowe',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor)),
              const SizedBox(height: 10),
              // Dropdown gwarancji
              DropdownButtonFormField<GwarancjaModel>(
                value: selected,
                dropdownColor: theme.userTile,
                style: TextStyle(color: theme.textColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Gwarancja',
                  labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: gwarancje
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.tytul,
                              style: TextStyle(color: theme.textColor, fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (g) => g != null ? set(() => selected = g) : null,
              ),
              const SizedBox(height: 8),
              _tf(opisCtrl, 'Opis usterki / problemu *', theme, maxLines: 3),
              const SizedBox(height: 8),
              _tf(zglaszajacyCtrl, 'Zgłaszający', theme),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (opisCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await ref.read(zgloszeniaProvider.notifier).add(
                          ZgloszenieSerwisowModel(
                            id: 0,
                            gwarancjaId: selected.id,
                            gwarancjaTytul: selected.tytul,
                            opis: opisCtrl.text.trim(),
                            zglaszajacy: zglaszajacyCtrl.text.trim(),
                            dataZgloszenia: DateTime.now(),
                          ),
                        );
                  },
                  child: const Text('Zgłoś'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, ThemeColors theme,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _datePick(String label, DateTime value, ValueChanged<DateTime> onChanged,
          ThemeColors theme) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2010),
            lastDate: DateTime(2040),
          );
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text('${value.day}.${value.month}.${value.year}',
              style: TextStyle(color: theme.textColor, fontSize: 13)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final gwarancjeAsync = ref.watch(gwarancjeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gwarancje i serwis',
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
          tabs: const [Tab(text: 'Gwarancje'), Tab(text: 'Zgłoszenia')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _GwarancjeTab(budowaId: widget.budowaId),
          _ZgloszeniaTab(budowaId: widget.budowaId),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          backgroundColor: theme.themeColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_tabCtrl.index == 0 ? 'Nowa gwarancja' : 'Nowe zgłoszenie'),
          onPressed: () {
            if (_tabCtrl.index == 0) {
              _showAddGwarancja(theme);
            } else {
              final gwarancje = gwarancjeAsync.valueOrNull ?? [];
              _showAddZgloszenie(theme, gwarancje);
            }
          },
        ),
      ),
    );
  }
}

class _GwarancjeTab extends ConsumerWidget {
  final int budowaId;
  const _GwarancjeTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(gwarancjeProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (gwarancje) => gwarancje.isEmpty
          ? Center(
              child: Text('Brak gwarancji',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: gwarancje.length,
              itemBuilder: (_, i) => _GwarancjaTile(g: gwarancje[i], theme: theme),
            ),
    );
  }
}

class _GwarancjaTile extends StatelessWidget {
  final GwarancjaModel g;
  final ThemeColors theme;
  const _GwarancjaTile({required this.g, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeColor) = switch (g.status) {
      StatusGwarancji.aktywna => ('AKTYWNA', const Color(0xFF1E7A3A)),
      StatusGwarancji.wygasajaca => ('WYGASA', const Color(0xFF7B5E00)),
      StatusGwarancji.wygasla => ('WYGASŁA', const Color(0xFF7B1F1F)),
      StatusGwarancji.zarchiwizowana => ('ARCH.', const Color(0xFF3A3A3A)),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: g.wygasla
              ? const Color(0xFF7B1F1F).withAlpha(80)
              : g.wygasajaca
                  ? const Color(0xFF7B5E00).withAlpha(80)
                  : theme.bordercolor.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.tytul,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: theme.textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(badgeLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.business, size: 13, color: theme.textColor.withAlpha(100)),
              const SizedBox(width: 4),
              Text(g.wykonawca,
                  style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(140))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Odbiór: ${g.dataOdbioruFmt}',
                  style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(100))),
              Text(
                g.wygasla
                    ? 'Wygasła: ${g.dataKoncaFmt}'
                    : 'Ważna do: ${g.dataKoncaFmt} (${g.dniDoKonca} dni)',
                style: TextStyle(
                  fontSize: 11,
                  color: g.wygasla
                      ? const Color(0xFF7B1F1F)
                      : g.wygasajaca
                          ? const Color(0xFF7B5E00)
                          : const Color(0xFF1E7A3A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (g.kontaktSerwisowy.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 13, color: theme.textColor.withAlpha(100)),
                const SizedBox(width: 4),
                Text(g.kontaktSerwisowy,
                    style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ZgloszeniaTab extends ConsumerWidget {
  final int budowaId;
  const _ZgloszeniaTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(zgloszeniaProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (zgloszenia) => zgloszenia.isEmpty
          ? Center(
              child: Text('Brak zgłoszeń serwisowych',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: zgloszenia.length,
              itemBuilder: (_, i) =>
                  _ZgloszenieTile(z: zgloszenia[i], theme: theme),
            ),
    );
  }
}

class _ZgloszenieTile extends ConsumerWidget {
  final ZgloszenieSerwisowModel z;
  final ThemeColors theme;
  const _ZgloszenieTile({required this.z, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (badgeLabel, badgeColor) = switch (z.status) {
      StatusZgloszenia.nowe => ('NOWE', const Color(0xFF7B5E00)),
      StatusZgloszenia.wTrakcie => ('W TRAKCIE', const Color(0xFF1A5E8A)),
      StatusZgloszenia.zrealizowane => ('ZREAL.', const Color(0xFF1E7A3A)),
      StatusZgloszenia.odrzucone => ('ODRZUC.', const Color(0xFF4A4A4A)),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(z.gwarancjaTytul,
                    style: TextStyle(
                        fontSize: 12, color: theme.textColor.withAlpha(140))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(badgeLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(z.opis,
              style: TextStyle(fontSize: 13, color: theme.textColor)),
          const SizedBox(height: 4),
          Text('${z.zglaszajacy} · ${z.dataZgloszenia2Fmt}',
              style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(100))),
          if (z.odpowiedz != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Odpowiedź: ${z.odpowiedz}',
                  style: TextStyle(
                      fontSize: 12, color: theme.textColor.withAlpha(160))),
            ),
          ],
          if (z.status == StatusZgloszenia.nowe ||
              z.status == StatusZgloszenia.wTrakcie) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (z.status == StatusZgloszenia.nowe)
                  _Btn('W trakcie', const Color(0xFF1A5E8A), () {
                    ref.read(zgloszeniaProvider.notifier).updateStatus(
                        z.id, StatusZgloszenia.wTrakcie);
                  }),
                const SizedBox(width: 8),
                _Btn('Zrealizowano', const Color(0xFF1E7A3A), () {
                  ref.read(zgloszeniaProvider.notifier).updateStatus(
                      z.id, StatusZgloszenia.zrealizowane);
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}
