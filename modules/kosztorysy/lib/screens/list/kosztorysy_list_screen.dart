import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/kosztorys_model.dart';
import '../../data/providers/kosztorysy_provider.dart';
import '../../widgets/kosztorys_status_badge.dart';
import '../../widgets/wartosc_chip.dart';
import '../detail/kosztorys_detail_screen.dart';
import '../form/kosztorys_form_screen.dart';

class KosztorysyListScreen extends ConsumerWidget {
  const KosztorysyListScreen({super.key, this.budowaId});

  // Opcjonalnie — lista tylko dla jednej budowy
  final int? budowaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kosztorysyListProvider(budowaId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:
            Text(budowaId != null ? 'Kosztorysy budowy' : 'Wszystkie kosztorysy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nowy kosztorys'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          error: e,
          onRetry: () =>
              ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
        ),
        data: (lista) => lista.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context, ref, null))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, i) => _KosztorysCard(
                    item: lista[i],
                    onTap: () => _openDetail(context, lista[i].id),
                  ),
                ),
              ),
      ),
    );
  }

  void _openDetail(BuildContext context, int id) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => KosztorysDetailScreen(kosztorysId: id)));
  }

  void _openForm(BuildContext context, WidgetRef ref, KosztorysListItemModel? existing) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            KosztorysFormScreen(existing: existing, defaultBudowaId: budowaId)));
  }
}

class _KosztorysCard extends StatelessWidget {
  const _KosztorysCard({required this.item, required this.onTap});
  final KosztorysListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nazwa,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  KosztorysStatusBadge(status: item.status),
                ],
              ),
              if (item.opis.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  item.opis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 14, color: cs.outline),
                  SizedBox(width: 4.w),
                  Text(
                    '${item.pozycjeCount} pozycji',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                  const Spacer(),
                  WartoscChip(wartosc: item.wartoscTotal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Błąd połączenia',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('$error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Spróbuj ponownie')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calculate_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          SizedBox(height: 16.h),
          Text('Brak kosztorysów',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8.h),
          Text('Utwórz kosztorys ręcznie lub wygeneruj przez AI',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nowy kosztorys'),
          ),
        ],
      ),
    );
  }
}
