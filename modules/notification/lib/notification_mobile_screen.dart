// notification/notification_mobile_screen.dart
import 'dart:ui' as ui;

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



class NotificationMobileScreen extends ConsumerStatefulWidget {
  const NotificationMobileScreen({super.key});

  @override
  ConsumerState<NotificationMobileScreen> createState() => _NotificationMobileScreenState();
}

class _NotificationMobileScreenState extends ConsumerState<NotificationMobileScreen> {
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

    return EmmaUiAnchorTarget(
      anchorKey: NotificationEmmaAnchors.mobileRoot.anchorKey,

      spec: NotificationEmmaAnchors.mobileRoot,
      runtimeMode: NotificationEmmaAnchors.mobileRoot.runtimeMode,
      tapMode: NotificationEmmaAnchors.mobileRoot.tapMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Header
            _buildHeader(notificationState, theme),
            
            // Tabs and Notifications List
            Expanded(
              child: EmmaUiAnchorTarget(
                anchorKey: NotificationEmmaAnchors.mobileList.anchorKey,

                spec: NotificationEmmaAnchors.mobileList,
                runtimeMode: NotificationEmmaAnchors.mobileList.runtimeMode,
                tapMode: NotificationEmmaAnchors.mobileList.tapMode,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationProvider notificationState, ThemeColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (notificationState.unreadCount > 0)
                      Text(
                        '${notificationState.unreadCount} unread',
                        style: TextStyle(
                          fontSize: 14,
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
                      await ref.read(notificationProvider.notifier).refreshAllData(ref: ref);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.themeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
            ],
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