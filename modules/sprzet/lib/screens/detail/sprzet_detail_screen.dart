import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/sprzet_model.dart';
import '../../data/providers/sprzet_provider.dart';
import '../../widgets/sprzet_status_badge.dart';

class SprzetDetailScreen extends ConsumerStatefulWidget {
  final int sprzetId;
  const SprzetDetailScreen({super.key, required this.sprzetId});

  @override
  ConsumerState<SprzetDetailScreen> createState() => _SprzetDetailScreenState();
}

class _SprzetDetailScreenState extends ConsumerState<SprzetDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(sprzetProvider(widget.sprzetId).notifier).init(widget.sprzetId);
  }

  void _showWypozyczSheet(ThemeColors theme, SprzetModel sprzet) {
    final budowaCtrl = TextEditingController();
    final pracownikCtrl = TextEditingController();

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
            Text('Wypożycz sprzęt',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 12),
            TextField(
              controller: budowaCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _inputDec('Budowa / lokalizacja', theme),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pracownikCtrl,
              style: TextStyle(color: theme.textColor),
              decoration: _inputDec('Odpowiedzialny pracownik', theme),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.themeColor, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(sprzetProvider(widget.sprzetId).notifier)
                      .setStatus(StatusSprzetu.uzyciu);
                },
                child: const Text('Potwierdź wypożyczenie'),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(sprzetProvider(widget.sprzetId));
    final wypozyczenieAsync = ref.watch(wypozyczenieProvider(widget.sprzetId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
        data: (sprzet) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.userTile,
              pinned: true,
              title: Row(
                children: [
                  Text(sprzet.kategoria.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sprzet.nazwa,
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<StatusSprzetu>(
                  icon: Icon(Icons.more_vert, color: theme.textColor),
                  color: theme.userTile,
                  onSelected: (s) {
                    if (s == StatusSprzetu.uzyciu) {
                      _showWypozyczSheet(theme, sprzet);
                    } else {
                      ref.read(sprzetProvider(widget.sprzetId).notifier).setStatus(s);
                    }
                  },
                  itemBuilder: (_) => StatusSprzetu.values
                      .where((s) => s != sprzet.status)
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Text(s.label,
                                style: TextStyle(color: theme.textColor, fontSize: 13)),
                          ))
                      .toList(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.userTile,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.bordercolor.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status',
                            style: TextStyle(
                                fontSize: 11, color: theme.textColor.withAlpha(120))),
                        SprzetStatusBadge(status: sprzet.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoRow('Kategoria', sprzet.kategoria.label, theme),
                    if (sprzet.nrSeryjny != null)
                      _InfoRow('Nr seryjny', sprzet.nrSeryjny!, theme),
                    if (sprzet.nrRejestracyjny != null)
                      _InfoRow('Nr rej.', sprzet.nrRejestracyjny!, theme),
                    if (sprzet.lokalizacja != null)
                      _InfoRow('Lokalizacja', sprzet.lokalizacja!, theme),
                    if (sprzet.dataKoncaFmt != null) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.engineering_outlined,
                            size: 14,
                            color: sprzet.przegladWygasl
                                ? const Color(0xFF7B1F1F)
                                : sprzet.przegladWygasa
                                    ? const Color(0xFF7B5E00)
                                    : const Color(0xFF1E7A3A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Przegląd ważny do: ${sprzet.dataKoncaFmt}',
                            style: TextStyle(
                              fontSize: 12,
                              color: sprzet.przegladWygasl
                                  ? const Color(0xFF7B1F1F)
                                  : sprzet.przegladWygasa
                                      ? const Color(0xFF7B5E00)
                                      : const Color(0xFF1E7A3A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (sprzet.uwagi.isNotEmpty) ...[
                      const Divider(height: 16),
                      Text(sprzet.uwagi,
                          style: TextStyle(
                              fontSize: 12, color: theme.textColor.withAlpha(140))),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Historia wypożyczeń',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: theme.textColor.withAlpha(180))),
              ),
            ),
            wypozyczenieAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (wypozyczenia) => wypozyczenia.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('Brak historii',
                              style:
                                  TextStyle(color: theme.textColor.withAlpha(100))),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _WypozyczenieTile(w: wypozyczenia[i], theme: theme),
                        childCount: wypozyczenia.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  const _InfoRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: theme.textColor.withAlpha(120))),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 12, color: theme.textColor)),
            ),
          ],
        ),
      );
}

class _WypozyczenieTile extends StatelessWidget {
  final WypozyczenieModel w;
  final ThemeColors theme;
  const _WypozyczenieTile({required this.w, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: w.aktywne
                    ? theme.themeColor.withAlpha(25)
                    : const Color(0xFF1E7A3A).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                w.aktywne ? Icons.construction : Icons.check,
                size: 18,
                color: w.aktywne ? theme.themeColor : const Color(0xFF1E7A3A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.budowaNazwa.isEmpty ? 'Budowa #${w.budowaId}' : w.budowaNazwa,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                  Text('${w.pracownik} · ${w.dataOdFmt}${w.dataDoFmt != null ? ' – ${w.dataDoFmt}' : ''}',
                      style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120))),
                ],
              ),
            ),
            if (w.aktywne)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.themeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('AKTYWNE',
                    style: TextStyle(
                        fontSize: 10, color: theme.themeColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      );
}
