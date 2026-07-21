import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/kosztorys_model.dart';
import '../../data/providers/kosztorysy_provider.dart';
import '../../widgets/kosztorys_status_badge.dart';
import '../../widgets/wartosc_chip.dart';

class KosztorysyListScreen extends ConsumerWidget {
  const KosztorysyListScreen({super.key, this.budowaId});
  final int? budowaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final state = ref.watch(kosztorysyListProvider(budowaId));

    final content = state.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
      error: (e, _) => _ErrorView(
        error: e,
        theme: theme,
        onRetry: () => ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
      ),
      data: (lista) => lista.isEmpty
          ? _EmptyState(
              onAdd: () => ref.read(navigationService).pushNamedScreen(
                    '/kosztorysy/new',
                    data: {'budowaId': budowaId},
                  ),
              theme: theme)
          : RefreshIndicator(
              onRefresh: () => ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
              color: theme.themeColor,
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: lista.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) => _KosztorysCard(
                  item: lista[i],
                  onTap: () => ref
                      .read(navigationService)
                      .pushNamedScreen('/kosztorysy/${lista[i].id}'),
                ),
              ),
            ),
    );

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      verticalButtonsPc: IconButton(
        icon: Icon(Icons.refresh, color: theme.textColor),
        onPressed: () => ref.read(kosztorysyListProvider(budowaId).notifier).fetch(),
      ),
      childPc: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => ref.read(navigationService).pushNamedScreen(
                    '/kosztorysy/new',
                    data: {'budowaId': budowaId},
                  ),
              backgroundColor: theme.themeColor,
              icon: Icon(Icons.add, color: theme.buttonTextColor),
              label: Text('Nowy kosztorys', style: TextStyle(color: theme.buttonTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _KosztorysCard extends ConsumerWidget {
  const _KosztorysCard({required this.item, required this.onTap});
  final KosztorysListItemModel item;
  final VoidCallback onTap;

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
                    child: Text(item.nazwa,
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  KosztorysStatusBadge(status: item.status),
                ],
              ),
              if (item.opis.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(item.opis,
                    style: TextStyle(color: theme.textColor.withAlpha(140), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 14, color: theme.textColor.withAlpha(120)),
                  SizedBox(width: 4.w),
                  Text('${item.pozycjeCount} pozycji',
                      style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12)),
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
  const _ErrorView({required this.error, required this.onRetry, required this.theme});
  final Object error;
  final VoidCallback onRetry;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: theme.textColor.withAlpha(80)),
          const SizedBox(height: 12),
          Text('Błąd połączenia',
              style: TextStyle(
                  color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$error',
              style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
            child: Text('Spróbuj ponownie', style: TextStyle(color: theme.buttonTextColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.theme});
  final VoidCallback onAdd;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calculate_outlined, size: 64, color: theme.textColor.withAlpha(80)),
          SizedBox(height: 16.h),
          Text('Brak kosztorysów',
              style: TextStyle(
                  color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Text('Utwórz kosztorys ręcznie lub wygeneruj przez AI',
              style: TextStyle(color: theme.textColor.withAlpha(150), fontSize: 13),
              textAlign: TextAlign.center),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(backgroundColor: theme.themeColor),
            icon: Icon(Icons.add, color: theme.buttonTextColor),
            label: Text('Nowy kosztorys', style: TextStyle(color: theme.buttonTextColor)),
          ),
        ],
      ),
    );
  }
}
