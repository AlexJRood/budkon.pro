import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/magazyn_model.dart';
import '../../data/providers/magazyn_provider.dart';
import '../../widgets/stan_badge.dart';
import '../../widgets/ruch_tile.dart';

class PozycjaDetailScreen extends ConsumerStatefulWidget {
  final int pozycjaId;

  const PozycjaDetailScreen({super.key, required this.pozycjaId});

  @override
  ConsumerState<PozycjaDetailScreen> createState() => _PozycjaDetailScreenState();
}

class _PozycjaDetailScreenState extends ConsumerState<PozycjaDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(pozycjaProvider(widget.pozycjaId).notifier).init(widget.pozycjaId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(pozycjaProvider(widget.pozycjaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      body: async.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
        data: (state) => CustomScrollView(
          slivers: [
            _AppBar(pozycja: state.pozycja, theme: theme),
            SliverToBoxAdapter(child: _StanSummary(pozycja: state.pozycja, theme: theme)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text('Historia ruchów',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor.withAlpha(180))),
              ),
            ),
            if (state.ruchy.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Brak ruchów',
                        style: TextStyle(color: theme.textColor.withAlpha(100))),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => RuchTile(ruch: state.ruchy[i]),
                  childCount: state.ruchy.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: async.valueOrNull != null
          ? _AddRuchFab(pozycjaId: widget.pozycjaId)
          : null,
    );
  }
}

class _AppBar extends StatelessWidget {
  final MagazynPozycjaModel pozycja;
  final ThemeColors theme;
  const _AppBar({required this.pozycja, required this.theme});

  @override
  Widget build(BuildContext context) => SliverAppBar(
        backgroundColor: theme.userTile,
        pinned: true,
        title: Row(
          children: [
            Text(pozycja.kategoria.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(pozycja.nazwa,
                  style: TextStyle(
                      color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

class _StanSummary extends StatelessWidget {
  final MagazynPozycjaModel pozycja;
  final ThemeColors theme;
  const _StanSummary({required this.pozycja, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.userTile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.bordercolor.withAlpha(50)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatBox(
                    label: 'Stan aktualny',
                    value: '${pozycja.stanAktualny.toStringAsFixed(1)} ${pozycja.jednostka}',
                    color: theme.textColor,
                    theme: theme),
                _StatBox(
                    label: 'Stan minimalny',
                    value: '${pozycja.stanMinimalny.toStringAsFixed(1)} ${pozycja.jednostka}',
                    color: theme.textColor.withAlpha(150),
                    theme: theme),
                Column(
                  children: [
                    Text('Status',
                        style: TextStyle(fontSize: 10, color: theme.textColor.withAlpha(120))),
                    const SizedBox(height: 4),
                    StanBadge(pozycja: pozycja),
                  ],
                ),
              ],
            ),
            if (pozycja.cenaJednostkowa > 0) ...[
              const SizedBox(height: 12),
              Divider(color: theme.bordercolor.withAlpha(40)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cena jedn.: ${pozycja.cenaJednostkowa.toStringAsFixed(2)} zł',
                      style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(150))),
                  Text('Wartość: ${pozycja.wartoscCalkowita.toStringAsFixed(2)} zł',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: theme.themeColor)),
                ],
              ),
            ],
            if (pozycja.dostawca != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 14, color: theme.textColor.withAlpha(100)),
                  const SizedBox(width: 6),
                  Text(pozycja.dostawca!,
                      style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(120))),
                ],
              ),
            ],
          ],
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeColors theme;
  const _StatBox({required this.label, required this.value, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: theme.textColor.withAlpha(120))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

class _AddRuchFab extends ConsumerStatefulWidget {
  final int pozycjaId;
  const _AddRuchFab({required this.pozycjaId});

  @override
  ConsumerState<_AddRuchFab> createState() => _AddRuchFabState();
}

class _AddRuchFabState extends ConsumerState<_AddRuchFab> {
  void _showSheet(TypRuchu typ) {
    final theme = ref.read(themeColorsProvider);
    final iloscCtrl = TextEditingController();
    final uwagiCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.userTile,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${typ.label} — wpisz ilość',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 12),
            TextField(
              controller: iloscCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                labelText: 'Ilość',
                labelStyle: TextStyle(color: theme.textColor.withAlpha(150)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: uwagiCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                labelText: 'Uwagi (opcjonalnie)',
                labelStyle: TextStyle(color: theme.textColor.withAlpha(150)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  final ilosc =
                      double.tryParse(iloscCtrl.text.replaceAll(',', '.')) ??
                          0;
                  if (ilosc <= 0) return;
                  Navigator.pop(context);
                  await ref
                      .read(pozycjaProvider(widget.pozycjaId).notifier)
                      .addRuch(MagazynRuchModel(
                        id: 0,
                        pozycjaId: widget.pozycjaId,
                        pozycjaNazwa: '',
                        typ: typ,
                        ilosc: ilosc,
                        data: DateTime.now(),
                        uwaga: uwagiCtrl.text.trim().isEmpty
                            ? null
                            : uwagiCtrl.text.trim(),
                      ));
                },
                child: const Text('Zapisz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'zuzycie',
          backgroundColor: theme.themeColor,
          foregroundColor: Colors.white,
          onPressed: () => _showSheet(TypRuchu.zuzycie),
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'dostawa',
          backgroundColor: const Color(0xFF1E7A3A),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Dostawa'),
          onPressed: () => _showSheet(TypRuchu.dostawa),
        ),
      ],
    );
  }
}
