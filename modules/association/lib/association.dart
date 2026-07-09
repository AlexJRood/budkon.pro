import 'package:association/providers/loyalty.dart';
import 'package:association/screens/loyalty/loyalty.dart';
import 'package:association/widgets/announcements.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_calendar_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';



class AssociationMember extends ConsumerWidget {
  final int assosiationId;
  static const _baseUrl = 'https://www.superbee.cloud';

  const AssociationMember({super.key, required this.assosiationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    final programsAsync = ref.watch(
      loyaltyProgramsProvider((
        baseUrl: _baseUrl,
        associationId: assosiationId,
      )),
    );
    final programId = programsAsync.whenOrNull(
          data: (programs) {
            if (programs.isEmpty) return null;
            try {
              return programs.firstWhere((p) => p.isActive).id;
            } catch (_) {
              return programs.first.id;
            }
          },
        ) ??
        1;

    final balanceAsync = ref.watch(
      balanceProv((programId: programId, baseUrl: _baseUrl)),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final conHght = screenHeight - 300;


    

    final nav = ref.read(navigationService);

    // Reusable widget: karta punktów + progress
    Widget _buildBalanceCard() {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          border: Border.all(color: theme.dashboardBoarder),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: balanceAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Błąd: $e'),
          data: (b) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Twoje punkty: ${b.points}  |  Poziom: ${b.tier}',
                style: TextStyle(color: theme.textColor),
              ),
              if (b.nextTier != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Następny próg: ${b.nextTier} (${b.nextThreshold})',
                      style: TextStyle(color: theme.textColor),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (b.progressPercent / 100).clamp(0, 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.association,
      paddingPc: 10,

      // PC – przycisk po prawej w pionowym pasku
      verticalButtonsPc: SizedBox(
        height: 48,
        width: 48,
        child: ElevatedButton(
          style: buttonStyleRounded10ThemeRed,
          onPressed: () => nav.pushNamedScreen('${Routes.associationAdminPath}/8'),
          child: const Icon(Icons.swap_horiz_outlined, color: AppColors.white),
        ),
      ),

      /// ==========================
      /// DESKTOP / PC
      /// ==========================
      childrenPc: [
        const SizedBox(height: 10),
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lewa strona: tekst powitalny + ogłoszenia
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Welcome back association member!'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Association Management Dashboard.'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DashboardNewsAndAnnouncements(
                          theme: theme,
                          associationId: assosiationId,
                          baseUrl: 'https://www.superbee.cloud',
                          height: conHght,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Prawa strona: punkty + kalendarz
            Expanded(
              flex: 1,
              child: Column(
                spacing: 10,
                children: [
                  _buildBalanceCard(),
                  const DbCalendarWidget(),
                ],
              ),
            ),
          ],
        ),
      ],

      /// ==========================
      /// MOBILE
      /// ==========================
      childrenMobile: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Welcome back association member!'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Association Management Dashboard.'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildBalanceCard(),
              const SizedBox(height: 12),
              const DbCalendarWidget(),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Ogłoszenia na dole, scrolowane
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DashboardNewsAndAnnouncements(
              theme: theme,
              associationId: assosiationId,
              baseUrl: 'https://www.superbee.cloud',
              // Na mobile nie spinamy wysokością – niech rośnie w Expanded
            ),
          ),
        ),
      ],
    );
  }
}
