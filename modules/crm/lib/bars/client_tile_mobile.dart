import 'dart:ui';

import 'package:crm/pie_menu/clients_pro.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';

class ClientTileMobile extends ConsumerWidget {
  const ClientTileMobile({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = ref.read(themeColorsProvider);
    const defaultAvatarUrl =
        'https://www.superbee.cloud/media/avatars/avatar_PvxQuoF.jpg'; // Zmienna do przechowywania URL domyślnego awatara
    final clientListAsyncValue = ref.watch(clientProvider);
    ScrollController scrollController = ScrollController();
    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: CustomBackgroundGradients.adGradient1(context, ref),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'no_clients_available'.tr,
                  style: AppTextStyles.interRegular12.copyWith(
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          );
        }
        return DragScrollView(
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...clients.map((client) {
                  return PieMenu(
                    theme: PieTheme.of(context).copyWith(
                        overlayColor:
                            (() {
                              final theme = ref.watch(themeColorsProvider);
                              final bool uiIsDark =
                                  theme.textColor.computeLuminance() > 0.5;

                              final base =
                                  uiIsDark ? Colors.black : Colors.white;
                              return base.withValues(alpha: 0.70);
                            })(),
                      ),
                    onPressedWithDevice: (kind) {
                      if (kind == PointerDeviceKind.mouse ||
                          kind == PointerDeviceKind.touch) {
                        final routeName =
                            ref.read(navigationService).currentPath;
                        final baseRoute = removeContactSegment(routeName);

                        if (routeName.contains('contact') &&
                            routeName.contains('dashboard')) {
                          ref.read(navigationService).beamPop();
                          ref
                              .read(navigationService)
                              .pushNamedScreen(
                                '$baseRoute/contact/${client.id}/dashboard',
                                data: {'clientViewPop': client},
                              );
                        } else {
                          ref
                              .read(navigationService)
                              .pushNamedScreen(
                                '$baseRoute/contact/${client.id}/dashboard',
                                data: {'clientViewPop': client},
                              );
                        }
                      }
                    },
                    actions: buildPieMenuActionsClientsPro(
                      ref,
                      client.id,
                      client,
                      context,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Handle client-specific tap logic
                        ref
                            .read(navigationService)
                            .pushNamedScreen(Routes.proAddClient);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            client.avatar ?? defaultAvatarUrl,
                          ),
                          child:
                              client.avatar == null
                                  ? AppIcons.search(
                                    color: Theme.of(context).iconTheme.color,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading:
          () => DragScrollView(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  15, // Number of shimmer placeholders
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: ShimmerPlaceholder(
                      height: 65,
                      width: 65,
                      radius: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),
      error:
          (error, stackTrace) => Center(
            child: Text(
              'Error loading clients'.tr,
              style: AppTextStyles.interRegular12,
            ),
          ),
    );
  }

  String removeContactSegment(String path) {
    // This removes the last '/contact/:id/dashboard' from the path
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}
