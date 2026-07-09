import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/harmonogram_model.dart';
import '../../data/providers/harmonogram_provider.dart';
import '../../data/services/harmonogram_api.dart';

class ZadanieDetailScreen extends ConsumerStatefulWidget {
  final int zadanieId;
  final int budowaId;

  const ZadanieDetailScreen({
    super.key,
    required this.zadanieId,
    required this.budowaId,
  });

  @override
  ConsumerState<ZadanieDetailScreen> createState() =>
      _ZadanieDetailScreenState();
}

class _ZadanieDetailScreenState extends ConsumerState<ZadanieDetailScreen> {
  ZadanieModel? _zadanie;
  bool _loading = true;
  int _sliderValue = 0;

  static final _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final z = await harmonogramApi.zadanie(widget.zadanieId);
      setState(() {
        _zadanie = z;
        _sliderValue = z.postepProcent;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _zapiszPostep() async {
    if (_zadanie == null) return;

    final notifier = ref.read(postepProvider.notifier);
    final updated = await notifier.aktualizuj(
      widget.zadanieId,
      postepProcent: _sliderValue,
    );
    if (updated != null) {
      setState(() => _zadanie = updated);
      ref.invalidate(timelineProvider(widget.budowaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_zadanie == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zadanie')),
        body: const Center(child: Text('Błąd ładowania')),
      );
    }

    final z = _zadanie!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadanie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/harmonogram/zadanie/form',
                arguments: {
                  'budowaId': widget.budowaId,
                  'zadanieId': widget.zadanieId,
                },
              );
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nazwa + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  z.nazwa,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: z.status, isOpóźnione: z.isOpóźnione),
            ],
          ),

          if (z.etapNazwa != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.construction, size: 16, color: cs.outline),
                const SizedBox(width: 6),
                Text(z.etapNazwa!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],

          if (z.opis.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(z.opis),
          ],

          const Divider(height: 32),

          // Daty
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  value: z.dataStart != null ? _fmt.format(z.dataStart!) : '—',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  icon: Icons.flag,
                  label: 'Koniec',
                  value:
                      z.dataKoniec != null ? _fmt.format(z.dataKoniec!) : '—',
                  isWarning: z.isOpóźnione,
                ),
              ),
              Expanded(
                child: _InfoTile(
                  icon: Icons.timer_outlined,
                  label: 'Czas trwania',
                  value: '${z.durationDni} dni',
                ),
              ),
            ],
          ),

          if (z.isOpóźnione) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Opóźnienie: ${z.opoznienieDni} dni',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),

          // Postęp
          Text(
            'Postęp: $_sliderValue%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sliderValue.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_sliderValue%',
                  onChanged: (v) =>
                      setState(() => _sliderValue = v.round()),
                ),
              ),
              FilledButton(
                onPressed: _sliderValue != z.postepProcent
                    ? _zapiszPostep
                    : null,
                child: const Text('Zapisz'),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: z.postepProcent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),

          const Divider(height: 32),

          // Poprzednicy
          if (z.poprzednicyIds.isNotEmpty) ...[
            Text(
              'Poprzednicy (${z.poprzednicyIds.length})',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: z.poprzednicyIds
                  .map((id) => Chip(label: Text('#$id')))
                  .toList(),
            ),
            const Divider(height: 32),
          ],

          // Budżet
          if (z.budzet > 0)
            _InfoTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Budżet zadania',
              value:
                  '${z.budzet.toStringAsFixed(0)} PLN',
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StatusZadania status;
  final bool isOpóźnione;

  const _StatusBadge({required this.status, required this.isOpóźnione});

  Color _color(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    if (isOpóźnione) return Colors.orange.shade100;
    return switch (status) {
      StatusZadania.zakonczone => cs.secondaryContainer,
      StatusZadania.w_toku => cs.primaryContainer,
      StatusZadania.wstrzymane => cs.surfaceContainerHighest,
      _ => cs.surfaceContainerHighest,
    };
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isOpóźnione ? 'Opóźnione' : status.label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: isWarning
                      ? Colors.orange
                      : Theme.of(context).colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isWarning ? Colors.orange.shade800 : null,
                ),
          ),
        ],
      );
}
