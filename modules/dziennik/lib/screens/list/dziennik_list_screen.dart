import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';
import '../../widgets/pogoda_badge.dart';

class DziennikListScreen extends ConsumerStatefulWidget {
  final int budowaId;
  final String budowaNazwa;

  const DziennikListScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  ConsumerState<DziennikListScreen> createState() => _DziennikListScreenState();
}

class _DziennikListScreenState extends ConsumerState<DziennikListScreen> {
  static final _fmt = DateFormat('dd.MM.yyyy', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dziennikListProvider(widget.budowaId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dziennik budowy'),
            Text(
              widget.budowaNazwa,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa budowy',
            onPressed: () => Navigator.pushNamed(
              context,
              '/dziennik/mapa',
              arguments: {'budowaId': widget.budowaId, 'budowaNazwa': widget.budowaNazwa},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(dziennikListProvider(widget.budowaId).notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nowy wpis'),
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/dziennik/form',
            arguments: {
              'budowaId': widget.budowaId,
              'budowaNazwa': widget.budowaNazwa,
            },
          );
          if (result == true) {
            ref
                .read(dziennikListProvider(widget.budowaId).notifier)
                .load();
          }
        },
      ),
      body: Builder(builder: (_) {
        if (state.loading && state.wpisy.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.wpisy.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.error!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(dziennikListProvider(widget.budowaId).notifier)
                      .load(),
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          );
        }
        if (state.wpisy.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Brak wpisów',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Dodaj pierwszy wpis do dziennika budowy'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(dziennikListProvider(widget.budowaId).notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: state.wpisy.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _WpisCard(
              wpis: state.wpisy[i],
              budowaId: widget.budowaId,
              budowaNazwa: widget.budowaNazwa,
            ),
          ),
        );
      }),
    );
  }
}

class _WpisCard extends StatelessWidget {
  final WpisListItem wpis;
  final int budowaId;
  final String budowaNazwa;

  const _WpisCard({
    required this.wpis,
    required this.budowaId,
    required this.budowaNazwa,
  });

  static final _fmt = DateFormat('dd.MM.yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/dziennik/detail',
          arguments: {
            'wpisId': wpis.id,
            'budowaId': budowaId,
            'budowaNazwa': budowaNazwa,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fmt.format(wpis.data),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  PogodaBadge(pogoda: wpis.pogoda, temperatura: wpis.temperatura),
                ],
              ),
              if (wpis.etapNazwa != null) ...[
                const SizedBox(height: 6),
                _Chip(
                  icon: Icons.construction,
                  label: wpis.etapNazwa!,
                  color: cs.primaryContainer,
                ),
              ],
              if (wpis.opis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  wpis.opis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _Chip(
                    icon: Icons.people_outline,
                    label: '${wpis.liczbaPracownikow} os.',
                    color: cs.secondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.schedule,
                    label: '${wpis.godzinyPracy.toStringAsFixed(0)} h',
                    color: cs.tertiaryContainer,
                  ),
                  if (wpis.zdjeciaCount > 0) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.photo_library_outlined,
                      label: '${wpis.zdjeciaCount}',
                      color: cs.surfaceContainerHighest,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
