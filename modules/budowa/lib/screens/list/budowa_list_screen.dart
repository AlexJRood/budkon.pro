import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/budowa_model.dart';
import '../../data/providers/budowa_provider.dart';
import '../../widgets/budowa_status_badge.dart';
import '../../widgets/postep_bar.dart';
import '../detail/budowa_detail_screen.dart';
import '../form/budowa_form_screen.dart';

class BudowaListScreen extends ConsumerWidget {
  const BudowaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budowaListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Budowy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(budowaListProvider.notifier).fetch(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nowa budowa'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Błąd połączenia', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$e', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(budowaListProvider.notifier).fetch(),
                child: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
        data: (budowy) => budowy.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context, ref, null))
            : RefreshIndicator(
                onRefresh: () => ref.read(budowaListProvider.notifier).fetch(),
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: budowy.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, i) => _BudowaCard(
                    budowa: budowy[i],
                    onTap: () => _openDetail(context, budowy[i].id),
                    onEdit: () => _openForm(context, ref, budowy[i]),
                  ),
                ),
              ),
      ),
    );
  }

  void _openDetail(BuildContext context, int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BudowaDetailScreen(budowaId: id)),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, BudowaModel? existing) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BudowaFormScreen(existing: existing)),
    );
  }
}

class _BudowaCard extends StatelessWidget {
  const _BudowaCard({
    required this.budowa,
    required this.onTap,
    required this.onEdit,
  });

  final BudowaModel budowa;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                      budowa.nazwa,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  BudowaStatusBadge(status: budowa.status),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (budowa.adres.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.outline),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        budowa.adres,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: PostepBar(postep: budowa.postep)),
                  SizedBox(width: 12.w),
                  Text(
                    '${budowa.postep}%',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: theme.colorScheme.outline),
                  SizedBox(width: 4.w),
                  Text(
                    '${budowa.etapyCount} etapów',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const Spacer(),
                  if (budowa.budzet > 0)
                    Text(
                      '${_fmt(budowa.budzet)} zł',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} mln';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} tys.';
    return v.toStringAsFixed(0);
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
          Icon(Icons.domain_add_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          SizedBox(height: 16.h),
          Text('Brak budów', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8.h),
          Text(
            'Dodaj pierwszy projekt budowlany',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nowa budowa'),
          ),
        ],
      ),
    );
  }
}
