import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/dziennik_model.dart';
import '../../data/providers/dziennik_provider.dart';
import '../../widgets/pogoda_badge.dart';

class DziennikDetailScreen extends ConsumerWidget {
  final int wpisId;
  final int budowaId;
  final String budowaNazwa;

  const DziennikDetailScreen({
    super.key,
    required this.wpisId,
    required this.budowaId,
    required this.budowaNazwa,
  });

  static final _fmt = DateFormat('dd MMMM yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wpisDetailProvider(wpisId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wpis dziennika'),
        actions: [
          async.whenOrNull(
            data: (wpis) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/dziennik/form',
                  arguments: {
                    'budowaId': budowaId,
                    'budowaNazwa': budowaNazwa,
                    'wpisId': wpisId,
                  },
                );
                if (result == true) {
                  ref.invalidate(wpisDetailProvider(wpisId));
                  ref
                      .read(dziennikListProvider(budowaId).notifier)
                      .load();
                }
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (wpis) => _WpisBody(wpis: wpis, budowaId: budowaId, budowaNazwa: budowaNazwa),
      ),
    );
  }
}

class _WpisBody extends StatelessWidget {
  final WpisDetail wpis;
  final int budowaId;
  final String budowaNazwa;

  const _WpisBody({
    required this.wpis,
    required this.budowaId,
    required this.budowaNazwa,
  });

  static final _fmt = DateFormat('dd MMMM yyyy (EEEE)', 'pl_PL');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Data + pogoda
        Row(
          children: [
            Expanded(
              child: Text(
                _fmt.format(wpis.data),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            PogodaBadge(
              pogoda: wpis.pogoda,
              temperatura: wpis.temperatura,
              showLabel: true,
            ),
          ],
        ),

        if (wpis.pogodaAuto) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 12, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                'Pogoda uzupełniona automatycznie',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ],

        if (wpis.predkoscWiatru != null || wpis.opady != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (wpis.predkoscWiatru != null)
                _InfoBadge(
                  '💨 ${wpis.predkoscWiatru!.round()} km/h',
                  cs.surfaceContainerHighest,
                ),
              if (wpis.opady != null && wpis.opady! > 0)
                _InfoBadge(
                  '🌧 ${wpis.opady!.toStringAsFixed(1)} mm',
                  cs.surfaceContainerHighest,
                ),
            ],
          ),
        ],

        const Divider(height: 32),

        // Etap
        if (wpis.etapNazwa != null) ...[
          _RowInfo(
            icon: Icons.construction,
            label: 'Etap',
            value: wpis.etapNazwa!,
          ),
          const SizedBox(height: 12),
        ],

        // Opis
        _SectionLabel('Opis dnia'),
        Text(wpis.opis, style: Theme.of(context).textTheme.bodyMedium),

        if (wpis.uwagi.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('Uwagi'),
          Text(wpis.uwagi, style: Theme.of(context).textTheme.bodyMedium),
        ],

        const Divider(height: 32),

        // Zespół
        _SectionLabel('Zespół'),
        Row(
          children: [
            _InfoBadge('👷 ${wpis.liczbaPracownikow} os.', cs.secondaryContainer),
            const SizedBox(width: 8),
            _InfoBadge('⏱ ${wpis.godzinyPracy.toStringAsFixed(0)} h', cs.tertiaryContainer),
          ],
        ),

        if (wpis.obecnosci.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...wpis.obecnosci.map(
            (o) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Text(o.imieNazwisko[0]),
              ),
              title: Text(o.imieNazwisko),
              subtitle: Text(o.rola),
              trailing: Text('${o.godziny.round()} h'),
            ),
          ),
        ],

        // Zdjęcia
        if (wpis.zdjecia.isNotEmpty) ...[
          const Divider(height: 32),
          _SectionLabel('Zdjęcia (${wpis.zdjecia.length})'),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wpis.zdjecia.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final z = wpis.zdjecia[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: z.url.isNotEmpty
                        ? Image.network(z.url, fit: BoxFit.cover)
                        : Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.photo),
                          ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _InfoBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      );
}

class _RowInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _RowInfo({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelMedium),
          Expanded(child: Text(value)),
        ],
      );
}
