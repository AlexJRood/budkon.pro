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
import '../../widgets/etap_tile.dart';
import '../../widgets/postep_bar.dart';

class BudowaDetailScreen extends ConsumerWidget {
  const BudowaDetailScreen({super.key, required this.budowaId});

  final int budowaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);
    final async = ref.watch(budowaDetailProvider(budowaId));

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.budkon,
      childPc: async.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.themeColor)),
        error: (e, _) =>
            Center(child: Text('Błąd: $e', style: TextStyle(color: theme.textColor))),
        data: (budowa) => _BudowaDetail(budowa: budowa),
      ),
    );
  }
}

class _BudowaDetail extends ConsumerWidget {
  const _BudowaDetail({required this.budowa});
  final BudowaModel budowa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(budowa.nazwa, style: TextStyle(color: theme.textColor)),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.textColor),
              onPressed: () => ref.read(navigationService).pushNamedScreen(
                    '/budowa/${budowa.id}/edit',
                    data: {'existing': budowa},
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
                Row(
                  children: [
                    BudowaStatusBadge(status: budowa.status),
                    const Spacer(),
                    if (budowa.budzet > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: theme.themeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${_fmt(budowa.budzet)} zł',
                          style: TextStyle(
                            color: theme.themeColor,
                            fontSize: 16,
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
                      Icon(Icons.location_on_outlined,
                          size: 16, color: theme.textColor.withAlpha(120)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          budowa.adres,
                          style: TextStyle(color: theme.textColor.withAlpha(180), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 20.h),

                _SectionHeader('Postęp', icon: Icons.trending_up, theme: theme),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(child: PostepBar(postep: budowa.postep, height: 10)),
                    SizedBox(width: 12.w),
                    Text(
                      '${budowa.postep}%',
                      style: TextStyle(
                          color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${budowa.etapy.where((e) => e.status == StatusEtapu.zakonczony).length} z ${budowa.etapy.length} etapów zakończonych',
                  style: TextStyle(color: theme.textColor.withAlpha(120), fontSize: 12),
                ),
                SizedBox(height: 24.h),

                _SectionHeader('Etapy budowy', icon: Icons.layers_outlined, theme: theme),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),

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

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
            child: _SectionHeader('Moduły budowy', icon: Icons.apps_outlined, theme: theme),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _ModulTile(
                icon: Icons.calculate_outlined,
                label: 'Kosztorys',
                color: const Color(0xFF9C27B0),
                onTap: () => ref.read(navigationService).pushNamedScreen('/kosztorysy?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.description_outlined,
                label: 'Oferty',
                color: const Color(0xFFFF9800),
                onTap: () => ref.read(navigationService).pushNamedScreen('/oferty?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.inventory_2_outlined,
                label: 'Materiały',
                color: const Color(0xFF607D8B),
                onTap: () => ref.read(navigationService).pushNamedScreen('/materialy?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.book_outlined,
                label: 'Dziennik',
                color: const Color(0xFF8BC34A),
                onTap: () => ref.read(navigationService).pushNamedScreen('/dziennik?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.groups_outlined,
                label: 'Zespół',
                color: const Color(0xFF5C6BC0),
                onTap: () => ref.read(navigationService).pushNamedScreen('/pracownicy?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.receipt_long_outlined,
                label: 'Faktury',
                color: const Color(0xFF26A69A),
                onTap: () => ref.read(navigationService).pushNamedScreen('/faktury?budowa=${budowa.id}'),
              ),
              _ModulTile(
                icon: Icons.link_outlined,
                label: 'Portal klienta',
                color: const Color(0xFF7E57C2),
                onTap: () => ref.read(navigationService).pushNamedScreen(
                      '/budowy/${budowa.id}/portale',
                      data: {'budowaNazwa': budowa.nazwa},
                    ),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 80.h)),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} mln';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} tys.';
    return v.toStringAsFixed(0);
  }
}

class _ModulTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModulTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: 10.w),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.icon, required this.theme});
  final String label;
  final IconData icon;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.themeColor),
        SizedBox(width: 6.w),
        Text(label,
            style: TextStyle(
                color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
