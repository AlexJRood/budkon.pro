// notification/notification_pc_screen.dart
import 'dart:ui' as ui;

import 'package:core/shell/manager/bar_manager.dart'
    show SidebarManagerRail, AppModule;
import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/pie/app_pie_canvas.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification/emma/anchors/notification_emma_anchors.dart';
import 'package:notification/model/notification_model.dart';
import 'package:notification/notification_beamer_navigation.dart';
import 'package:notification/notification_service.dart';
import 'package:notification/widgets/notification_tabs.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/lottie.dart';

class NotificationPcScreen extends ConsumerStatefulWidget {
  const NotificationPcScreen({super.key});

  @override
  ConsumerState<NotificationPcScreen> createState() => _NotificationPcScreenState();
}

class _NotificationPcScreenState extends ConsumerState<NotificationPcScreen> {
  String _selectedTab = 'all';

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = _filterNotifications(
      notificationState.notifications,
      _selectedTab,
      notificationState.categories,
    );
    final theme = ref.watch(themeColorsProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return EmmaUiAnchorTarget(
      anchorKey: NotificationEmmaAnchors.pcRoot.anchorKey,

      spec: NotificationEmmaAnchors.pcRoot,
      runtimeMode: NotificationEmmaAnchors.pcRoot.runtimeMode,
      tapMode: NotificationEmmaAnchors.pcRoot.tapMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // PieCanvas ancestor for the SidebarManagerRail's PieMenu buttons.
        // Without it pie_menu throws "Could not find any PieCanvas".
        body: AppPieCanvas(
          child: Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: theme.adPopBackground.withAlpha((255 * 0.25).toInt()),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Row(
              children: [
                EmmaUiAnchorTarget(
                  anchorKey: NotificationEmmaAnchors.pcSidebar.anchorKey,

                  spec: NotificationEmmaAnchors.pcSidebar,
                  runtimeMode: NotificationEmmaAnchors.pcSidebar.runtimeMode,
                  tapMode: NotificationEmmaAnchors.pcSidebar.tapMode,
                  child: SidebarManagerRail(
                    appModule: AppModule.chat,
                    sideMenuKey: sideMenuKey,
                    legacyChild: const SizedBox.shrink(),
                    onSidebarTap: () => Navigator.maybeOf(context)?.pop(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: EmmaUiAnchorTarget(
                    anchorKey: NotificationEmmaAnchors.pcPanel.anchorKey,

                    spec: NotificationEmmaAnchors.pcPanel,
                    runtimeMode: NotificationEmmaAnchors.pcPanel.runtimeMode,
                    tapMode: NotificationEmmaAnchors.pcPanel.tapMode,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 35,
                          sigmaY: 35,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.dashboardContainer.withOpacity(0.95),
                          ),
                          child: Column(
                            children: [
                              _buildHeader(notificationState, theme),
                              Expanded(
                                child: NotificationTabs(
                                  notifications: notifications,
                                  categories: notificationState.categories,
                                  selectedTab: _selectedTab,
                                  isLoading: notificationState.isLoading,
                                  onTabChanged: (tab) {
                                    setState(() {
                                      _selectedTab = tab;
                                    });
                                  },
                                  onNotificationTap: (notification) async {
                                    await ref.read(notificationProvider.notifier)
                                        .makeNotificationSeen(notification.id);
                                    
                                    NotificationBeamerNavigation.navigate(
                                      context,
                                      ref,
                                      notification,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Empty area to the right of the panel — tapping it closes the
                // notifications overlay (matches the parent dismiss area, which
                // this full-screen child would otherwise cover).
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(navigationService).beamPop(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationProvider notificationState, ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.textColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                if (notificationState.unreadCount > 0)
                  Text(
                    '${notificationState.unreadCount} unread notifications',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (notificationState.unreadCount > 0)
            GestureDetector(
              onTap: () async {
                final success = await ref.read(notificationProvider.notifier)
                    .makeAllNotificationsSeen();
                if (success) {
                  ref.read(notificationProvider.notifier).refreshAllData(ref: ref);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.themeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                        color: theme.themeColor.withOpacity(0.3),
                      ),
                ),
                child: Text(
                  'Mark all as read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.dashboardContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
    String tab,
    List<NotificationCategory> categories,
  ) {
    if (tab == 'all') return notifications;
    
    return notifications.where((notification) {
      if (tab == 'mentions') {
        return notification.text.toLowerCase().contains('@') ||
               notification.title.toLowerCase().contains('mention');
      } else if (tab == 'tasks') {
        return notification.contentType == 77 ||
               notification.title.toLowerCase().contains('task');
      } else if (tab == 'alerts') {
        return notification.title.toLowerCase().contains('alert') ||
               notification.contentType == 50;
      }
      return true;
    }).toList();
  }
}