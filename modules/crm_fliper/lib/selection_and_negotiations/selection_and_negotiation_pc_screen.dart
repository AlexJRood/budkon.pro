import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/refurbishment/refurbishment_pc_screen.dart';
import 'package:crm_fliper/sale/sale_pc_screen.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/flipper_custom_tap_bar.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/negotiation_widget.dart';
import 'package:crm_fliper/selection_and_negotiations/widgets/nigotiation_header_widget.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

class SelectionAndNegotiationPcScreen extends ConsumerWidget {
  const SelectionAndNegotiationPcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    double screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 1920;
    const double minWidth = 480;
    const double maxLogoSize = 30;
    const double minLogoSize = 22;
    double logoSize = (screenWidth - minWidth) /
            (maxWidth - minWidth) *
            (maxLogoSize - minLogoSize) +
        minLogoSize;
    logoSize = logoSize.clamp(minLogoSize, maxLogoSize);
    final tabIndex = ref.watch(tabIndexProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isTopAppBarOff: true,
      childPc: Container(
        color: Colors.black,
        child: Column(
          spacing: 30.h,
          children: [
            const SizedBox(),
            const NegotiationHeaderWidget(),
            const FlipperCustomTapBar(),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: const [
                  Center(child: NegotiationWidget()),
                  Center(child: RefurbishmentPcScreen()),
                  Center(child: SalePcScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
