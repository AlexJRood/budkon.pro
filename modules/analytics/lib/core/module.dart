import 'package:flutter/material.dart';
import 'package:core/modules/app_module.dart';
import 'package:core/navigation/dock_item.dart';
import '../screens/analytics_screen.dart';

class AnalyticsModule extends AppModule {
  @override
  String get id => 'analytics';

  @override
  List<DockItem> dockItems() => [
        DockItem(
          moduleId: id,
          label: 'Analytics',
          icon: Icons.analytics_outlined,
          route: '/analytics',
        ),
      ];

  @override
  Map<RegExp, Widget Function(Map<String, String>)> routeMap() => {
        RegExp(r'^/analytics$'): (_) => const AnalyticsScreen(),
      };

  @override
  Future<void> init() async {}
}
