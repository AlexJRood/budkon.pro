import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:intl/intl.dart';
import '../../data/models/harmonogram_model.dart';
import '../../data/providers/harmonogram_provider.dart';
import '../../data/services/harmonogram_api.dart';
import '../../widgets/gantt_bar.dart';
import '../../widgets/milestone_chip.dart';

class HarmonogramScreen extends ConsumerWidget {
  final int budowaId;
  final String budowaNazwa;

  const HarmonogramScreen({super.key, required this.budowaId, required this.budowaNazwa});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(timelineProvider(budowaId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Harmonogram', style: TextStyle(color: theme.textColor)),
            Text(budowaNazwa, style: TextStyle(color: theme.textColor.withAlpha(160), fontSize: 11)),
          ],
        ),
        iconTheme: IconThemeData(color: theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () => ref.invalidate(timelineProvider(budowaId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => _ErrorView(
          theme: theme,
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
              theme: theme,
              budowaId: budowaId,
              onAutoGenerate: () async {
                await harmonogramApi.autoGeneruj(budowaId);
                ref.invalidate(timelineProvider(budowaId));
              },
            );
          }
          return _TimelineBody(data: data, budowaId: budowaId, theme: theme);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        icon: Icon(Icons.add_task, color: theme.buttonTextColor),
        label: Text('Nowe zadanie', style: TextStyle(color: theme.buttonTextColor)),
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
  final ThemeColors theme;

  const _TimelineBody({required this.data, required this.budowaId, required this.theme});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _BudowaDatesHeader(data: data, theme: theme)),
        if (data.milestones.isNotEmpty)
          SliverToBoxAdapter(child: _MilestonesRow(milestones: data.milestones, theme: theme)),
        for (final etap in data.etapy) ...[
          SliverToBoxAdapter(child: _EtapHeader(
            etap: etap,
            projectStart: data.effectiveStart,
            projectEnd: data.effectiveEnd,
            theme: theme,
          )),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ZadanieRow(
                zadanie: etap.zadania[i],
                projectStart: data.effectiveStart,
                projectEnd: data.effectiveEnd,
                budowaId: budowaId,
                theme: theme,
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

class _BudowaDatesHeader extends StatelessWidget {
  final TimelineData data;
  final ThemeColors theme;
  const _BudowaDatesHeader({required this.data, required this.theme});

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Expanded(child: _DateCol(label: 'Rozpoczęcie', date: data.dataStart, icon: Icons.play_arrow, theme: theme)),
          Container(width: 1, height: 40, color: theme.bordercolor.withAlpha(60)),
          Expanded(child: _DateCol(label: 'Planowane zakończenie', date: data.dataKoniec, icon: Icons.flag, theme: theme, isEnd: true)),
        ],
      ),
    );
  }
}

class _DateCol extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final ThemeColors theme;
  final bool isEnd;

  const _DateCol({required this.label, required this.date, required this.icon, required this.theme, this.isEnd = false});

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: theme.themeColor),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 11)),
      const SizedBox(height: 2),
      Text(date != null ? _fmt.format(date!) : '—',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
    ],
  );
}

class _MilestonesRow extends StatelessWidget {
  final List<MilestoneModel> milestones;
  final ThemeColors theme;
  const _MilestonesRow({required this.milestones, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kamienie milowe',
            style: TextStyle(color: theme.themeColor, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
            children: milestones.map((m) => MilestoneChip(milestone: m)).toList()),
        Divider(height: 32, color: theme.bordercolor.withAlpha(60)),
      ],
    ),
  );
}

class _EtapHeader extends StatelessWidget {
  final EtapTimeline etap;
  final DateTime projectStart;
  final DateTime projectEnd;
  final ThemeColors theme;

  const _EtapHeader({required this.etap, required this.projectStart, required this.projectEnd, required this.theme});

  Color _statusColor() => switch (etap.status) {
    'w_toku' => theme.themeColor.withAlpha(80),
    'zakończony' => const Color(0xFF4CAF50),
    _ => theme.textColor.withAlpha(40),
  };

  @override
  Widget build(BuildContext context) {
    final totalDays = projectEnd.difference(projectStart).inDays.clamp(1, 9999);
    final etapStart = etap.dataStart ?? projectStart;
    final etapEnd = etap.dataKoniec ?? projectEnd;
    final offsetFrac = etapStart.difference(projectStart).inDays / totalDays;
    final widthFrac = (etapEnd.difference(etapStart).inDays.clamp(1, totalDays)) / totalDays;

    return Container(
      color: theme.mobileBackground,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(etap.nazwa,
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor(), borderRadius: BorderRadius.circular(8)),
              child: Text('${etap.postepEtapu}%',
                  style: TextStyle(color: theme.textColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (ctx, constraints) {
            final total = constraints.maxWidth;
            return Stack(children: [
              Container(height: 10,
                  decoration: BoxDecoration(color: theme.bordercolor.withAlpha(60), borderRadius: BorderRadius.circular(5))),
              Positioned(
                left: (offsetFrac * total).clamp(0.0, total),
                child: Container(
                  height: 10,
                  width: (widthFrac * total).clamp(4.0, total),
                  decoration: BoxDecoration(color: theme.themeColor.withAlpha(60), borderRadius: BorderRadius.circular(5)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: etap.postepEtapu / 100,
                    child: Container(
                      decoration: BoxDecoration(color: theme.themeColor, borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

class _ZadanieRow extends StatelessWidget {
  final ZadanieModel zadanie;
  final DateTime projectStart;
  final DateTime projectEnd;
  final int budowaId;
  final ThemeColors theme;

  const _ZadanieRow({required this.zadanie, required this.projectStart, required this.projectEnd, required this.budowaId, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/harmonogram/zadanie',
          arguments: {'zadanieId': zadanie.id, 'budowaId': budowaId}),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (zadanie.isOpoznione)
                  const Padding(padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber, size: 14, color: Colors.orange)),
                Expanded(child: Text(zadanie.nazwa,
                    style: TextStyle(color: theme.textColor, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              Text('${zadanie.postepProcent}%  •  ${zadanie.status.label}',
                  style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 11)),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: GanttBar(
            zadanie: zadanie, projectStart: projectStart, projectEnd: projectEnd)),
        ]),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final int budowaId;
  final ThemeColors theme;
  final VoidCallback onAutoGenerate;

  const _EmptyView({required this.budowaId, required this.theme, required this.onAutoGenerate});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.calendar_month_outlined, size: 64, color: theme.textColor.withAlpha(80)),
      const SizedBox(height: 16),
      Text('Brak harmonogramu', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Możesz wygenerować domyślne zadania\nautomatycznie na podstawie etapów budowy.',
          style: TextStyle(color: theme.textColor.withAlpha(150)), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      FilledButton.icon(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generuj automatycznie'),
        onPressed: onAutoGenerate,
        style: FilledButton.styleFrom(backgroundColor: theme.themeColor, foregroundColor: theme.buttonTextColor),
      ),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final int budowaId;
  final ThemeColors theme;
  final VoidCallback onRetry;
  final VoidCallback onAutoGenerate;

  const _ErrorView({required this.error, required this.budowaId, required this.theme, required this.onRetry, required this.onAutoGenerate});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(error, style: TextStyle(color: theme.textColor)),
      const SizedBox(height: 12),
      Row(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton(onPressed: onRetry,
            style: OutlinedButton.styleFrom(foregroundColor: theme.textColor, side: BorderSide(color: theme.bordercolor.withAlpha(80))),
            child: const Text('Odśwież')),
        const SizedBox(width: 12),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Auto-generuj'),
          onPressed: onAutoGenerate,
          style: FilledButton.styleFrom(backgroundColor: theme.themeColor, foregroundColor: theme.buttonTextColor),
        ),
      ]),
    ]),
  );
}
