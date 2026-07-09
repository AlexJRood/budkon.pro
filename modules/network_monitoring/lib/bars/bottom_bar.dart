import 'package:core/ui/components/buttons.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'dart:ui' as ui;
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/user/user/user_provider.dart';

class NetworkMonitoringBottomBarMobile extends ConsumerWidget {
  const NetworkMonitoringBottomBarMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final nav = ref.read(navigationService);
    final currentRoute = nav.currentPath;
    double screenWidth = MediaQuery.of(context).size.width;
    final theme = ref.read(themeColorsProvider);

    final double dynamicPadding = screenWidth / 9;

    return SizedBox(
      height: BottomBarSize.resolve(context),
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            color: theme.sidebar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: dynamicPadding),
                SizedBox(
                  width: 55,
                  height: 55,
                  child: BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.home(
                      color:
                          currentRoute == Routes.homeNetworkMonitoring
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'nav_home'.tr,
                    onPressed: () {
                      ref
                          .read(navigationService)
                          .pushNamedScreen(Routes.homeNetworkMonitoring);
                    },
                    route: Routes.homeNetworkMonitoring,
                    currentRoute: currentRoute,
                  ),
                ),
                SizedBox(
                  width: 55,
                  height: 55,
                  child: BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.star(
                      color:
                          currentRoute == Routes.saveNetworkMonitoring
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'saved_searches'.tr,
                    onPressed: () {
                      ref
                          .read(navigationService)
                          .pushNamedScreen(Routes.saveNetworkMonitoring);
                    },
                    route: Routes.saveNetworkMonitoring,
                    currentRoute: currentRoute,
                  ),
                ),
                SizedBox(
                  width: 55,
                  height: 55,
                  child: BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.search(
                      color:
                          currentRoute == Routes.networkMonitoring
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'nav_search'.tr,
                    onPressed: () {
                      ref
                          .read(navigationService)
                          .pushNamedScreen(Routes.networkMonitoring);
                    },
                    route: Routes.networkMonitoring,
                    currentRoute: currentRoute,
                  ),
                ),
                if (isUserLoggedIn) ...[
                  SizedBox(
                    width: 55,
                    height: 55,
                    child: BuildIconButton(
                      isMobile: true,
                      icon: AppIcons.heart(
                        color:
                            currentRoute == Routes.nmFav
                                ? AppColors.white
                                : theme.textColor,
                      ),
                      label: 'nav_favorites'.tr,
                      onPressed: () {
                        ref
                            .read(navigationService)
                            .pushNamedScreen(Routes.nmFav);
                      },
                      route: Routes.nmFav,
                      currentRoute: currentRoute,
                    ),
                  ),
                ],
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (isUserLoggedIn) {
                      return Row(
                        children: [
                          userAsyncValue.when(
                            data:
                                (userData) =>
                                    userData != null
                                        ? SizedBox(
                                          width: 55,
                                          height: 55,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              ref
                                                  .read(navigationService)
                                                  .pushNamedScreen(
                                                    Routes.profile,
                                                  );
                                            },
                                            style: elevatedButtonStyleRounded10,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      ShimmerColors.base(
                                                        context,
                                                      ),
                                                  backgroundImage: NetworkImage(
                                                    userData.avatarUrl ??
                                                        'assets/images/default_user_avatar.jpg',
                                                  ),
                                                  radius: 12.5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        : Container(),
                            loading:
                                () => const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ShimmerPlaceholdercircle(radius: 12.5),
                                  ],
                                ),
                            error: (error, stack) => Text('Error: $error'),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BuildIconButton(
                            isMobile: true,
                            icon: AppIcons.person(color: theme.textColor),
                            label: 'Login'.tr,
                            onPressed: () => pushLoginNative(ref),
                            route: Routes.login,
                            currentRoute: currentRoute,
                          ),
                        ],
                      );
                    }
                  },
                ),
                SizedBox(width: dynamicPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
