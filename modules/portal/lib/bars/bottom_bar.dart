import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

import 'package:core/ui/device_type_util.dart';

class BottomBarMobile extends ConsumerWidget {
  const BottomBarMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);
    final isUserLoggedIn = ApiServices.isUserLoggedIn();
    final nav = ref.read(navigationService);
    final currentRoute = nav.currentPath;
    final theme = ref.read(themeColorsProvider);

    // Determine the color based on theme and route
    final Color color = theme.textColor;

    double screenWidth = MediaQuery.of(context).size.width;

    final double dynamicPadding = screenWidth / 9;

    return Container(
      color: Colors.transparent,
      height: BottomBarSize.resolve(context),
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            decoration: BoxDecoration(color: theme.sidebar),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dynamicPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.home(
                      height: 25,
                      width: 25,
                      color:
                          currentRoute == Routes.entry
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'nav_home'.tr,
                    onPressed: () {
                      ref.read(selectedRouteProvider.notifier).state =
                          Routes.entry;
                      ref.read(navigationService).pushNamedScreen(Routes.entry);
                    },
                    route: Routes.entry,
                    currentRoute: currentRoute,
                  ),

                  BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.search(
                      height: 25,
                      width: 25,
                      color:
                          currentRoute == Routes.feedView
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'nav_search'.tr,
                    onPressed: () {
                      ref.read(selectedRouteProvider.notifier).state =
                          selectedFeedViewProvider.toString();
                      String selectedFeedView = ref.read(
                        selectedFeedViewProvider,
                      ); // Odczytaj wybrany widok
                      ref
                          .read(navigationService)
                          .pushNamedScreen(selectedFeedView);
                    },
                    route: Routes.feedView,
                    currentRoute: currentRoute,
                  ),

                  if (isUserLoggedIn) ...[
                    BuildIconButton(
                      isMobile: true,
                      icon: AppIcons.heart(
                        height: 25,
                        width: 25,
                        color:
                            currentRoute == Routes.fav
                                ? AppColors.white
                                : theme.textColor,
                      ),
                      label: '',
                      onPressed: () {
                        ref.read(selectedRouteProvider.notifier).state =
                            Routes.fav;
                        ref.read(navigationService).pushNamedScreen(Routes.fav);
                      },
                      route: Routes.fav,
                      currentRoute: currentRoute,
                    ),
                  ],

                  BuildIconButton(
                    isMobile: true,
                    icon: AppIcons.add(
                      height: 25,
                      width: 25,
                      color:
                          currentRoute == Routes.add
                              ? AppColors.white
                              : theme.textColor,
                    ),
                    label: 'Add'.tr,
                    onPressed: () {
                      ref.read(selectedRouteProvider.notifier).state =
                          Routes.add;
                      ref.read(navigationService).pushNamedScreen(Routes.add);
                    },
                    route: Routes.add,
                    currentRoute: currentRoute,
                  ),

                  if (isUserLoggedIn) ...[
                    userAsyncValue.when(
                      data: (userData) {
                        return SizedBox(
                          width: 55,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(selectedRouteProvider.notifier).state =
                                  Routes.profile;
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.profile);
                            },
                            style: elevatedButtonStyleRounded10withoutPadding,
                            child: Center(
                              child: CircleAvatar(
                                backgroundColor: ShimmerColors.background(
                                  context,
                                ),
                                backgroundImage:
                                    userData?.avatarUrl != null
                                        ? CachedNetworkImageProvider(
                                          userData!.avatarUrl!,
                                        )
                                        : const AssetImage(
                                              'assets/images/default_user_avatar.jpg',
                                            )
                                            as ImageProvider,
                                radius: 15,
                              ),
                            ),
                          ),
                        );
                      },
                      loading:
                          () => const Padding(
                            padding: EdgeInsets.all(5),
                            child: ShimmerPlaceholdercircle(radius: 15),
                          ),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                  if (!isUserLoggedIn) ...[
                    BuildIconButton(
                      isMobile: true,
                      icon: AppIcons.person(
                        height: 25,
                        width: 25,
                        color:
                            currentRoute == Routes.login
                                ? AppColors.white
                                : theme.textColor,
                      ),
                      label: 'btn_login'.tr,
                      onPressed: () => pushLoginNative(ref),
                      route: Routes.login,
                      currentRoute: currentRoute,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
