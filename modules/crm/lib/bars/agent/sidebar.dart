import 'package:core/shell/components/bottom_buttons.dart';
import 'package:core/ui/components/buttons.dart';
import 'package:core/shell/components/top_buttons.dart';
import 'package:calendar/emma/phone_call_flow_provider.dart';
import 'package:calendar/emma/widgets/phone_call_trigger_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/user/user/company_permissions.dart';
import 'package:core/user/user/company_permissions_service.dart';
import 'dart:ui' as ui;

class SidebarAgentCrm extends ConsumerWidget {
  final GlobalKey<SideMenuState> sideMenuKey;
  const SidebarAgentCrm({super.key, required this.sideMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final nav = ref.read(navigationService);
    final currentRoute = nav.currentPath;

    final theme = ref.watch(themeColorsProvider);

    final canFinance = ref.watch(canUseCompanyFeatureProvider(CompanyFeature.finance));
    final canTransactions = ref.watch(canUseCompanyFeatureProvider(CompanyFeature.transactions));
    final canCalendar = ref.watch(canUseCompanyFeatureProvider(CompanyFeature.calendar));
    final canClients = ref.watch(canUseCompanyFeatureProvider(CompanyFeature.clients));

    return InkWell(
      onTap: () {
        SideMenuManager.toggleMenu(ref: ref, menuKey: sideMenuKey);
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 500, sigmaY: 35),
          child: Container(
            color: theme.sidebar,
            width: 60,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TopButtonsSidebar(
                  currentRoute: currentRoute,
                  sideMenuKey: sideMenuKey,
                  isUserLoggedIn: isUserLoggedIn,
                  ref: ref,
                  color: theme.textColor,
                ),

                Column(
                  children: [
                    BuildIconButton(
                      icon: AppIcons.home(
                        color: currentRoute == Routes.proDashboard
                            ? AppColors.white
                            : theme.textColor,
                      ),
                      label: 'Dashboard'.tr,
                      onPressed: () {
                        ref.read(navigationHistoryProvider.notifier).addPage(Routes.proDashboard);
                        ref.read(navigationService).pushNamedScreen(Routes.proDashboard);
                      },
                      route: Routes.proDashboard,
                      currentRoute: currentRoute,
                    ),

                    if (canTransactions)
                      BuildIconButton(
                        icon: AppIcons.document(
                          color: currentRoute == Routes.proTxDashboard
                              ? AppColors.white
                              : theme.textColor,
                        ),
                        label: 'Transactions'.tr,
                        onPressed: () {
                          ref.read(navigationHistoryProvider.notifier).addPage(Routes.proTxDashboard);
                          ref.read(navigationService).pushNamedScreen(Routes.proTxDashboard);
                        },
                        route: Routes.proTxDashboard,
                        currentRoute: currentRoute,
                      ),

                    if (canFinance)
                      BuildIconButton(
                        icon: AppIcons.pie(
                          color: currentRoute == Routes.proFinance
                              ? AppColors.white
                              : theme.textColor,
                        ),
                        label: 'Finanse'.tr,
                        onPressed: () {
                          ref.read(navigationHistoryProvider.notifier).addPage(Routes.proFinance);
                          ref.read(navigationService).pushNamedScreen(Routes.proFinance);
                        },
                        route: Routes.proFinance,
                        currentRoute: currentRoute,
                      ),

                    if (canCalendar)
                      BuildIconButton(
                        icon: AppIcons.calendar(
                          color: currentRoute == Routes.proCalendar
                              ? AppColors.white
                              : theme.textColor,
                        ),
                        label: 'nav_calendar'.tr,
                        onPressed: () {
                          ref.read(navigationHistoryProvider.notifier).addPage(Routes.proCalendar);
                          ref.read(navigationService).pushNamedScreen(Routes.proCalendar);
                        },
                        route: Routes.proCalendar,
                        currentRoute: currentRoute,
                      ),

                    BuildIconButton(
                      icon: AppIcons.task(
                        color: currentRoute == Routes.proTodo
                            ? AppColors.white
                            : theme.textColor,
                      ),
                      label: 'Todo'.tr,
                      onPressed: () {
                        ref.read(navigationHistoryProvider.notifier).addPage(Routes.proTodo);
                        ref.read(navigationService).pushNamedScreen(Routes.proTodo);
                      },
                      route: Routes.proTodo,
                      currentRoute: currentRoute,
                    ),

                    if (canClients)
                      BuildIconButton(
                        icon: AppIcons.viewList(
                          color: currentRoute == Routes.proClients
                              ? AppColors.white
                              : theme.textColor,
                        ),
                        label: 'nav_clients'.tr,
                        onPressed: () {
                          ref.read(navigationHistoryProvider.notifier).addPage(Routes.proClients);
                          ref.read(navigationService).pushNamedScreen(Routes.proClients);
                        },
                        route: Routes.proClients,
                        currentRoute: currentRoute,
                      ),

                    Consumer(
                      builder: (context, ref, _) {
                        final callState = ref.watch(phoneCallFlowProvider);
                        final isActive = !callState.isIdle;
                        return BuildIconButton(
                          icon: Icon(
                            isActive
                                ? Icons.phone_in_talk_rounded
                                : Icons.phone_rounded,
                            color: isActive ? AppColors.white : theme.textColor,
                            size: 22,
                          ),
                          label: 'Rozmowa',
                          onPressed: isActive
                              ? () {}
                              : () => showPhoneCallStartDialog(context),
                          currentRoute: isActive ? 'phone_call' : currentRoute,
                          route: isActive ? 'phone_call' : null,
                        );
                      },
                    ),
                  ],
                ),

                BottomButtonsSidebar(
                  isUserLoggedIn: isUserLoggedIn,
                  currentRoute: currentRoute,
                  ref: ref,
                  color: theme.textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
