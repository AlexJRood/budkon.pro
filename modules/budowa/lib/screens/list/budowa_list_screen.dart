import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/budowa_model.dart';
import '../../data/providers/budowa_provider.dart';
import '../../widgets/budowa_status_badge.dart';
import '../../widgets/postep_bar.dart';

class BudowaListScreen extends ConsumerWidget {
  const BudowaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(budowaListProvider);

    final content = state.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.textColor.withAlpha(80)),
            const SizedBox(height: 12),
            Text('Błąd połączenia',
                style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(budowaListProvider.notifier).fetch(),
              style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
              child: Text('Spróbuj ponownie', style: TextStyle(color: theme.buttonTextColor)),
            ),
          ],
        ),
      ),
      data: (budowy) => budowy.isEmpty
          ? _EmptyState(
              onAdd: () => ref.read(navigationService).pushNamedScreen('/budowa/new'))
          : RefreshIndicator(
              onRefresh: () => ref.read(budowaListProvider.notifier).fetch(),
              color: theme.themeColor,
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: budowy.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, i) => _BudowaCard(
                  budowa: budowy[i],
                  onTap: () => ref
                      .read(navigationService)
                      .pushNamedScreen('/budowa/${budowy[i].id}'),
                  onEdit: () => ref.read(navigationService).pushNamedScreen(
                        '/budowa/${budowy[i].id}/edit',
                        data: {'existing': budowy[i]},
                      ),
                ),
              ),
            ),
    );

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: IconButton(
        icon: Icon(Icons.refresh, color: theme.textColor),
        onPressed: () => ref.read(budowaListProvider.notifier).fetch(),
      ),
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => ref.read(navigationService).pushNamedScreen('/budowa/new'),
              backgroundColor: theme.themeColor,
              icon: Icon(Icons.add, color: theme.buttonTextColor),
              label: Text('Nowa budowa', style: TextStyle(color: theme.buttonTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudowaCard extends ConsumerWidget {
  const _BudowaCard({
    required this.budowa,
    required this.onTap,
    required this.onEdit,
  });

  final BudowaModel budowa;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.userTile,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.bordercolor.withAlpha(60)),
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
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BudowaStatusBadge(status: budowa.status),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: theme.textColor.withAlpha(150)),
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
                    Icon(Icons.location_on_outlined,
                        size: 14, color: theme.textColor.withAlpha(120)),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        budowa.adres,
                        style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
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
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: theme.textColor.withAlpha(120)),
                  SizedBox(width: 4.w),
                  Text(
                    '${budowa.etapyCount} etapów',
                    style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
                  ),
                  const Spacer(),
                  if (budowa.budzet > 0)
                    Text(
                      '${_fmt(budowa.budzet)} zł',
                      style: TextStyle(
                        color: theme.themeColor,
                        fontSize: 13,
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.domain_add_outlined, size: 64, color: theme.textColor.withAlpha(80)),
          SizedBox(height: 16.h),
          Text('Brak budów',
              style: TextStyle(
                  color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Text(
            'Dodaj pierwszy projekt budowlany',
            style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
            icon: Icon(Icons.add, color: theme.buttonTextColor),
            label: Text('Nowa budowa', style: TextStyle(color: theme.buttonTextColor)),
          ),
        ],
      ),
    );
  }
}
