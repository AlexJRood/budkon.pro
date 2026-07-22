import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/sprzet_model.dart';
import '../../data/providers/sprzet_provider.dart';
import '../../widgets/sprzet_card.dart';

class SprzetListScreen extends ConsumerStatefulWidget {
  final int? budowaId;
  final String? budowaNazwa;

  const SprzetListScreen({super.key, this.budowaId, this.budowaNazwa});

  @override
  ConsumerState<SprzetListScreen> createState() => _SprzetListScreenState();
}

class _SprzetListScreenState extends ConsumerState<SprzetListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  StatusSprzetu? _statusFilter;

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
    final async = ref.watch(sprzetListProvider(widget.budowaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sprzęt i narzędzia',
                style: TextStyle(
                    color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            if (widget.budowaNazwa != null)
              Text(widget.budowaNazwa!,
                  style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: theme.themeColor,
          labelColor: theme.themeColor,
          unselectedLabelColor: theme.textColor.withAlpha(120),
          tabs: const [
            Tab(text: 'Sprzęt'),
            Tab(text: 'Przeglądy'),
          ],
        ),
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
        data: (lista) => TabBarView(
          controller: _tabCtrl,
          children: [
            _SprzetTab(lista: lista, statusFilter: _statusFilter,
                onFilterChanged: (s) => setState(() => _statusFilter = s)),
            _PrzegladTab(lista: lista),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj sprzęt'),
        onPressed: () =>
            Navigator.pushNamed(context, '/sprzet/nowy', arguments: widget.budowaId),
      ),
    );
  }
}

class _SprzetTab extends StatelessWidget {
  final List<SprzetModel> lista;
  final StatusSprzetu? statusFilter;
  final ValueChanged<StatusSprzetu?> onFilterChanged;

  const _SprzetTab({
    required this.lista,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = statusFilter == null
        ? lista
        : lista.where((s) => s.status == statusFilter).toList();

    return Column(
      children: [
        _StatusFilterRow(selected: statusFilter, onChanged: onFilterChanged),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Brak sprzętu'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => SprzetCard(
                    sprzet: filtered[i],
                    onTap: () => Navigator.pushNamed(
                        context, '/sprzet/${filtered[i].id}'),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PrzegladTab extends ConsumerWidget {
  final List<SprzetModel> lista;
  const _PrzegladTab({required this.lista});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final alerty = ref.read(przegladAlertyProvider(lista));

    if (alerty.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF1E7A3A)),
            const SizedBox(height: 12),
            Text('Wszystkie przeglądy aktualne',
                style: TextStyle(color: theme.textColor, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('${alerty.length} sprzętów wymaga przeglądu',
              style: TextStyle(
                  fontSize: 12, color: theme.textColor.withAlpha(150), fontWeight: FontWeight.w600)),
        ),
        ...alerty.map((s) => SprzetCard(sprzet: s)),
      ],
    );
  }
}

class _StatusFilterRow extends ConsumerWidget {
  final StatusSprzetu? selected;
  final ValueChanged<StatusSprzetu?> onChanged;
  const _StatusFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _FChip('Wszystkie', selected == null, theme, () => onChanged(null)),
          ...StatusSprzetu.values.map((s) => _FChip(
                s.label,
                selected == s,
                theme,
                () => onChanged(selected == s ? null : s),
              )),
        ],
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors theme;
  final VoidCallback onTap;
  const _FChip(this.label, this.selected, this.theme, this.onTap);

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
                  color: selected ? theme.themeColor : theme.textColor)),
        ),
      );
}
