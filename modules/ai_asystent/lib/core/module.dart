import 'package:flutter/material.dart';
import 'package:core/modules/app_module.dart';
import 'package:core/navigation/dock_item.dart';
import '../screens/ai_asystent_screen.dart';

class AiAsystentModule extends AppModule {
  @override
  String get id => 'ai_asystent';

  @override
  List<DockItem> dockItems() => [
        DockItem(
          moduleId: id,
          label: 'AI Asystent',
          icon: Icons.smart_toy_outlined,
          route: '/ai-asystent',
        ),
      ];

  @override
  Map<RegExp, Widget Function(Map<String, String>)> routeMap() => {
        RegExp(r'^/budowy/(?<budowaId>\d+)/ai-asystent$'): (p) =>
            AiAsystentScreen(budowaId: int.parse(p['budowaId']!)),
      };

  @override
  Future<void> init() async {}
}
