import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/common/chrome/appbar_back.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/add_offer/add_offer_new_mobile.dart';
import 'package:portal/screens/add_offer/components/progress_indicator.dart';
import 'package:portal/screens/add_offer/add_offer_new_pc.dart';

import 'add_offer_new_tablet.dart';

class AddOfferPage extends ConsumerWidget {
  const AddOfferPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final currentStep = ref.watch(progressProvider);

    final sideMenuKey = GlobalKey<SideMenuState>();
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      specialAppBar: TopAppBarWithBack(),
      isChildExpanded: false,
      childPc: AddOfferNewPc(),
      childTablet: AddOfferNewTablet(),
      childMobile: AddOfferNewMobile(),
    );
  }
}