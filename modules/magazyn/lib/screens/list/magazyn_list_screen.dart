import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/magazyn_model.dart';
import '../../data/providers/magazyn_provider.dart';
import '../../widgets/pozycja_card.dart';

class MagazynListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const MagazynListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<MagazynListScreen> createState() => _MagazynListScreenState();
}

class _MagazynListScreenState extends ConsumerState<MagazynListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  KategoriaMaterialu? _filterKat;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(pozycjeProvider(widget.budowaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magazyn',
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
            Tab(text: 'Stan magazynu'),
            Tab(text: 'Alerty'),
          ],
        ),
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(
          child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400)),
        ),
        data: (pozycje) => TabBarView(
          controller: _tabCtrl,
          children: [
            _StanTab(pozycje: pozycje, filterKat: _filterKat,
                onFilterChanged: (k) => setState(() => _filterKat = k)),
            _AlertyTab(pozycje: pozycje),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj pozycję'),
        onPressed: () => Navigator.pushNamed(
          context,
          '/magazyn/${widget.budowaId}/nowa-pozycja',
        ),
      ),
    );
  }
}

class _StanTab extends StatelessWidget {
  final List<MagazynPozycjaModel> pozycje;
  final KategoriaMaterialu? filterKat;
  final ValueChanged<KategoriaMaterialu?> onFilterChanged;

  const _StanTab({
    required this.pozycje,
    required this.filterKat,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = filterKat == null
        ? pozycje
        : pozycje.where((p) => p.kategoria == filterKat).toList();

    // Grupuj po kategorii
    final grouped = <KategoriaMaterialu, List<MagazynPozycjaModel>>{};
    for (final p in filtered) {
      grouped.putIfAbsent(p.kategoria, () => []).add(p);
    }

    return ListView(
      children: [
        _KatFilterRow(selected: filterKat, onChanged: onFilterChanged),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('Brak pozycji', style: TextStyle(color: Colors.grey.shade500)),
            ),
          )
        else
          ...grouped.entries.expand((e) => [
                _KatHeader(kategoria: e.key),
                ...e.value.map((p) => PozycjaCard(
                      pozycja: p,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/magazyn/pozycja/${p.id}',
                      ),
                    )),
              ]),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _AlertyTab extends ConsumerWidget {
  final List<MagazynPozycjaModel> pozycje;
  const _AlertyTab({required this.pozycje});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final alerty = pozycje.where((p) => p.niski || p.pusty).toList();

    if (alerty.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: const Color(0xFF1E7A3A)),
            const SizedBox(height: 12),
            Text('Wszystkie stany w normie',
                style: TextStyle(color: theme.textColor, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('${alerty.length} pozycji wymaga uwagi',
              style: TextStyle(
                  fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
        ),
        ...alerty.map((p) => PozycjaCard(pozycja: p)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _KatFilterRow extends ConsumerWidget {
  final KategoriaMaterialu? selected;
  final ValueChanged<KategoriaMaterialu?> onChanged;
  const _KatFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _FilterChip(label: 'Wszystkie', selected: selected == null,
              theme: theme, onTap: () => onChanged(null)),
          ...KategoriaMaterialu.values.map((k) => _FilterChip(
                label: '${k.emoji} ${k.label}',
                selected: selected == k,
                theme: theme,
                onTap: () => onChanged(selected == k ? null : k),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors theme;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? theme.themeColor.withAlpha(40) : theme.userTile,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? theme.themeColor : theme.bordercolor.withAlpha(60)),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? theme.themeColor : theme.textColor,
              )),
        ),
      );
}

class _KatHeader extends ConsumerWidget {
  final KategoriaMaterialu kategoria;
  const _KatHeader({required this.kategoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        '${kategoria.emoji}  ${kategoria.label}',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: theme.textColor.withAlpha(150)),
      ),
    );
  }
}
