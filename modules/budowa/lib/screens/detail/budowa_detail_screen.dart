import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/budowa_model.dart';
import '../../data/providers/budowa_provider.dart';
import '../../widgets/budowa_status_badge.dart';
import '../../widgets/etap_tile.dart';
import '../../widgets/postep_bar.dart';
import '../form/budowa_form_screen.dart';

class BudowaDetailScreen extends ConsumerWidget {
  const BudowaDetailScreen({super.key, required this.budowaId});

  final int budowaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budowaDetailProvider(budowaId));

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Błąd: $e')),
      ),
      data: (budowa) => _BudowaDetail(budowa: budowa),
    );
  }
}

class _BudowaDetail extends ConsumerWidget {
  const _BudowaDetail({required this.budowa});
  final BudowaModel budowa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(budowa.nazwa),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BudowaFormScreen(existing: budowa)),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + adres
                  Row(
                    children: [
                      BudowaStatusBadge(status: budowa.status),
                      const Spacer(),
                      if (budowa.budzet > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${_fmt(budowa.budzet)} zł',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (budowa.adres.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.outline),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(budowa.adres, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 20.h),

                  // Progress
                  _SectionHeader('Postęp', icon: Icons.trending_up),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: PostepBar(postep: budowa.postep, height: 10)),
                      SizedBox(width: 12.w),
                      Text(
                        '${budowa.postep}%',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${budowa.etapy.where((e) => e.status == StatusEtapu.zakończony).length} z ${budowa.etapy.length} etapów zakończonych',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  SizedBox(height: 24.h),

                  // Etapy
                  _SectionHeader('Etapy budowy', icon: Icons.layers_outlined),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),

          // Etapy lista
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverList.separated(
              itemCount: budowa.etapy.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (context, i) {
                final etap = budowa.etapy[i];
                return EtapTile(
                  etap: etap,
                  onStatusChange: (nowyStatus) async {
                    await ref
                        .read(budowaFormProvider.notifier)
                        .updateEtapStatus(etap.id, nowyStatus);
                    ref.invalidate(budowaDetailProvider(budowa.id));
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} mln';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} tys.';
    return v.toStringAsFixed(0);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        SizedBox(width: 6.w),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
