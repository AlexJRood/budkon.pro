import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pc/go_pro_pc.dart';
import 'tablet/go_pro_tablet.dart';
import 'mobile/go_pro_mobile.dart';

class GoProPage extends ConsumerWidget {
  const GoProPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      enableScrool: true,

      childPc: const GoProPc(),
      childTablet: const GoProTablet(),
      childMobile: const GoProMobile(),
    );
  }
}
