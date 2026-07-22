import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import '../../data/models/rozliczenia_model.dart';
import '../../data/providers/rozliczenia_provider.dart';
import '../../widgets/faktura_card.dart';

class RozliczeniaListScreen extends ConsumerWidget {
  final int budowaId;
  final String budowaNazwa;

  const RozliczeniaListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final fakturyAsync = ref.watch(fakturyProvider(budowaId));
    final statsAsync = ref.watch(rozliczeniaStatsProvider(budowaId));

    return Scaffold(
      backgroundColor: theme.scaffoldColor,
      appBar: AppBar(
        backgroundColor: theme.userTile,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rozliczenia',
                style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(budowaNazwa,
                style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 11)),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Stats header
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => const SizedBox(height: 8),
              error: (_, __) => const SizedBox(height: 8),
              data: (stats) => _StatsHeader(stats: stats, theme: theme),
            ),
          ),

          // Faktury lista
          fakturyAsync.when(
            loading: () => SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator(color: theme.themeColor)),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Błąd: $e', style: TextStyle(color: Colors.red.shade400))),
            ),
            data: (faktury) => faktury.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Brak faktur',
                            style: TextStyle(color: theme.textColor.withAlpha(100))),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FakturaCard(
                        faktura: faktury[i],
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/rozliczenia/faktura/${faktury[i].id}',
                        ),
                      ),
                      childCount: faktury.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Nowa faktura'),
        onPressed: () => Navigator.pushNamed(
          context,
          '/rozliczenia/$budowaId/nowa-faktura',
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final BudowaRozliczeniaStats stats;
  final ThemeColors theme;
  const _StatsHeader({required this.stats, required this.theme});

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
                _Stat('Kontrakt', _money(stats.wartoscKontraktu), theme),
                _Stat('Zafakturowano', _money(stats.fakturowanoLacznie), theme),
                _Stat('Opłacono', _money(stats.oplaconoLacznie), theme,
                    color: const Color(0xFF1E7A3A)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.postepFakturowania,
                backgroundColor: theme.bordercolor.withAlpha(40),
                color: theme.themeColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Postęp fakturowania: ${(stats.postepFakturowania * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: theme.textColor.withAlpha(120)),
                ),
                if (stats.fakturaOczekujace > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B5E00).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${stats.fakturaOczekujace} oczekuje',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF7B5E00), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      );

  String _money(double v) =>
      '${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]} ')} zł';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeColors theme;
  final Color? color;
  const _Stat(this.label, this.value, this.theme, {this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: theme.textColor.withAlpha(120))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color ?? theme.textColor)),
        ],
      );
}
