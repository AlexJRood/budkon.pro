import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../data/models/bhp_model.dart';
import '../data/providers/bhp_provider.dart';

class BhpScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const BhpScreen({super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<BhpScreen> createState() => _BhpScreenState();
}

class _BhpScreenState extends ConsumerState<BhpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bhpSzkoleniaProvider.notifier).init(widget.budowaId);
      ref.read(bhpWypadkiProvider.notifier).init(widget.budowaId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddSzkolenie(ThemeColors theme) {
    TypSzkolenia typ = TypSzkolenia.wstepne;
    final pracownikCtrl = TextEditingController();
    DateTime dataSzkolenia = DateTime.now();
    DateTime dataWaznosci = DateTime.now().add(const Duration(days: 365));

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
              Text('Dodaj szkolenie BHP',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TypSzkolenia.values.map((t) {
                  final sel = typ == t;
                  return GestureDetector(
                    onTap: () => set(() => typ = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? theme.themeColor.withAlpha(40) : theme.userTile,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? theme.themeColor : theme.bordercolor.withAlpha(60)),
                      ),
                      child: Text(t.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: sel ? theme.themeColor : theme.textColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pracownikCtrl,
                style: TextStyle(color: theme.textColor),
                decoration: _inputDec('Pracownik (imię i nazwisko)', theme),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _datePick('Data szkolenia', dataSzkolenia,
                      (d) => set(() => dataSzkolenia = d), theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _datePick('Ważne do', dataWaznosci,
                      (d) => set(() => dataWaznosci = d), theme)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (pracownikCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await ref.read(bhpSzkoleniaProvider.notifier).add(
                          SzkolenieBhpModel(
                            id: 0,
                            pracownikId: 0,
                            pracownikImie: pracownikCtrl.text.trim(),
                            typ: typ,
                            dataSzkolenia: dataSzkolenia,
                            dataWaznosci: dataWaznosci,
                          ),
                        );
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

  void _showAddWypadek(ThemeColors theme) {
    final opisCtrl = TextEditingController();
    final poszkodowanyCtrl = TextEditingController();
    final miejsceCtrl = TextEditingController();
    bool wezwano = false;
    DateTime data = DateTime.now();

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
              Text('Zgłoś wypadek / zdarzenie',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
              const SizedBox(height: 10),
              TextField(
                controller: opisCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.textColor),
                decoration: _inputDec('Opis zdarzenia *', theme),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: poszkodowanyCtrl,
                style: TextStyle(color: theme.textColor),
                decoration: _inputDec('Poszkodowany (imię i nazwisko)', theme),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: miejsceCtrl,
                style: TextStyle(color: theme.textColor),
                decoration: _inputDec('Miejsce zdarzenia', theme),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => set(() => wezwano = !wezwano),
                child: Row(
                  children: [
                    Icon(
                      wezwano ? Icons.check_box : Icons.check_box_outline_blank,
                      color: wezwano ? theme.themeColor : theme.textColor.withAlpha(80),
                    ),
                    const SizedBox(width: 8),
                    Text('Wezwano służby ratunkowe',
                        style: TextStyle(fontSize: 13, color: theme.textColor)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1F1F),
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    if (opisCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await ref.read(bhpWypadkiProvider.notifier).add(WypadekModel(
                          id: 0,
                          budowaId: widget.budowaId,
                          opis: opisCtrl.text.trim(),
                          dataZdarzenia: data,
                          poszkodowany: poszkodowanyCtrl.text.trim().isEmpty
                              ? null
                              : poszkodowanyCtrl.text.trim(),
                          miejsceZdarzenia: miejsceCtrl.text.trim().isEmpty
                              ? null
                              : miejsceCtrl.text.trim(),
                          wezwanoSluzby: wezwano,
                        ));
                  },
                  child: const Text('Zgłoś zdarzenie'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, ThemeColors theme) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _datePick(String label, DateTime value, ValueChanged<DateTime> onChanged,
          ThemeColors theme) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2020),
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

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BHP',
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
          tabs: const [
            Tab(text: 'Szkolenia'),
            Tab(text: 'Wypadki'),
            Tab(text: 'Instrukcje'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _SzkoleniaTab(budowaId: widget.budowaId),
          _WypadkiTab(budowaId: widget.budowaId),
          _InstrukcjeTab(budowaId: widget.budowaId),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          backgroundColor:
              _tabCtrl.index == 1 ? const Color(0xFF7B1F1F) : theme.themeColor,
          foregroundColor: Colors.white,
          icon: Icon(_tabCtrl.index == 1 ? Icons.warning_amber : Icons.add),
          label: Text(
            _tabCtrl.index == 0
                ? 'Dodaj szkolenie'
                : _tabCtrl.index == 1
                    ? 'Zgłoś zdarzenie'
                    : 'Dodaj',
          ),
          onPressed: () {
            if (_tabCtrl.index == 0) _showAddSzkolenie(theme);
            if (_tabCtrl.index == 1) _showAddWypadek(theme);
          },
        ),
      ),
    );
  }
}

class _SzkoleniaTab extends ConsumerWidget {
  final int budowaId;
  const _SzkoleniaTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(bhpSzkoleniaProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (szkolenia) {
        final alerty = szkolenia.where((s) => s.wygaslo || s.wygasa).toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            if (alerty.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1F1F).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7B1F1F).withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFF7B1F1F), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${alerty.length} szkoleń wygasło lub wygasa wkrótce',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7B1F1F),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ...szkolenia.map((s) => _SzkolenieTile(szkolenie: s, theme: theme)),
          ],
        );
      },
    );
  }
}

class _SzkolenieTile extends StatelessWidget {
  final SzkolenieBhpModel szkolenie;
  final ThemeColors theme;
  const _SzkolenieTile({required this.szkolenie, required this.theme});

  @override
  Widget build(BuildContext context) {
    final alertColor = szkolenie.wygaslo
        ? const Color(0xFF7B1F1F)
        : szkolenie.wygasa
            ? const Color(0xFF7B5E00)
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: alertColor?.withAlpha(100) ?? theme.bordercolor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (alertColor ?? theme.themeColor).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined,
                size: 20, color: alertColor ?? theme.themeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(szkolenie.pracownikImie,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                Text(szkolenie.typ.label,
                    style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Ważne do:',
                  style: TextStyle(fontSize: 10, color: theme.textColor.withAlpha(100))),
              Text(
                szkolenie.dataWaznosciFmt,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: alertColor ?? const Color(0xFF1E7A3A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WypadkiTab extends ConsumerWidget {
  final int budowaId;
  const _WypadkiTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(bhpWypadkiProvider);

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (wypadki) => wypadki.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF1E7A3A)),
                  const SizedBox(height: 12),
                  Text('Brak wypadków i zdarzeń',
                      style: TextStyle(color: theme.textColor, fontSize: 14)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: wypadki.length,
              itemBuilder: (_, i) => _WypadekTile(wypadek: wypadki[i], theme: theme),
            ),
    );
  }
}

class _WypadekTile extends ConsumerWidget {
  final WypadekModel wypadek;
  final ThemeColors theme;
  const _WypadekTile({required this.wypadek, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (badgeLabel, badgeColor) = switch (wypadek.status) {
      StatusWypadku.zgloszony => ('ZGŁOSZONY', const Color(0xFF7B5E00)),
      StatusWypadku.wTrakcie => ('W TRAKCIE', const Color(0xFF1A5E8A)),
      StatusWypadku.zamkniety => ('ZAMKNIĘTY', const Color(0xFF3A3A3A)),
      StatusWypadku.skierowany => ('→ PIP', const Color(0xFF7B1F1F)),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B1F1F).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF7B1F1F), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(wypadek.dataFmt,
                    style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(140))),
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
          const SizedBox(height: 8),
          Text(wypadek.opis,
              style: TextStyle(fontSize: 13, color: theme.textColor)),
          if (wypadek.poszkodowany != null) ...[
            const SizedBox(height: 4),
            Text('Poszkodowany: ${wypadek.poszkodowany}',
                style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(130))),
          ],
          if (wypadek.wezwanoSluzby) ...[
            const SizedBox(height: 4),
            Text('⚠️ Wezwano służby ratunkowe',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF7B1F1F), fontWeight: FontWeight.w600)),
          ],
          if (wypadek.status == StatusWypadku.zgloszony ||
              wypadek.status == StatusWypadku.wTrakcie) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _Btn('Zamknij', const Color(0xFF3A3A3A), () {
                  ref.read(bhpWypadkiProvider.notifier).updateStatus(
                      wypadek.id, StatusWypadku.zamkniety);
                }),
                const SizedBox(width: 8),
                _Btn('→ PIP', const Color(0xFF7B1F1F), () {
                  ref.read(bhpWypadkiProvider.notifier).updateStatus(
                      wypadek.id, StatusWypadku.skierowany);
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

class _InstrukcjeTab extends ConsumerWidget {
  final int budowaId;
  const _InstrukcjeTab({required this.budowaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(bhpInstrukcjeProvider(budowaId));

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) =>
          Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
      data: (instrukcje) => instrukcje.isEmpty
          ? Center(
              child: Text('Brak instrukcji BHP',
                  style: TextStyle(color: theme.textColor.withAlpha(100))))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: instrukcje.length,
              itemBuilder: (_, i) {
                final ins = instrukcje[i];
                return ExpansionTile(
                  iconColor: theme.themeColor,
                  collapsedIconColor: theme.textColor.withAlpha(80),
                  title: Text(ins.tytul,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(ins.tresc,
                          style: TextStyle(
                              fontSize: 12, color: theme.textColor.withAlpha(160))),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
