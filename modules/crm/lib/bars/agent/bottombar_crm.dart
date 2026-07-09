import 'package:core/ui/components/buttons.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/platform/navigation_service.dart';
import 'dart:ui' as ui;

class BottombarCrm extends ConsumerWidget {
  const BottombarCrm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(navigationService);
    final currentRoute = nav.currentPath;
    final theme = ref.read(themeColorsProvider);

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          height: BottomBarSize.resolve(context),
          color: theme.sidebar,
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //dark and white mode
              const SizedBox(width: 10),
              BuildIconButton(
                isMobile: true,
                icon: AppIcons.home(
                  color:
                      currentRoute == Routes.proDashboard
                          ? AppColors.white
                          : theme.textColor,
                ),
                label: 'nav_home'.tr,
                onPressed:
                    () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proDashboard),
                route: Routes.proDashboard,
                currentRoute: currentRoute,
              ),
              const SizedBox(height: 15.0),
              BuildIconButton(
                isMobile: true,
                icon: AppIcons.pie(
                  color:
                      currentRoute == Routes.proDraggable
                          ? AppColors.white
                          : theme.textColor,
                ),
                label: 'Finanse'.tr,
                onPressed:
                    () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proDraggable),
                route: Routes.proDraggable,
                currentRoute: currentRoute,
              ),
              const SizedBox(height: 15.0),
              BuildIconButton(
                isMobile: true,
                icon: AppIcons.calendar(
                  color:
                      currentRoute == Routes.proCalendar
                          ? AppColors.white
                          : theme.textColor,
                ),
                label: 'nav_calendar'.tr,
                onPressed:
                    () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proCalendar),
                route: Routes.proCalendar,
                currentRoute: currentRoute,
              ),
              const SizedBox(height: 15.0),
              BuildIconButton(
                isMobile: true,
                icon: AppIcons.task(
                  color:
                      currentRoute == Routes.proTodo
                          ? AppColors.white
                          : theme.textColor,
                ),
                label: 'Todo',
                onPressed:
                    () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proTodo),
                route: Routes.proTodo,
                currentRoute: currentRoute,
              ),

              // const SizedBox(height: 15.0),
              // BuildIconButton(
              //   isMobile: true,
              //   icon: AppIcons.em(original: true),
              //   label: 'Emma'.tr,
              //   currentRoute: currentRoute,
              //  onPressed: () {
              //           Navigator.of(context).push(
              //             PageRouteBuilder(
              //               opaque: false,
              //               pageBuilder: (_, __, ___) => const AiPage(),
              //               transitionsBuilder: (_, anim, __, child) {
              //                 return FadeTransition(
              //                   opacity: anim,
              //                   child: child,
              //                 );
              //               },
              //             ),
              //           );
              //         },
              // ),
              const SizedBox(height: 15.0),
              BuildIconButton(
                isMobile: true,
                icon: AppIcons.viewList(
                  color:
                      currentRoute == Routes.proClients
                          ? AppColors.white
                          : theme.textColor,
                ),
                label: 'nav_clients'.tr,
                onPressed:
                    () => ref
                        .read(navigationService)
                        .pushNamedScreen(Routes.proClients),
                route: Routes.proClients,
                currentRoute: currentRoute,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
