import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:notification/notification_screen.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/icons.dart';
import 'package:core/common/loading_widgets.dart';
import 'dart:ui' as ui;
import 'package:core/user/login/login/login_navigation.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:core/shell/keyboard_shortcuts.dart';
import 'package:core/common/chrome/side_menu_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class SidebarPanel extends ConsumerStatefulWidget {
  final GlobalKey<SideMenuState> sideMenuKey;

  const SidebarPanel({super.key, required this.sideMenuKey});

  @override
  ConsumerState<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends ConsumerState<SidebarPanel>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userAsyncValue = ref.watch(userProvider);
    final isUserLoggedIn = ref.watch(authStateProvider);
    final theme = ref.watch(themeColorsProvider);
    final nav = ref.read(navigationService);
    final currentRoute = nav.currentPath;
    final currentThemeMode = ref.watch(themeProvider);

    // Determine the color based on theme and route
    final Color color =
        currentThemeMode == ThemeMode.system
            ? (currentRoute == '/ai' ? Colors.white : Colors.grey.shade100)
            : currentThemeMode == ThemeMode.light
            ? (currentRoute == '/ai'
                ? Colors.white
                : Colors.white.withAlpha(128)) // Light theme
            : (currentRoute == '/ai'
                ? Colors.black
                : Colors.black.withAlpha(128)); // Dark theme

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        final LogicalKeyboardKey? shiftKey = ref.watch(togglesidemenu1);
        final LogicalKeyboardKey? altKey = ref.watch(togglesidemenu2);

        // Check if both keys (Shift + Alt) are pressed simultaneously
        if (event is KeyDownEvent) {
          final Set<LogicalKeyboardKey> pressedKeys =
              HardwareKeyboard.instance.logicalKeysPressed;

          if (pressedKeys.contains(shiftKey) && pressedKeys.contains(altKey)) {
            SideMenuManager.toggleMenu(ref: ref, menuKey: widget.sideMenuKey);
          }
        }
      },
      child: InkWell(
        onTap: () {
          SideMenuManager.toggleMenu(ref: ref, menuKey: widget.sideMenuKey);
        },
        child: SizedBox(
          width: 60,
          height: double.infinity,
          child: ClipRRect(
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 50,
                    sigmaY: 50,
                    tileMode: TileMode.repeated,
                  ),
                  child: Container(
                    color: theme.adPopBackground.withAlpha(38),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                SizedBox(
                  width: 60.0,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          BuildIconButton(
                            icon: Transform.rotate(
                              angle: -90 * 3.141592653589793238 / 180,
                              child: AppIcons.moreVertical(
                                height: 25,
                                width: 25,
                                color: color,
                              ),
                            ),
                            label: '',
                            onPressed: () {
                              SideMenuManager.toggleMenu(
                                ref: ref,
                                menuKey: widget.sideMenuKey,
                              );
                            },
                            currentRoute: currentRoute,
                          ),

                          BuildIconButton(
                            icon: AppIcons.notification(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: '',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                            currentRoute: currentRoute,
                          ),

                          if (isUserLoggedIn) const SizedBox(height: 105),

                          if (!isUserLoggedIn) const SizedBox(height: 15),

                          // Dark mode button
                        ],
                      ),
                      Column(
                        children: [
                          BuildIconButton(
                            icon: AppIcons.home(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'Dashboard'.tr,
                            onPressed: () {},
                            currentRoute: currentRoute,
                          ),
                          BuildIconButton(
                            icon: AppIcons.viewList(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'nav_leads'.tr,
                            onPressed: () {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.proClients);
                            },
                            currentRoute: currentRoute,
                          ),

                          BuildIconButton(
                            icon: AppIcons.gridView(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'nav_board'.tr,
                            onPressed: () {
                              // `Routes.leadsBoard` had no screen behind it;
                              // the pro board (sibling of proTodo/proCalendar
                              // used below) is `Routes.proBoard`.
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.proBoard);
                            },
                            currentRoute: currentRoute,
                          ),

                          BuildIconButton(
                            icon: AppIcons.arrowTrendUp(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'nav_leads'.tr,
                            onPressed: () {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(
                                    Routes.networkMonitorigManagment,
                                  );
                            },
                            currentRoute: currentRoute,
                          ),

                          BuildIconButton(
                            icon: AppIcons.calendar(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'Calendar'.tr,
                            onPressed: () {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.proCalendar);
                            },
                            currentRoute: currentRoute,
                          ),

                          BuildIconButton(
                            icon: AppIcons.task(
                              height: 25,
                              width: 25,
                              color: color,
                            ),
                            label: 'Todo'.tr,
                            onPressed: () {
                              ref
                                  .read(navigationService)
                                  .pushNamedScreen(Routes.proTodo);
                            },
                            currentRoute: currentRoute,
                          ),
                        ],
                      ),
                      LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          if (isUserLoggedIn) {
                            return Column(
                              children: [
                                BuildIconButton(
                                  icon: Icon(
                                    Icons.mail_outline,
                                    size: 25,
                                    color: color,
                                  ),
                                  label: ''.tr,
                                  onPressed: () {
                                    ref
                                        .read(navigationService)
                                        .pushNamedScreen(Routes.emailView);
                                  },
                                  currentRoute: currentRoute,
                                ),
                                ElevatedButton(
                                  style: elevatedButtonStyleRounded10,
                                  onPressed: () {
                                    ref
                                        .read(
                                          navigationHistoryProvider.notifier,
                                        )
                                        .addPage(Routes.chatWrapper);
                                    ref
                                        .read(navigationService)
                                        .pushNamedScreen(Routes.chatWrapper);
                                  },
                                  child: SizedBox(
                                    width: 60,
                                    height: 45,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: AppIcons.sendAbove(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                            height: 25.0,
                                            width: 25.0,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const ChatPage(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                userAsyncValue.when(
                                  data:
                                      (userData) =>
                                          userData != null
                                              ? ElevatedButton(
                                                onPressed:
                                                    () => ref
                                                        .read(navigationService)
                                                        .pushNamedScreen(
                                                          Routes.profile,
                                                        ),
                                                style:
                                                    elevatedButtonStyleRounded10,
                                                child: SizedBox(
                                                  width: 60,
                                                  height: 60,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width:
                                                              45, // ustaw szerokość
                                                          height:
                                                              45, // ustaw wysokość
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                                ),
                                                            image: DecorationImage(
                                                              image:
                                                                  userData.avatarUrl !=
                                                                          null
                                                                      ? CachedNetworkImageProvider(
                                                                        userData
                                                                            .avatarUrl!,
                                                                      )
                                                                      : AssetImage(
                                                                            'assets/images/default_user_avatar.jpg',
                                                                          )
                                                                          as ImageProvider,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : Container(),
                                  loading:
                                      () => const Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(5),
                                            child: ShimmerPlaceholdercircle(
                                              radius: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                  error:
                                      (error, stack) => Text('Error: $error'),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                BuildIconButton(
                                  icon: AppIcons.person(
                                    height: 25,
                                    width: 25,
                                    color: color,
                                  ),
                                  label: '',
                                  onPressed: () => pushLoginNative(ref),
                                  currentRoute: currentRoute,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BuildIconButton extends ConsumerWidget {
  const BuildIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.currentRoute,
  });

  final Widget icon; // <-- zmiana tutaj
  final String label;
  final VoidCallback onPressed;
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: onPressed,
      style: elevatedButtonStyleRounded10,
      child: SizedBox(
        width: 60,
        height: label.isNotEmpty ? 60 : 45,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon, // <-- teraz to widget
              if (label.isNotEmpty) ...[const SizedBox(height: 5.0)],
            ],
          ),
        ),
      ),
    );
  }
}
