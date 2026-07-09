// notification/widgets/notification_tabs.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import '../model/notification_model.dart';
import 'notification_card.dart';


class NotificationTabs extends ConsumerStatefulWidget {
  final List<NotificationModel> notifications;
  final List<NotificationCategory> categories;
  final Function(String) onTabChanged;
  final Function(NotificationModel) onNotificationTap;
  final String selectedTab;
  final bool isLoading;

  const NotificationTabs({
    super.key,
    required this.notifications,
    required this.categories,
    required this.onTabChanged,
    required this.onNotificationTap,
    required this.selectedTab,
    this.isLoading = false,
  });

  @override
  ConsumerState<NotificationTabs> createState() => _NotificationTabsState();
}

class _NotificationTabsState extends ConsumerState<NotificationTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _getTabIndex(widget.selectedTab);
    _tabController = TabController(
      length: _getTabs().length,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabValue = _getTabs()[_tabController.index]['value'] as String;
        if (widget.selectedTab != tabValue) {
          widget.onTabChanged(tabValue);
        }
      }
    });
  }

  @override
  void didUpdateWidget(NotificationTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      final newIndex = _getTabIndex(widget.selectedTab);
      if (_currentIndex != newIndex) {
        _currentIndex = newIndex;
        _tabController.animateTo(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabIndex(String tabValue) {
    final tabs = _getTabs();
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i]['value'] == tabValue) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final tabs = _getTabs();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: theme.textColor,
            unselectedLabelColor: theme.textColor.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: theme.themeColor,
                width: 2,
              ),
            ),
            indicatorPadding: const EdgeInsets.only(bottom: 8),
            dividerColor: Colors.transparent,
            tabs: tabs.map((tab) {
              final count = tab['count'] as int?;
              return Tab(
                child: Row(
                  children: [
                    Text(tab['label'] as String),
                    if (count != null && count > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.themeColorText,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onTap: (index) {
              final tabValue = tabs[index]['value'] as String;
              if (widget.selectedTab != tabValue) {
                widget.onTabChanged(tabValue);
              }
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: widget.isLoading
              ? Center(child: AppLottie.loading(size: isMobile ? 260 : 460,),)
              : widget.notifications.isEmpty
                  ? Center(
                      child: AppLottie.noResults(size: isMobile ? 260 : 460,),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = widget.notifications[index];
                        return NotificationCard(
                          notification: notification,
                          onTap: () => widget.onNotificationTap(notification),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  List<Map<String, dynamic>> _getTabs() {
    final tabs = <Map<String, dynamic>>[
      {'value': 'all', 'label': 'All'},
      {'value': 'mentions', 'label': 'Mentions'},
      {'value': 'tasks', 'label': 'Tasks'},
      {'value': 'alerts', 'label': 'Alerts'},
    ];
    
    if (widget.categories.isNotEmpty) {
      for (var category in widget.categories) {
        if (category.value == 'mention') {
          tabs[1]['count'] = category.unreadCount;
        } else if (category.value == 'task') {
          tabs[2]['count'] = category.unreadCount;
        } else if (category.value == 'alert') {
          tabs[3]['count'] = category.unreadCount;
        }
      }
    }
    
    return tabs;
  }
}