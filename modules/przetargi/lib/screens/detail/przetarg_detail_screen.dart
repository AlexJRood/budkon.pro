import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:intl/intl.dart';

import '../../data/models/przetarg_model.dart';
import '../../data/providers/przetargi_provider.dart';
import '../../widgets/ai_score_badge.dart';
import '../../widgets/status_badge.dart';

class PrzetargDetailScreen extends ConsumerWidget {
  final int przetargId;

  const PrzetargDetailScreen({super.key, required this.przetargId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(przetargDetailProvider(przetargId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: state.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (p) => _PrzetargDetailView(przetarg: p, przetargId: przetargId, theme: theme),
      ),
    );
  }
}

class _PrzetargDetailView extends ConsumerWidget {
  final PrzetargDetail przetarg;
  final int przetargId;
  final ThemeColors theme;

  const _PrzetargDetailView(
      {required this.przetarg, required this.przetargId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = przetarg;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.textColor),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              p.tytul,
              style: TextStyle(fontSize: 14, color: theme.textColor),
              maxLines: 2,
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.sidebar, theme.themeColor.withAlpha(80)],
                ),
              ),
            ),
          ),
          actions: [
            _StatusMenu(przetarg: p, przetargId: przetargId),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  PrzetargStatusBadge(p.status),
                  const SizedBox(width: 8),
                  if (p.aiScore != null) AiScoreBadge(score: p.aiScore!),
                  const Spacer(),
                  if (p.dniDoTerminu != null) _DniChip(dni: p.dniDoTerminu!, theme: theme),
                ],
              ),
              const SizedBox(height: 20),

              _InfoCard(theme: theme, children: [
                _InfoRow(
                  icon: Icons.business_outlined,
                  label: 'Zamawiający',
                  value: p.zamawiajacy,
                  theme: theme,
                ),
                if (p.wartoscSzacunkowa != null)
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Wartość szacunkowa',
                    value: p.wartoscFormatted,
                    highlight: true,
                    theme: theme,
                  ),
                if (p.lokalizacja.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokalizacja',
                    value: p.lokalizacja,
                    theme: theme,
                  ),
                if (p.terminSkladania != null)
                  _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Termin składania',
                    value: DateFormat('d MMMM yyyy, HH:mm', 'pl_PL')
                        .format(p.terminSkladania!.toLocal()),
                    theme: theme,
                  ),
                if (p.terminRealizacji != null)
                  _InfoRow(
                    icon: Icons.construction_outlined,
                    label: 'Termin realizacji',
                    value: p.terminRealizacji!,
                    theme: theme,
                  ),
                if (p.zrodloUrl.isNotEmpty)
                  _InfoRow(
                    icon: Icons.link,
                    label: 'Źródło',
                    value: p.zrodloUrl,
                    isLink: true,
                    theme: theme,
                  ),
              ]),
              const SizedBox(height: 16),

              if (p.aiScore != null) ...[
                _AiOcenaCard(przetarg: p, theme: theme),
                const SizedBox(height: 16),
              ],

              if (p.opis.isNotEmpty) ...[
                Text('Opis',
                    style: TextStyle(
                        color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Text(p.opis, style: TextStyle(color: theme.textColor)),
                const SizedBox(height: 16),
              ],

              if (p.cpvKody.isNotEmpty) ...[
                Text('Kody CPV',
                    style: TextStyle(
                        color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: p.cpvKody
                      .map(
                        (k) => Chip(
                          label: Text(k,
                              style: TextStyle(fontSize: 12, color: theme.textColor)),
                          backgroundColor: theme.secondaryWidgetColor,
                          side: BorderSide(color: theme.bordercolor.withAlpha(60)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              _AkcjeBar(przetarg: p, przetargId: przetargId),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _AiOcenaCard extends StatelessWidget {
  final PrzetargDetail przetarg;
  final ThemeColors theme;
  const _AiOcenaCard({required this.przetarg, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = przetarg;
    final pozytywna = p.aiCzyWarto == true;
    final color = pozytywna ? const Color(0xFF4CAF50) : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pozytywna ? Icons.thumb_up_outlined : Icons.warning_amber_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                pozytywna ? 'AI rekomenduje złożenie oferty' : 'AI: wątpliwości',
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
              const Spacer(),
              if (p.aiScore != null) AiScoreBadge(score: p.aiScore!),
            ],
          ),
          if (p.aiUzasadnienie.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.aiUzasadnienie,
                style: TextStyle(color: theme.textColor.withAlpha(180), fontSize: 13)),
          ],
          if (p.aiUwagi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: p.aiUwagi
                  .map(
                    (u) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.secondaryWidgetColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.bordercolor.withAlpha(60)),
                      ),
                      child: Text(u,
                          style: TextStyle(
                              color: theme.textColor, fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AkcjeBar extends ConsumerStatefulWidget {
  final PrzetargDetail przetarg;
  final int przetargId;

  const _AkcjeBar({required this.przetarg, required this.przetargId});

  @override
  ConsumerState<_AkcjeBar> createState() => _AkcjeBarState();
}

class _AkcjeBarState extends ConsumerState<_AkcjeBar> {
  bool _analyzingAi = false;
  bool _generatingKosztorys = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final p = widget.przetarg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          icon: _generatingKosztorys
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.calculate_outlined),
          label: Text(p.kosztorysId != null ? 'Regeneruj kosztorys' : 'Generuj kosztorys AI'),
          onPressed: _generatingKosztorys ? null : _generujKosztorys,
          style: FilledButton.styleFrom(
              backgroundColor: theme.themeColor, foregroundColor: theme.buttonTextColor),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          icon: _analyzingAi
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor))
              : const Icon(Icons.psychology_outlined),
          label: Text(p.aiAnalizowanyAt != null ? 'Ponów analizę AI' : 'Analizuj przez AI'),
          onPressed: _analyzingAi ? null : _analizuj,
          style: OutlinedButton.styleFrom(
              foregroundColor: theme.themeColor,
              side: BorderSide(color: theme.bordercolor.withAlpha(80))),
        ),

        if (p.kosztorysId != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Otwórz kosztorys'),
            onPressed: () => ref.read(navigationService).pushNamedScreen('/kosztorysy/${p.kosztorysId}'),
            style: OutlinedButton.styleFrom(
                foregroundColor: theme.themeColor,
                side: BorderSide(color: theme.bordercolor.withAlpha(80))),
          ),
        ],
      ],
    );
  }

  Future<void> _analizuj() async {
    setState(() => _analyzingAi = true);
    try {
      final result = await ref
          .read(przetargDetailProvider(widget.przetargId).notifier)
          .analizuj();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ocena AI: ${result['score']}/100 — ${result['uzasadnienie']}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _analyzingAi = false);
    }
  }

  Future<void> _generujKosztorys() async {
    setState(() => _generatingKosztorys = true);
    try {
      final kosztorysId = await ref
          .read(przetargDetailProvider(widget.przetargId).notifier)
          .generujKosztorys();
      if (mounted && kosztorysId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kosztorys gotowy!'),
            action: SnackBarAction(
              label: 'Otwórz',
              onPressed: () =>
                  ref.read(navigationService).pushNamedScreen('/kosztorysy/$kosztorysId'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingKosztorys = false);
    }
  }
}

class _StatusMenu extends ConsumerWidget {
  final PrzetargDetail przetarg;
  final int przetargId;

  const _StatusMenu({required this.przetarg, required this.przetargId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return PopupMenuButton<StatusPrzetargu>(
      icon: Icon(Icons.more_vert, color: theme.textColor),
      itemBuilder: (_) => StatusPrzetargu.values
          .where((s) => s != przetarg.status)
          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
      onSelected: (s) async {
        await ref
            .read(przetargDetailProvider(przetargId).notifier)
            .zmienStatus(s);
        ref.invalidate(przetargiListProvider);
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final ThemeColors theme;
  const _InfoCard({required this.children, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.bordercolor.withAlpha(40)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeColors theme;
  final bool highlight;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.textColor.withAlpha(120)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: (isLink || highlight) ? theme.themeColor : theme.textColor,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DniChip extends StatelessWidget {
  final int dni;
  final ThemeColors theme;
  const _DniChip({required this.dni, required this.theme});

  @override
  Widget build(BuildContext context) {
    final urgent = dni <= 7;
    final color = urgent ? Colors.red : theme.themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$dni dni do terminu',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
