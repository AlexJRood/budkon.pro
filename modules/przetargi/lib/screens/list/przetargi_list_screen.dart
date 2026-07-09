import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/przetarg_model.dart';
import '../../data/providers/przetargi_provider.dart';
import '../../widgets/przetarg_card.dart';

class PrzetargiListScreen extends ConsumerStatefulWidget {
  const PrzetargiListScreen({super.key});

  @override
  ConsumerState<PrzetargiListScreen> createState() =>
      _PrzetargiListScreenState();
}

class _PrzetargiListScreenState extends ConsumerState<PrzetargiListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final listState = ref.watch(przetargiListProvider);
    final filter = ref.watch(przetargiFilterProvider);
    final fetchState = ref.watch(fetchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Przetargi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Subskrypcje',
            onPressed: () => Navigator.of(context).pushNamed('/przetargi/subskrypcje'),
          ),
          _FetchButton(fetchState: fetchState),
        ],
      ),
      body: Column(
        children: [
          // Wyszukiwarka
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Szukaj przetargu...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref
                          .read(przetargiFilterProvider.notifier)
                          .state = filter.copyWith(q: null);
                      ref.read(przetargiListProvider.notifier).load(
                            filter: filter.copyWith(q: null),
                          );
                    },
                  ),
              ],
              onChanged: (q) {
                final f = filter.copyWith(q: q.isEmpty ? null : q);
                ref.read(przetargiFilterProvider.notifier).state = f;
                ref.read(przetargiListProvider.notifier).load(filter: f);
              },
            ),
          ),

          // Filtry statusu
          _StatusFilterBar(
            current: filter.status,
            onChanged: (s) {
              final f = filter.copyWith(status: s);
              ref.read(przetargiFilterProvider.notifier).state = f;
              ref.read(przetargiListProvider.notifier).load(filter: f);
            },
          ),

          // Lista
          Expanded(
            child: listState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 40),
                    const SizedBox(height: 8),
                    Text('Błąd: $e'),
                    TextButton(
                      onPressed: () =>
                          ref.read(przetargiListProvider.notifier).load(),
                      child: const Text('Spróbuj ponownie'),
                    ),
                  ],
                ),
              ),
              data: (przetargi) => przetargi.isEmpty
                  ? _EmptyState(onFetch: () => ref
                      .read(fetchProvider.notifier)
                      .fetch(ref.read(przetargiListProvider.notifier)))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(przetargiListProvider.notifier).load(),
                      child: ListView.builder(
                        itemCount: przetargi.length,
                        itemBuilder: (ctx, i) => PrzetargCard(
                          przetarg: przetargi[i],
                          onTap: () => Navigator.of(context).pushNamed(
                            '/przetargi/${przetargi[i].id}',
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Dodaj ręcznie'),
        onPressed: () => _showAddManual(context),
      ),
    );
  }

  void _showAddManual(BuildContext context) {
    // Prosty dialog do ręcznego dodania przetargu
    showDialog(
      context: context,
      builder: (_) => const _AddManualDialog(),
    );
  }
}

// ------------------------------------------------------------------ //
// Fetch button ze stanem                                               //
// ------------------------------------------------------------------ //

class _FetchButton extends ConsumerWidget {
  final AsyncValue<int?> fetchState;
  const _FetchButton({required this.fetchState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fetchState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.cloud_download_outlined),
      tooltip: 'Pobierz z BZP',
      onPressed: () async {
        final result = await ref
            .read(fetchProvider.notifier)
            .fetch(ref.read(przetargiListProvider.notifier));
        if (context.mounted) {
          final n = ref.read(fetchProvider).valueOrNull ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(n > 0
                  ? 'Pobrano $n nowych przetargów'
                  : 'Brak nowych przetargów'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}

// ------------------------------------------------------------------ //
// Filtr statusu                                                        //
// ------------------------------------------------------------------ //

class _StatusFilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;

  const _StatusFilterBar({required this.current, required this.onChanged});

  static const _chips = [
    (null, 'Wszystkie'),
    ('nowy', 'Nowe'),
    ('analizowany', 'Analizowane'),
    ('kosztorys_gotowy', 'Kosztorys'),
    ('zlozony', 'Złożone'),
    ('wygrany', 'Wygrane'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _chips
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(c.$2),
                  selected: current == c.$1,
                  onSelected: (_) => onChanged(c.$1),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// Empty state                                                          //
// ------------------------------------------------------------------ //

class _EmptyState extends StatelessWidget {
  final VoidCallback onFetch;
  const _EmptyState({required this.onFetch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.find_in_page_outlined,
                size: 64, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Brak przetargów',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pobierz przetargi z BZP lub dodaj ręcznie.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Pobierz z BZP'),
              onPressed: onFetch,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ //
// Dialog ręcznego dodania                                              //
// ------------------------------------------------------------------ //

class _AddManualDialog extends ConsumerStatefulWidget {
  const _AddManualDialog();

  @override
  ConsumerState<_AddManualDialog> createState() => _AddManualDialogState();
}

class _AddManualDialogState extends ConsumerState<_AddManualDialog> {
  final _tytulCtrl = TextEditingController();
  final _zamawiajacyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj przetarg ręcznie'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tytulCtrl,
            decoration: const InputDecoration(labelText: 'Tytuł *'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zamawiajacyCtrl,
            decoration: const InputDecoration(labelText: 'Zamawiający *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Link do ogłoszenia',
              hintText: 'https://',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Dodaj'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_tytulCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = PrzetargiApi();
      await api.createPrzetarg({
        'tytul': _tytulCtrl.text.trim(),
        'zamawiajacy': _zamawiajacyCtrl.text.trim(),
        'zrodlo_url': _urlCtrl.text.trim(),
      });
      await ref.read(przetargiListProvider.notifier).load();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ignore: unused_import
import '../../data/services/przetargi_api.dart';
