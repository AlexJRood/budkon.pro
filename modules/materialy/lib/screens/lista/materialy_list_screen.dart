import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import '../../data/models/materialy_model.dart';
import '../../data/providers/materialy_provider.dart';
import '../../data/services/materialy_api.dart';
import '../../widgets/sparkline.dart';

class MaterialyListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const MaterialyListScreen({super.key, required this.budowaId, required this.budowaNazwa});

  @override
  ConsumerState<MaterialyListScreen> createState() => _MaterialyListScreenState();
}

class _MaterialyListScreenState extends ConsumerState<MaterialyListScreen> with SingleTickerProviderStateMixin {
  late final _sideMenuKey = GlobalKey<SideMenuState>();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(pozycjeProvider(widget.budowaId));

    final doZamowienia = state.lista.where((p) => p.status == StatusPozycji.doZamowienia).toList();
    final wTrakcie = state.lista.where((p) =>
        p.status == StatusPozycji.zamowione || p.status == StatusPozycji.wDostawie).toList();
    final dostarczone = state.lista.where((p) => p.status == StatusPozycji.dostarczone).toList();

    final content = Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(150),
          indicatorColor: theme.themeColor,
          tabs: [
            Tab(text: 'Do zamówienia (${doZamowienia.length})'),
            Tab(text: 'W trakcie (${wTrakcie.length})'),
            const Tab(text: 'Dostarczone'),
          ],
        ),
        Expanded(
          child: state.loading && state.lista.isEmpty
              ? Center(child: CircularProgressIndicator(color: theme.themeColor))
              : TabBarView(controller: _tabs, children: [
                  _ListaTab(pozycje: doZamowienia, budowaId: widget.budowaId, theme: theme,
                      emptyLabel: 'Brak materiałów do zamówienia', emptyIcon: Icons.check_circle_outline),
                  _ListaTab(pozycje: wTrakcie, budowaId: widget.budowaId, theme: theme,
                      emptyLabel: 'Brak zamówionych materiałów', emptyIcon: Icons.local_shipping_outlined),
                  _ListaTab(pozycje: dostarczone, budowaId: widget.budowaId, theme: theme,
                      emptyLabel: 'Brak dostarczonych materiałów', emptyIcon: Icons.inventory_2_outlined),
                ]),
        ),
      ],
    );

    return BarManager(
      sideMenuKey: _sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.trending_up, color: theme.textColor),
            tooltip: 'Trendy cen',
            onPressed: () => ref.read(navigationService).pushNamedScreen('/materialy/trendy'),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () => ref.read(pozycjeProvider(widget.budowaId).notifier).load(),
          ),
        ],
      ),
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (_tabs.index == 0)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                backgroundColor: theme.themeColor,
                icon: Icon(Icons.add, color: theme.buttonTextColor),
                label: Text('Dodaj', style: TextStyle(color: theme.buttonTextColor)),
                onPressed: () => _dodajPozycje(context, theme),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _dodajPozycje(BuildContext context, ThemeColors theme) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DodajPozycjeSheet(budowaId: widget.budowaId, theme: theme),
    );
    if (mounted) ref.read(pozycjeProvider(widget.budowaId).notifier).load();
  }
}

class _ListaTab extends StatelessWidget {
  final List<PozycjaZamowieniaModel> pozycje;
  final int budowaId;
  final ThemeColors theme;
  final String emptyLabel;
  final IconData emptyIcon;

  const _ListaTab({required this.pozycje, required this.budowaId, required this.theme,
      required this.emptyLabel, required this.emptyIcon});

  @override
  Widget build(BuildContext context) {
    if (pozycje.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(emptyIcon, size: 56, color: theme.textColor.withAlpha(80)),
        const SizedBox(height: 16),
        Text(emptyLabel, style: TextStyle(color: theme.textColor.withAlpha(150))),
      ]));
    }
    return Consumer(builder: (context, ref, _) => RefreshIndicator(
      onRefresh: () => ref.read(pozycjeProvider(budowaId).notifier).load(),
      color: theme.themeColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: pozycje.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _PozycjaCard(pozycja: pozycje[i], budowaId: budowaId, theme: theme),
      ),
    ));
  }
}

class _PozycjaCard extends ConsumerWidget {
  final PozycjaZamowieniaModel pozycja;
  final int budowaId;
  final ThemeColors theme;

  const _PozycjaCard({required this.pozycja, required this.budowaId, required this.theme});

  Color _statusColor(StatusPozycji s) => switch (s) {
    StatusPozycji.doZamowienia => theme.themeColor,
    StatusPozycji.zamowione => const Color(0xFF9C27B0),
    StatusPozycji.wDostawie => const Color(0xFFFF9800),
    StatusPozycji.dostarczone => const Color(0xFF4CAF50),
    StatusPozycji.zwrocone => Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mat = pozycja.material;
    final statusColor = _statusColor(pozycja.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _szczegoly(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(mat.kategoria.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mat.nazwa, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                if (mat.producent.isNotEmpty)
                  Text(mat.producent, style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12)),
              ])),
              TrendBadge(trend: mat.trend, showPorada: true),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _InfoChip(icon: Icons.inventory_2_outlined, label: pozycja.iloscStr, theme: theme),
              const SizedBox(width: 8),
              if (mat.cenaNetto != null)
                _InfoChip(icon: Icons.payments_outlined, label: '${mat.cenaFormatted}/${mat.jednostka}', theme: theme),
              const Spacer(),
              if (pozycja.wartoscNetto != null)
                Text('${pozycja.wartoscNetto!.toStringAsFixed(0)} PLN',
                    style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
            if (pozycja.dataPotrzeby != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.event, size: 13, color: theme.textColor.withAlpha(120)),
                const SizedBox(width: 4),
                Text('Potrzebne: ${pozycja.dataPotrzeby}',
                    style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Text(pozycja.status.label,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              TextButton.icon(
                icon: Icon(Icons.show_chart, size: 16, color: theme.themeColor),
                label: Text('Historia cen', style: TextStyle(color: theme.themeColor)),
                onPressed: () => ref.read(navigationService).pushNamedScreen(
                  '/materialy/historia',
                  data: {'material': mat},
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _szczegoly(BuildContext context, WidgetRef ref) async {
    final nowyStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _StatusSheet(pozycja: pozycja, theme: theme),
    );
    if (nowyStatus == null) return;
    try {
      final updated = await materialyApi.zmienStatus(pozycja.id, nowyStatus);
      ref.read(pozycjeProvider(budowaId).notifier).update(updated);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeColors theme;
  const _InfoChip({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: theme.textColor.withAlpha(120)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12)),
  ]);
}

class _StatusSheet extends StatelessWidget {
  final PozycjaZamowieniaModel pozycja;
  final ThemeColors theme;
  const _StatusSheet({required this.pozycja, required this.theme});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pozycja.material.nazwa,
            style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        ...StatusPozycji.values.map((s) => ListTile(
          title: Text(s.label, style: TextStyle(color: theme.textColor)),
          selected: s == pozycja.status,
          selectedColor: theme.themeColor,
          leading: Radio<StatusPozycji>(
            value: s, groupValue: pozycja.status,
            activeColor: theme.themeColor,
            onChanged: (_) => Navigator.pop(context, s.value),
          ),
          onTap: () => Navigator.pop(context, s.value),
        )),
      ]),
    ),
  );
}

class _DodajPozycjeSheet extends ConsumerStatefulWidget {
  final int budowaId;
  final ThemeColors theme;
  const _DodajPozycjeSheet({required this.budowaId, required this.theme});

  @override
  ConsumerState<_DodajPozycjeSheet> createState() => _DodajPozycjeSheetState();
}

class _DodajPozycjeSheetState extends ConsumerState<_DodajPozycjeSheet> {
  final _searchCtrl = TextEditingController();
  MaterialModel? _selected;
  final _iloscCtrl = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _iloscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final wyniki = ref.watch(materialPickerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        color: theme.mobileBackground,
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: theme.bordercolor.withAlpha(80), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Dodaj materiał',
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Szukaj w katalogu...',
                hintStyle: TextStyle(color: theme.textColor.withAlpha(80)),
                prefixIcon: Icon(Icons.search, color: theme.textColor.withAlpha(120)),
                filled: true,
                fillColor: theme.textFieldColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.bordercolor.withAlpha(60))),
                isDense: true,
              ),
              onChanged: (v) => ref.read(materialPickerProvider.notifier).szukaj(v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: wyniki.when(
              loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
              error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
              data: (lista) => ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final m = lista[i];
                  return ListTile(
                    leading: Text(m.kategoria.emoji, style: const TextStyle(fontSize: 20)),
                    title: Text(m.nazwa, style: TextStyle(color: theme.textColor)),
                    subtitle: Text('${m.cenaFormatted}/${m.jednostka}${m.producent.isNotEmpty ? '  •  ${m.producent}' : ''}',
                        style: TextStyle(color: theme.textColor.withAlpha(140))),
                    trailing: TrendBadge(trend: m.trend, showPorada: true),
                    selected: _selected?.id == m.id,
                    selectedTileColor: theme.themeColor.withAlpha(25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () => setState(() => _selected = m),
                  );
                },
              ),
            ),
          ),
          if (_selected != null) ...[
            Divider(color: theme.bordercolor.withAlpha(60)),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_selected!.nazwa,
                      style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
                  Text(_selected!.cenaFormatted,
                      style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12)),
                ])),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _iloscCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: _selected!.jednostka,
                      labelStyle: TextStyle(color: theme.textColor.withAlpha(160)),
                      filled: true, fillColor: theme.textFieldColor,
                      border: const OutlineInputBorder(), isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _dodaj,
                  style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
                  child: _saving
                      ? SizedBox.square(dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.buttonTextColor))
                      : Text('Dodaj', style: TextStyle(color: theme.buttonTextColor)),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _dodaj() async {
    final m = _selected;
    if (m == null) return;
    final ilosc = double.tryParse(_iloscCtrl.text.replaceAll(',', '.')) ?? 1;
    setState(() => _saving = true);
    try {
      await materialyApi.listaPozycji();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
    }
  }
}

class TrendyCenScreen extends ConsumerWidget {
  const TrendyCenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(trendyProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (trendy) {
          if (trendy.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_flat, size: 56, color: theme.textColor.withAlpha(80)),
              const SizedBox(height: 16),
              Text('Brak danych o trendach', style: TextStyle(color: theme.textColor)),
              const SizedBox(height: 8),
              Text('Dodaj historię cen dla materiałów',
                  style: TextStyle(color: theme.textColor.withAlpha(150))),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trendy.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final t = trendy[i];
              final trend = TrendCeny.fromValue(t['trend']?.toString());
              final cenySkrot = (t['historia_skrot'] as List? ?? [])
                  .map((c) => (c as num).toDouble()).toList();
              final zmianaProc = (t['zmiana_procent'] as num?)?.toDouble();
              final cenaNetto = (t['cena_netto'] as num?)?.toDouble();

              return Container(
                decoration: BoxDecoration(
                  color: theme.userTile,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.bordercolor.withAlpha(60)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((t['nazwa'] ?? '').toString(),
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      if (cenaNetto != null)
                        Text('${cenaNetto.toStringAsFixed(2)} PLN',
                            style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12)),
                      const SizedBox(height: 4),
                      if (trend == TrendCeny.rosnacy)
                        Text(trend!.porada, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11, fontWeight: FontWeight.w600))
                      else if (trend == TrendCeny.spadajacy)
                        Text(trend!.porada, style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600)),
                    ])),
                    const SizedBox(width: 12),
                    PriceSparkline(ceny: cenySkrot, trend: trend, width: 80, height: 36),
                    const SizedBox(width: 10),
                    TrendBadge(trend: trend, zmianaProc: zmianaProc, showPorada: false),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
