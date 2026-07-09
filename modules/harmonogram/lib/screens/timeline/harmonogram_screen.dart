import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/harmonogram_model.dart';
import '../../data/providers/harmonogram_provider.dart';
import '../../data/services/harmonogram_api.dart';
import '../../widgets/gantt_bar.dart';
import '../../widgets/milestone_chip.dart';

class HarmonogramScreen extends ConsumerWidget {
  final int budowaId;
  final String budowaNazwa;

  const HarmonogramScreen({
    super.key,
    required this.budowaId,
    required this.budowaNazwa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineProvider(budowaId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Harmonogram'),
            Text(
              budowaNazwa,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(timelineProvider(budowaId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: e.toString(),
          budowaId: budowaId,
          onRetry: () => ref.invalidate(timelineProvider(budowaId)),
          onAutoGenerate: () async {
            await harmonogramApi.autoGeneruj(budowaId);
            ref.invalidate(timelineProvider(budowaId));
          },
        ),
        data: (data) {
          if (data.etapy.isEmpty) {
            return _EmptyView(
              budowaId: budowaId,
              onAutoGenerate: () async {
                await harmonogramApi.autoGeneruj(budowaId);
                ref.invalidate(timelineProvider(budowaId));
              },
            );
          }
          return _TimelineBody(data: data, budowaId: budowaId);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task),
        label: const Text('Nowe zadanie'),
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/harmonogram/zadanie/form',
            arguments: {'budowaId': budowaId, 'budowaNazwa': budowaNazwa},
          );
          if (result == true) ref.invalidate(timelineProvider(budowaId));
        },
      ),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  final TimelineData data;
  final int budowaId;

  const _TimelineBody({required this.data, required this.budowaId});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Podsumowanie dat budowy
        SliverToBoxAdapter(
          child: _BudowaDatesHeader(data: data),
        ),

        // Milestones
        if (data.milestones.isNotEmpty)
          SliverToBoxAdapter(
            child: _MilestonesRow(milestones: data.milestones),
          ),

        // Etapy z zadaniami
        for (final etap in data.etapy) ...[
          SliverToBoxAdapter(
            child: _EtapHeader(etap: etap, projectStart: data.effectiveStart, projectEnd: data.effectiveEnd),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ZadanieRow(
                zadanie: etap.zadania[i],
                projectStart: data.effectiveStart,
                projectEnd: data.effectiveEnd,
                budowaId: budowaId,
              ),
              childCount: etap.zadania.length,
            ),
          ),
        ],

        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ---- Sub-widgety -------------------------------------------------------

class _BudowaDatesHeader extends StatelessWidget {
  final TimelineData data;
  const _BudowaDatesHeader({required this.data});

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateCol(
              label: 'Rozpoczęcie',
              date: data.dataStart,
              icon: Icons.play_arrow,
            ),
          ),
          Container(width: 1, height: 40, color: cs.outline.withOpacity(0.3)),
          Expanded(
            child: _DateCol(
              label: 'Planowane zakończenie',
              date: data.dataKoniec,
              icon: Icons.flag,
              isEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCol extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final bool isEnd;

  const _DateCol({
    required this.label,
    required this.date,
    required this.icon,
    this.isEnd = false,
  });

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            date != null ? _fmt.format(date!) : '—',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      );
}

class _MilestonesRow extends StatelessWidget {
  final List<MilestoneModel> milestones;
  const _MilestonesRow({required this.milestones});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamienie milowe',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  milestones.map((m) => MilestoneChip(milestone: m)).toList(),
            ),
            const Divider(height: 32),
          ],
        ),
      );
}

class _EtapHeader extends StatelessWidget {
  final EtapTimeline etap;
  final DateTime projectStart;
  final DateTime projectEnd;

  const _EtapHeader({
    required this.etap,
    required this.projectStart,
    required this.projectEnd,
  });

  Color _statusColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (etap.status) {
      'w_toku' => cs.primaryContainer,
      'zakończony' => cs.secondaryContainer,
      _ => cs.surfaceContainerHighest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = projectEnd.difference(projectStart).inDays.clamp(1, 9999);

    final etapStart = etap.dataStart ?? projectStart;
    final etapEnd = etap.dataKoniec ?? projectEnd;
    final offsetFrac =
        etapStart.difference(projectStart).inDays / totalDays;
    final widthFrac =
        (etapEnd.difference(etapStart).inDays.clamp(1, totalDays)) /
            totalDays;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etap.nazwa,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${etap.postepEtapu}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Pasek etapu
          LayoutBuilder(
            builder: (ctx, constraints) {
              final total = constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Positioned(
                    left: (offsetFrac * total).clamp(0.0, total),
                    child: Container(
                      height: 10,
                      width: (widthFrac * total).clamp(4.0, total),
                      decoration: BoxDecoration(
                        color: _statusColor(context),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: etap.postepEtapu / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(ctx).colorScheme.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ZadanieRow extends ConsumerWidget {
  final ZadanieModel zadanie;
  final DateTime projectStart;
  final DateTime projectEnd;
  final int budowaId;

  const _ZadanieRow({
    required this.zadanie,
    required this.projectStart,
    required this.projectEnd,
    required this.budowaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/harmonogram/zadanie',
        arguments: {
          'zadanieId': zadanie.id,
          'budowaId': budowaId,
        },
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
        child: Row(
          children: [
            // Nazwa + status
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (zadanie.isOpóźnione)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.warning_amber,
                              size: 14, color: Colors.orange),
                        ),
                      Expanded(
                        child: Text(
                          zadanie.nazwa,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${zadanie.postepProcent}%  •  ${zadanie.status.label}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Gantt bar
            Expanded(
              flex: 3,
              child: GanttBar(
                zadanie: zadanie,
                projectStart: projectStart,
                projectEnd: projectEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Empty / Error -------------------------------------------------------

class _EmptyView extends StatelessWidget {
  final int budowaId;
  final VoidCallback onAutoGenerate;

  const _EmptyView({required this.budowaId, required this.onAutoGenerate});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Brak harmonogramu'),
            const SizedBox(height: 8),
            const Text(
              'Możesz wygenerować domyślne zadania\nautomatycznie na podstawie etapów budowy.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generuj automatycznie'),
              onPressed: onAutoGenerate,
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final int budowaId;
  final VoidCallback onRetry;
  final VoidCallback onAutoGenerate;

  const _ErrorView({
    required this.error,
    required this.budowaId,
    required this.onRetry,
    required this.onAutoGenerate,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(onPressed: onRetry, child: const Text('Odśwież')),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto-generuj'),
                  onPressed: onAutoGenerate,
                ),
              ],
            ),
          ],
        ),
      );
}
