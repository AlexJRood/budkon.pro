import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:crm/draft/components/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class DraftList extends ConsumerWidget {
  const DraftList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      isTopAppBarHoveroverUI: false,
      
      childPc: DraftAdvertisementsList(),
      childMobile: DraftAdvertisementsList()
    );
  }
}

