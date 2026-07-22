import 'package:flutter/material.dart';
import 'package:core/modules/app_module.dart';
import 'package:core/navigation/dock_item.dart';
import '../screens/integracje_screen.dart';

class IntegracjeModule extends AppModule {
  @override
  String get id => 'integracje';

  @override
  List<DockItem> dockItems() => [
        DockItem(
          moduleId: id,
          label: 'Integracje',
          icon: Icons.hub_outlined,
          route: '/integracje',
        ),
      ];

  @override
  Map<RegExp, Widget Function(Map<String, String>)> routeMap() => {
        RegExp(r'^/integracje$'): (_) => const IntegracjeScreen(),
      };

  @override
  Future<void> init() async {}
}
