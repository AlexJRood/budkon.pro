import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final state = ref.watch(przetargDetailProvider(przetargId));

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Błąd: $e')),
      ),
      data: (p) => _PrzetargDetailView(przetarg: p, przetargId: przetargId),
    );
  }
}

class _PrzetargDetailView extends ConsumerWidget {
  final PrzetargDetail przetarg;
  final int przetargId;

  const _PrzetargDetailView(
      {required this.przetarg, required this.przetargId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final p = przetarg;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar z tytułem
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                p.tytul,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.secondaryContainer,
                    ],
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
                // Status + score
                Row(
                  children: [
                    PrzetargStatusBadge(p.status),
                    const SizedBox(width: 8),
                    if (p.aiScore != null) AiScoreBadge(score: p.aiScore!),
                    const Spacer(),
                    if (p.dniDoTerminu != null)
                      _DniChip(dni: p.dniDoTerminu!),
                  ],
                ),
                const SizedBox(height: 20),

                // Kluczowe dane
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Zamawiający',
                    value: p.zamawiajacy,
                  ),
                  if (p.wartoscSzacunkowa != null)
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Wartość szacunkowa',
                      value: p.wartoscFormatted,
                      highlight: true,
                    ),
                  if (p.lokalizacja.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Lokalizacja',
                      value: p.lokalizacja,
                    ),
                  if (p.terminSkladania != null)
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Termin składania',
                      value: DateFormat('d MMMM yyyy, HH:mm', 'pl_PL')
                          .format(p.terminSkladania!.toLocal()),
                    ),
                  if (p.terminRealizacji != null)
                    _InfoRow(
                      icon: Icons.construction_outlined,
                      label: 'Termin realizacji',
                      value: p.terminRealizacji!,
                    ),
                  if (p.zrodloUrl.isNotEmpty)
                    _InfoRow(
                      icon: Icons.link,
                      label: 'Źródło',
                      value: p.zrodloUrl,
                      isLink: true,
                    ),
                ]),
                const SizedBox(height: 16),

                // AI ocena
                if (p.aiScore != null) ...[
                  _AiOcenaCard(przetarg: p),
                  const SizedBox(height: 16),
                ],

                // Opis
                if (p.opis.isNotEmpty) ...[
                  Text('Opis',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(p.opis,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],

                // CPV kody
                if (p.cpvKody.isNotEmpty) ...[
                  Text('Kody CPV',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: p.cpvKody
                        .map(
                          (k) => Chip(
                            label: Text(k, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Akcje
                _AkcjeBar(przetarg: p, przetargId: przetargId),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// AI Ocena card                                                        //
// ------------------------------------------------------------------ //

class _AiOcenaCard extends StatelessWidget {
  final PrzetargDetail przetarg;
  const _AiOcenaCard({required this.przetarg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = przetarg;
    final pozytywna = p.aiCzyWarto == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pozytywna
            ? Colors.green.shade50
            : cs.errorContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pozytywna
              ? Colors.green.shade200
              : cs.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pozytywna ? Icons.thumb_up_outlined : Icons.warning_amber_outlined,
                color: pozytywna ? Colors.green.shade700 : cs.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                pozytywna ? 'AI rekomenduje złożenie oferty' : 'AI: wątpliwości',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: pozytywna ? Colors.green.shade800 : cs.error,
                ),
              ),
              const Spacer(),
              if (p.aiScore != null) AiScoreBadge(score: p.aiScore!),
            ],
          ),
          if (p.aiUzasadnienie.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              p.aiUzasadnienie,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (p.aiUwagi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: p.aiUwagi
                  .map(
                    (u) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(u,
                          style: Theme.of(context).textTheme.labelSmall),
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

// ------------------------------------------------------------------ //
// Akcje                                                                //
// ------------------------------------------------------------------ //

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
    final p = widget.przetarg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Generuj kosztorys
        FilledButton.icon(
          icon: _generatingKosztorys
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.calculate_outlined),
          label: Text(p.kosztorysId != null
              ? 'Regeneruj kosztorys'
              : 'Generuj kosztorys AI'),
          onPressed: _generatingKosztorys ? null : _generujKosztorys,
        ),
        const SizedBox(height: 10),

        // Analizuj AI
        OutlinedButton.icon(
          icon: _analyzingAi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.psychology_outlined),
          label: Text(p.aiAnalizowanyAt != null
              ? 'Ponów analizę AI'
              : 'Analizuj przez AI'),
          onPressed: _analyzingAi ? null : _analizuj,
        ),

        // Link do kosztorysu
        if (p.kosztorysId != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: const Text('Otwórz kosztorys'),
            onPressed: () => Navigator.of(context)
                .pushNamed('/kosztorysy/${p.kosztorysId}'),
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
            content:
                Text('Ocena AI: ${result['score']}/100 — ${result['uzasadnienie']}'),
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
              onPressed: () => Navigator.of(context)
                  .pushNamed('/kosztorysy/$kosztorysId'),
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

// ------------------------------------------------------------------ //
// Status menu                                                          //
// ------------------------------------------------------------------ //

class _StatusMenu extends ConsumerWidget {
  final PrzetargDetail przetarg;
  final int przetargId;

  const _StatusMenu({required this.przetarg, required this.przetargId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<StatusPrzetargu>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (_) => StatusPrzetargu.values
          .where((s) => s != przetarg.status)
          .map(
            (s) => PopupMenuItem(
              value: s,
              child: Text(s.label),
            ),
          )
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

// ------------------------------------------------------------------ //
// Info card + row                                                      //
// ------------------------------------------------------------------ //

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: highlight ? FontWeight.bold : null,
                        color: isLink
                            ? cs.primary
                            : highlight
                                ? cs.primary
                                : null,
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
  const _DniChip({required this.dni});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urgent = dni <= 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: urgent ? cs.errorContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 14,
              color: urgent ? cs.onErrorContainer : cs.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            '$dni dni do terminu',
            style: TextStyle(
              color:
                  urgent ? cs.onErrorContainer : cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
