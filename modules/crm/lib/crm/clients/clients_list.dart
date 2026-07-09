
import 'package:core/ui/device_type_util.dart';
import 'package:crm/crm/clients/expand_client.dart';
import 'package:crm/crm/clients/status_dropdown.dart';
import 'package:crm/crm/clients/type_dropdown.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/pie_menu/clients_pro.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/url.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:crm/bars/contact_log.dart';

const configUrl = URLs.baseUrl;
const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

class ClientList extends ConsumerWidget {
  final bool isMobile;
  const ClientList({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientListAsyncValue = ref.watch(clientProvider);
    final theme = ref.read(themeColorsProvider);

    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Center(child: AppLottie.noResults(size: 450));
        }

        final notifier = ref.read(clientProvider.notifier);
        final hasMore = notifier.hasMore;

        return Container(
          margin: EdgeInsets.only(
            bottom: isMobile ? BottomBarSize.resolve(context) + 5 : 10,
          ),
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.textFieldColor,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Name and last name'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Type'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Email'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Phone Number'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ],

              // LIST + LAZY LOAD
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // ⬇️ Important guards so we DON'T auto-load all pages on first build
                    if (notification is ScrollUpdateNotification) {
                      final metrics = notification.metrics;

                      // List not scrollable yet → ignore
                      if (metrics.maxScrollExtent <= 0) return false;

                      // User hasn’t scrolled down yet → ignore
                      if (metrics.pixels <= 0) return false;

                      // Only when user is near bottom
                      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                        final notifier = ref.read(clientProvider.notifier);
                        if (notifier.hasMore && !notifier.isFetching) {
                          notifier.fetchClients(
                            append: true,
                            silentIfUnchanged: true,
                          );
                        }
                      }
                    }
                    return false;
                  },
                  child: ListView.separated(
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 10),
                    itemCount: hasMore ? clients.length + 1 : clients.length,
                    itemBuilder: (context, index) {
                      // Shimmer loader row at the bottom while next page loads
                      if (index >= clients.length) {
                        return const _ClientShimmerLoader();
                      }

                      final client = clients[index];

                      if (isMobile) {
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
                              ref.read(contactOpenLogProvider.notifier).logOpen(client.id, source: 'client_list');

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
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: theme.dashboardContainer,
                            ),
                            child: ClientExpandableTile(
                              theme: theme,
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      client.avatar ?? defaultAvatarUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              title: '${client.name} ${client.lastName}',
                              status: client.contactType.toString(),
                              email: client.email,
                              phone: client.phoneNumber,
                              onViewProfile: () {
                                final routeName =
                                    ref.read(navigationService).currentPath;
                                final baseRoute = removeContactSegment(
                                  routeName,
                                );

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
                              },
                            ),
                          ),
                        );
                      } else {
                        return _ClientDesktopItem(client: client, theme: theme);
                      }
                    },
                  ),
                ),
              ),

              // Footer Pagination (informational only)
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.textFieldColor,
                  ),
                  child: Row(
                    children: [
                      Text(
                        hasMore
                            ? 'Showing ${clients.length}+'.tr
                            : 'Showing ${clients.length} out of ${clients.length}'
                                .tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(
                            (255 * 0.85).toInt(),
                          ),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: AppIcons.iosArrowLeft(
                          color: theme.textColor.withAlpha(
                            (255 * 0.85).toInt(),
                          ),
                        ),
                        onPressed: () {},
                      ),
                      Text('1', style: TextStyle(color: theme.textColor)),
                      IconButton(
                        icon: AppIcons.iosArrowRight(
                          color: theme.textColor.withAlpha(
                            (255 * 0.85).toInt(),
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (err, stack) {
        return Center(child: AppLottie.error(size: 450));
      },
    );
  }

  String removeContactSegment(String path) {
    // This removes the last '/contact/:id/dashboard' from the path
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}

class _ClientShimmerLoader extends StatelessWidget {
  const _ClientShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ClientShimmerItem(),
        SizedBox(height: 5),
        _ClientShimmerItem(),
        SizedBox(height: 5),
        _ClientShimmerItem(),
      ],
    );
  }
}

class _ClientShimmerItem extends StatelessWidget {
  const _ClientShimmerItem();

  @override
  Widget build(BuildContext context) {
    return const ShimmerPlaceholder(
      width: double.infinity,
      height: 64,
      radius: 6,
    );
  }
}

class _ClientDesktopItem extends ConsumerStatefulWidget {
  final dynamic client;
  final dynamic theme;

  const _ClientDesktopItem({required this.client, required this.theme});

  @override
  ConsumerState<_ClientDesktopItem> createState() => _ClientDesktopItemState();
}

class _ClientDesktopItemState extends ConsumerState<_ClientDesktopItem> {
  bool _menuOpen = false;
  final _pieController = PieMenuController();

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final theme = widget.theme;

    return PieMenu(
      theme: PieTheme.of(context).copyWith(
        overlayColor:
            (() {
              final theme = ref.watch(themeColorsProvider);
              final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;

              final base = uiIsDark ? Colors.black : Colors.white;
              return base.withValues(alpha: 0.70);
            })(),
      ),
      controller: _pieController,
      actions: buildPieMenuActionsClientsPro(ref, client.id, client, context),
      onToggle: (open) => setState(() => _menuOpen = open),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _menuOpen
                  ? Color.lerp(theme.textFieldColor, Colors.black, 0.2)
                  : theme.textFieldColor,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {

          ref.read(contactOpenLogProvider.notifier).logOpen(client.id, source: 'client_list');

          final routeName = ref.read(navigationService).currentPath;
          final baseRoute = removeContactSegment(routeName);

          if (routeName.contains('contact') &&
              routeName.contains('dashboard')) {
            ref.read(navigationService).beamPop();
          }
          ref
              .read(navigationService)
              .openPopup(
                '$baseRoute/contact/${client.id}/dashboard',
                data: {'clientViewPop': client},
              );
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(client.avatar ?? defaultAvatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                '${client.name} ${client.lastName}',
                style: TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ),
            Expanded(
              child: ContactTypePillDropdown(
                currentTypeId: client.contactType,
                onChanged: (newId) async {
                  await ref
                      .read(clientProvider.notifier)
                      .patchClientContactType(client.id, newId);
                },
                maxPillWidth: 180,
                menuMaxHeight: 300,
              ),
            ),
            Expanded(
              child: ClientStatusPillDropdown(
                currentStatusId: int.tryParse(client.contactStatus ?? ''),
                onChanged: (newId) async {
                  await ref
                      .read(clientProvider.notifier)
                      .patchClientStatusId(client.id, newId);
                },
                maxPillWidth: 180,
                menuMaxHeight: 300,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                client.email ?? '-',
                style: TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ),
            Expanded(
              child: Text(
                client.phoneNumber ?? '-',
                style: TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ),
            IconButton(
              icon: AppIcons.moreVertical(color: theme.textColor),
              onPressed: () {
                _pieController.toggleMenu(menuAlignment: Alignment.centerRight);
              },
            ),
          ],
        ),
      ),
    );
  }

  String removeContactSegment(String path) {
    final regex = RegExp(r'/contact/\d+/dashboard$');
    return path.replaceAll(regex, '');
  }
}
