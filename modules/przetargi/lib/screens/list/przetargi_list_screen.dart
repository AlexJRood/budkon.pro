import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import '../../data/models/przetarg_model.dart';
import '../../data/providers/emma_inbox_provider.dart';
import '../../data/providers/przetargi_provider.dart';
import '../../data/services/przetargi_api.dart';
import '../../widgets/emma_inbox_widget.dart';
import '../../widgets/przetarg_card.dart';

class PrzetargiListScreen extends ConsumerStatefulWidget {
  const PrzetargiListScreen({super.key});

  @override
  ConsumerState<PrzetargiListScreen> createState() => _PrzetargiListScreenState();
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
    final theme = ref.read(themeColorsProvider);
    final listState = ref.watch(przetargiListProvider);
    final filter = ref.watch(przetargiFilterProvider);
    final fetchState = ref.watch(fetchProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.textColor),
        title: Text('Przetargi', style: TextStyle(color: theme.textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_outlined, color: theme.textColor),
            tooltip: 'Subskrypcje',
            onPressed: () => Navigator.of(context).pushNamed('/przetargi/subskrypcje'),
          ),
          _FetchButton(fetchState: fetchState),
        ],
      ),
      body: Column(
        children: [
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
                      ref.read(przetargiFilterProvider.notifier).state =
                          filter.copyWith(q: null);
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

          _StatusFilterBar(
            current: filter.status,
            theme: theme,
            onChanged: (s) {
              final f = filter.copyWith(status: s);
              ref.read(przetargiFilterProvider.notifier).state = f;
              ref.read(przetargiListProvider.notifier).load(filter: f);
            },
          ),

          Expanded(
            child: listState.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: theme.themeColor)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text('Błąd: $e', style: TextStyle(color: theme.textColor)),
                    TextButton(
                      onPressed: () =>
                          ref.read(przetargiListProvider.notifier).load(),
                      child: Text('Spróbuj ponownie',
                          style: TextStyle(color: theme.themeColor)),
                    ),
                  ],
                ),
              ),
              data: (przetargi) => przetargi.isEmpty
                  ? _EmptyState(
                      theme: theme,
                      onFetch: () => ref
                          .read(fetchProvider.notifier)
                          .fetch(ref.read(przetargiListProvider.notifier)))
                  : RefreshIndicator(
                      color: theme.themeColor,
                      onRefresh: () async {
                        await ref.read(przetargiListProvider.notifier).load();
                        ref.invalidate(emmaInboxProvider);
                      },
                      child: ListView.builder(
                        itemCount: przetargi.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return const EmmaInboxWidget();
                          final p = przetargi[i - 1];
                          return PrzetargCard(
                            przetarg: p,
                            onTap: () => Navigator.of(context)
                                .pushNamed('/przetargi/${p.id}'),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.themeColor,
        icon: Icon(Icons.add, color: theme.buttonTextColor),
        label: Text('Dodaj ręcznie', style: TextStyle(color: theme.buttonTextColor)),
        onPressed: () => _showAddManual(context),
      ),
    );
  }

  void _showAddManual(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddManualDialog());
  }
}

class _FetchButton extends ConsumerWidget {
  final AsyncValue<int?> fetchState;
  const _FetchButton({required this.fetchState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    if (fetchState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.themeColor),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.cloud_download_outlined, color: theme.textColor),
      tooltip: 'Pobierz z BZP',
      onPressed: () async {
        await ref
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

class _StatusFilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  final ThemeColors theme;

  const _StatusFilterBar(
      {required this.current, required this.onChanged, required this.theme});

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
                  selectedColor: theme.themeColor.withAlpha(60),
                  checkmarkColor: theme.themeColor,
                  labelStyle: TextStyle(
                      color: current == c.$1 ? theme.themeColor : theme.textColor),
                  backgroundColor: theme.userTile,
                  side: BorderSide(
                      color: current == c.$1
                          ? theme.themeColor
                          : theme.bordercolor.withAlpha(60)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onFetch;
  final ThemeColors theme;
  const _EmptyState({required this.onFetch, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.find_in_page_outlined,
                size: 64, color: theme.textColor.withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              'Brak przetargów',
              style: TextStyle(
                  color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pobierz przetargi z BZP lub dodaj ręcznie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textColor.withAlpha(150)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Pobierz z BZP'),
              onPressed: onFetch,
              style: FilledButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.buttonTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  child: CircularProgressIndicator(strokeWidth: 2))
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
